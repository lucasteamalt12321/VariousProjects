$ErrorActionPreference = 'Stop'

$root = 'C:\Users\admin\Documents\GD-shrink\gd22081_repack\assets'

Add-Type -AssemblyName System.Drawing

function Scale-QuarterInt([int]$value) {
    return [math]::Max(1, [int][math]::Round($value / 4.0, [System.MidpointRounding]::AwayFromZero))
}

function Parse-TupleRect([string]$value) {
    $m = [regex]::Match($value, '^\{\{(-?\d+),(-?\d+)\},\{(-?\d+),(-?\d+)\}\}$')
    if (-not $m.Success) {
        throw "Unsupported textureRect format: $value"
    }

    return [PSCustomObject]@{
        X = [int]$m.Groups[1].Value
        Y = [int]$m.Groups[2].Value
        Width = [int]$m.Groups[3].Value
        Height = [int]$m.Groups[4].Value
    }
}

function Get-DictPairs($dictNode) {
    $nodes = @($dictNode.ChildNodes | Where-Object { $_.NodeType -eq [System.Xml.XmlNodeType]::Element })
    $pairs = @()
    for ($i = 0; $i -lt $nodes.Count; $i += 2) {
        if ($nodes[$i].Name -ne 'key') {
            continue
        }

        $pairs += [PSCustomObject]@{
            Key = $nodes[$i]
            Value = $nodes[$i + 1]
        }
    }

    return $pairs
}

function Get-DictValue($dictNode, [string]$name) {
    foreach ($pair in (Get-DictPairs $dictNode)) {
        if ($pair.Key.InnerText -eq $name) {
            return $pair.Value
        }
    }

    return $null
}

function Resize-StandalonePng([string]$path) {
    $tempPath = "$path.tmp"
    $source = [System.Drawing.Bitmap]::new($path)
    try {
        $newWidth = Scale-QuarterInt $source.Width
        $newHeight = Scale-QuarterInt $source.Height
        $dest = [System.Drawing.Bitmap]::new($newWidth, $newHeight)
        try {
            $dest.SetResolution($source.HorizontalResolution, $source.VerticalResolution)
            $graphics = [System.Drawing.Graphics]::FromImage($dest)
            try {
                $graphics.CompositingQuality = [System.Drawing.Drawing2D.CompositingQuality]::HighQuality
                $graphics.InterpolationMode = [System.Drawing.Drawing2D.InterpolationMode]::HighQualityBicubic
                $graphics.PixelOffsetMode = [System.Drawing.Drawing2D.PixelOffsetMode]::HighQuality
                $graphics.SmoothingMode = [System.Drawing.Drawing2D.SmoothingMode]::HighQuality
                $graphics.DrawImage($source, 0, 0, $newWidth, $newHeight)
            }
            finally {
                $graphics.Dispose()
            }

            $dest.Save($tempPath, [System.Drawing.Imaging.ImageFormat]::Png)
        }
        finally {
            $dest.Dispose()
        }
    }
    finally {
        $source.Dispose()
    }

    [IO.File]::Delete($path)
    [IO.File]::Move($tempPath, $path)
}

