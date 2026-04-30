param(
    [Parameter(Mandatory = $true)]
    [string]$plistPath
)

$ErrorActionPreference = 'Stop'

Add-Type -AssemblyName System.Drawing

function Scale-QuarterInt([int]$value) {
    return [math]::Max(1, [int][math]::Round($value / 4.0, [System.MidpointRounding]::AwayFromZero))
}

function Parse-TupleRect([string]$value) {
    $m = [regex]::Match($value, '^\{\{(-?\d+),(-?\d+)\},\{(-?\d+),(-?\d+)\}\}$')
    if (-not $m.Success) { throw "Unsupported textureRect format: $value" }
    return [PSCustomObject]@{ X=[int]$m.Groups[1].Value; Y=[int]$m.Groups[2].Value; Width=[int]$m.Groups[3].Value; Height=[int]$m.Groups[4].Value }
}

$content = [IO.File]::ReadAllText($plistPath)
if ($content -notmatch '<key>frames</key>' -or $content -notmatch '<key>metadata</key>') {
    throw 'Not an atlas plist'
}

$textureMatch = [regex]::Match($content, '<key>textureFileName</key>\s*<string>([^<]+)</string>')
if (-not $textureMatch.Success) { throw 'textureFileName not found' }

$textureFileName = [IO.Path]::GetFileName($textureMatch.Groups[1].Value)
$textureDir = Split-Path $plistPath -Parent
$texturePath = Join-Path $textureDir $textureFileName
if (-not (Test-Path $texturePath)) { throw "Texture not found: $texturePath" }

$newTextureFileName = [IO.Path]::GetFileNameWithoutExtension($textureFileName) + '.repack.png'
$newTexturePath = Join-Path $textureDir $newTextureFileName

$framePattern = '<key>([^<]+)</key>\s*<dict>.*?<key>textureRect</key>\s*<string>(\{\{[^<]+\}\})</string>.*?<key>textureRotated</key>\s*<(true|false)/>.*?</dict>'
$matches = [regex]::Matches($content, $framePattern, [System.Text.RegularExpressions.RegexOptions]::Singleline)

$source = [System.Drawing.Bitmap]::new($texturePath)
try {
    $atlasWidth = [math]::Max(64, (Scale-QuarterInt $source.Width))
    $padding = 1
    $x = $padding
    $y = $padding
    $rowHeight = 0
    $positions = @()

    foreach ($match in $matches) {
        $rect = Parse-TupleRect $match.Groups[2].Value
        $newW = Scale-QuarterInt $rect.Width
        $newH = Scale-QuarterInt $rect.Height
        if ($x + $newW + $padding -gt $atlasWidth) {
            $x = $padding
            $y += $rowHeight + $padding
            $rowHeight = 0
        }

        $positions += [PSCustomObject]@{
            OriginalRect = $match.Groups[2].Value
            SourceRect = $rect
            X = $x
            Y = $y
            Width = $newW
            Height = $newH
        }

        $x += $newW + $padding
        $rowHeight = [math]::Max($rowHeight, $newH)
    }

    $atlasHeight = [math]::Max(1, $y + $rowHeight + $padding)
    $atlas = [System.Drawing.Bitmap]::new($atlasWidth, $atlasHeight)
    try {
        $graphics = [System.Drawing.Graphics]::FromImage($atlas)
        try {
            $graphics.Clear([System.Drawing.Color]::Transparent)

            foreach ($entry in $positions) {
                $cropRect = [System.Drawing.Rectangle]::new($entry.SourceRect.X, $entry.SourceRect.Y, $entry.SourceRect.Width, $entry.SourceRect.Height)
                $patch = $source.Clone($cropRect, $source.PixelFormat)
                try {
                    $graphics.DrawImage($patch, $entry.X, $entry.Y, $entry.Width, $entry.Height)
                }
                finally {
                    $patch.Dispose()
                }

                $newRect = '{{' + $entry.X + ',' + $entry.Y + '},{' + $entry.Width + ',' + $entry.Height + '}}'
                $content = [regex]::Replace($content, [regex]::Escape($entry.OriginalRect), [System.Text.RegularExpressions.MatchEvaluator]{ param($m) $newRect }, 1)
            }
        }
        finally {
            $graphics.Dispose()
        }

        $tempPath = "$newTexturePath.tmp"
        if (Test-Path $tempPath) { Remove-Item -Force $tempPath }
        $atlas.Save($tempPath, [System.Drawing.Imaging.ImageFormat]::Png)
    }
    finally {
        $atlas.Dispose()
    }
}
finally {
    $source.Dispose()
}

[GC]::Collect()
[GC]::WaitForPendingFinalizers()

if (Test-Path $newTexturePath) { Remove-Item -Force $newTexturePath }
Move-Item -Force "$newTexturePath.tmp" $newTexturePath

$content = [regex]::Replace($content, '(<key>size</key>\s*<string>)\{[^<]+\}(</string>)', ('$1' + "{$atlasWidth,$atlasHeight}" + '$2'), 1)
$content = [regex]::Replace($content, '(<key>textureFileName</key>\s*<string>)[^<]+(</string>)', ('$1' + $newTextureFileName + '$2'), 1)
$content = [regex]::Replace($content, '(<key>realTextureFileName</key>\s*<string>)[^<]+(</string>)', ('$1' + $newTextureFileName + '$2'), 1)
[IO.File]::WriteAllText($plistPath, $content, [System.Text.UTF8Encoding]::new($false))