function Repack-PlistAtlas([string]$plistPath) {
    $content = [IO.File]::ReadAllText($plistPath)
    if ($content -notmatch '<key>frames</key>' -or $content -notmatch '<key>metadata</key>') {
        return $null
    }

    $textureFileMatch = [regex]::Match($content, '<key>textureFileName</key>\s*<string>([^<]+)</string>')
    if (-not $textureFileMatch.Success) {
        return $null
    }

    $textureFileName = [IO.Path]::GetFileName($textureFileMatch.Groups[1].Value)
    $texturePath = Join-Path (Split-Path $plistPath -Parent) $textureFileName
    if (-not (Test-Path $texturePath)) {
        return $null
    }

    $newTextureFileName = [IO.Path]::GetFileNameWithoutExtension($textureFileName) + '.repack.png'
    $newTexturePath = Join-Path (Split-Path $texturePath -Parent) $newTextureFileName

    $source = [System.Drawing.Bitmap]::new($texturePath)
    try {
        $entries = @()
        $framePattern = '<key>([^<]+)</key>\s*<dict>.*?<key>textureRect</key>\s*<string>(\{\{[^<]+\}\})</string>.*?<key>textureRotated</key>\s*<(true|false)/>.*?</dict>'
        $matches = [regex]::Matches($content, $framePattern, [System.Text.RegularExpressions.RegexOptions]::Singleline)
        foreach ($match in $matches) {
            $frameName = $match.Groups[1].Value
            $rect = Parse-TupleRect $match.Groups[2].Value
            $newWidth = Scale-QuarterInt $rect.Width
            $newHeight = Scale-QuarterInt $rect.Height

            $crop = [System.Drawing.Rectangle]::new($rect.X, $rect.Y, $rect.Width, $rect.Height)
            $patch = $source.Clone($crop, $source.PixelFormat)
            try {
                $resized = [System.Drawing.Bitmap]::new($newWidth, $newHeight)
                try {
                    $graphics = [System.Drawing.Graphics]::FromImage($resized)
                    try {
                        $graphics.CompositingQuality = [System.Drawing.Drawing2D.CompositingQuality]::HighQuality
                        $graphics.InterpolationMode = [System.Drawing.Drawing2D.InterpolationMode]::HighQualityBicubic
                        $graphics.PixelOffsetMode = [System.Drawing.Drawing2D.PixelOffsetMode]::HighQuality
                        $graphics.SmoothingMode = [System.Drawing.Drawing2D.SmoothingMode]::HighQuality
                        $graphics.DrawImage($patch, 0, 0, $newWidth, $newHeight)
                    }
                    finally {
                        $graphics.Dispose()
                    }

                    $entries += [PSCustomObject]@{
                        Name = $frameName
                        OriginalRect = $match.Groups[2].Value
                        Bitmap = $resized.Clone()
                        Width = $newWidth
                        Height = $newHeight
                    }
                }
                finally {
                    $resized.Dispose()
                }
            }
            finally {
                $patch.Dispose()
            }
        }

        $padding = 1
        $initialWidth = [math]::Max(64, (Scale-QuarterInt $source.Width))
        $atlasWidth = $initialWidth
        $x = $padding
        $y = $padding
        $rowHeight = 0

        foreach ($entry in $entries) {
            if ($x + $entry.Width + $padding -gt $atlasWidth) {
                $x = $padding
                $y += $rowHeight + $padding
                $rowHeight = 0
            }

            $entry | Add-Member -NotePropertyName X -NotePropertyValue $x
            $entry | Add-Member -NotePropertyName Y -NotePropertyValue $y
            $x += $entry.Width + $padding
            $rowHeight = [math]::Max($rowHeight, $entry.Height)
        }

        $atlasHeight = [math]::Max(1, $y + $rowHeight + $padding)
        $atlas = [System.Drawing.Bitmap]::new($atlasWidth, $atlasHeight)
        try {
            $graphics = [System.Drawing.Graphics]::FromImage($atlas)
            try {
                $graphics.Clear([System.Drawing.Color]::Transparent)
                foreach ($entry in $entries) {
                    $graphics.DrawImage($entry.Bitmap, $entry.X, $entry.Y, $entry.Width, $entry.Height)
                    $newRect = '{{' + $entry.X + ',' + $entry.Y + '},{' + $entry.Width + ',' + $entry.Height + '}}'
                    $escapedOld = [regex]::Escape($entry.OriginalRect)
                    $content = [regex]::Replace($content, $escapedOld, [System.Text.RegularExpressions.MatchEvaluator]{ param($m) $newRect }, 1)
                }
            }
            finally {
                $graphics.Dispose()
            }

            $tempTexturePath = "$newTexturePath.tmp"
            $atlas.Save($tempTexturePath, [System.Drawing.Imaging.ImageFormat]::Png)
        }
        finally {
            $atlas.Dispose()
            foreach ($entry in $entries) {
                $entry.Bitmap.Dispose()
            }
        }

        [GC]::Collect()
        [GC]::WaitForPendingFinalizers()
        if (Test-Path $newTexturePath) { Remove-Item -Force $newTexturePath }
        Move-Item -Force $tempTexturePath $newTexturePath

        $content = [regex]::Replace($content, '(<key>size</key>\s*<string>)\{[^<]+\}(</string>)', ('$1' + "{$atlasWidth,$atlasHeight}" + '$2'), 1)
        $content = [regex]::Replace($content, '(<key>textureFileName</key>\s*<string>)[^<]+(</string>)', ('$1' + $newTextureFileName + '$2'), 1)
        $content = [regex]::Replace($content, '(<key>realTextureFileName</key>\s*<string>)[^<]+(</string>)', ('$1' + $newTextureFileName + '$2'), 1)
        [IO.File]::WriteAllText($plistPath, $content, [System.Text.UTF8Encoding]::new($false))

        return [PSCustomObject]@{
            Plist = $plistPath
            Texture = $newTexturePath
            Width = $atlasWidth
            Height = $atlasHeight
            Frames = $entries.Count
        }
    }
    finally {
        $source.Dispose()
    }
}

$plistTextures = New-Object System.Collections.Generic.HashSet[string]([System.StringComparer]::OrdinalIgnoreCase)

Get-ChildItem -Path $root -Recurse -File -Filter '*.plist' |
    ForEach-Object {
        $result = Repack-PlistAtlas $_.FullName
        if ($null -ne $result) {
            [void]$plistTextures.Add($result.Texture)
        }
    }

Get-ChildItem -Path $root -Recurse -File -Filter '*.fnt' |
    ForEach-Object {
        $path = $_.FullName
        $content = [IO.File]::ReadAllText($path)
        foreach ($field in @('x','y','scaleW','scaleH')) {
            $pattern = "(?<=\b$([regex]::Escape($field))=)-?\d+"
            $content = [regex]::Replace($content, $pattern, {
                param($m)
                Scale-QuarterInt ([int]$m.Value)
            })
        }
        [IO.File]::WriteAllText($path, $content, [System.Text.UTF8Encoding]::new($false))

        $pngNameMatch = [regex]::Match($content, 'file="([^"]+\.png)"')
        if ($pngNameMatch.Success) {
            $pngPath = Join-Path (Split-Path $path -Parent) ([IO.Path]::GetFileName($pngNameMatch.Groups[1].Value))
            if ((Test-Path $pngPath) -and (-not $plistTextures.Contains($pngPath))) {
                Resize-StandalonePng $pngPath
                [void]$plistTextures.Add($pngPath)
            }
        }
    }

Get-ChildItem -Path $root -Recurse -File -Filter '*.png' |
    ForEach-Object {
        if (-not $plistTextures.Contains($_.FullName)) {
            Resize-StandalonePng $_.FullName
        }
    }
