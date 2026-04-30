$ErrorActionPreference = 'Stop'

$root = 'C:\Users\admin\Documents\GD-shrink\apk_unpacked'

Add-Type -AssemblyName System.Drawing
Add-Type -AssemblyName System.Core

function Scale-Int([string]$value) {
    return ([int][math]::Round([double]$value * 2, [System.MidpointRounding]::AwayFromZero)).ToString()
}

function Scale-Number([string]$value) {
    $n = [double]$value
    $scaled = $n * 2
    if ([math]::Abs($scaled - [math]::Round($scaled)) -lt 1e-9) {
        return ([int][math]::Round($scaled)).ToString()
    }

    $text = $scaled.ToString('0.######', [Globalization.CultureInfo]::InvariantCulture)
    return $text.TrimEnd('0').TrimEnd('.')
}

function Scale-BraceTuple([string]$value) {
    return [regex]::Replace($value, '-?\d+(?:\.\d+)?', {
        param($m)
        Scale-Number $m.Value
    })
}

function Replace-KeyedString($content, [string[]]$keys) {
    foreach ($key in $keys) {
        $pattern = "(<key>$([regex]::Escape($key))</key>\s*<string>)([^<]+)(</string>)"
        $content = [regex]::Replace($content, $pattern, {
            param($m)
            $scaled = Scale-BraceTuple $m.Groups[2].Value
            return $m.Groups[1].Value + $scaled + $m.Groups[3].Value
        })
    }

    return $content
}

function Resize-Png([string]$path) {
    $tempPath = "$path.fixed"
    $source = [System.Drawing.Bitmap]::new($path)
    try {
        $dest = [System.Drawing.Bitmap]::new($source.Width * 2, $source.Height * 2)
        try {
            $dest.SetResolution($source.HorizontalResolution, $source.VerticalResolution)
            $graphics = [System.Drawing.Graphics]::FromImage($dest)
            try {
                $graphics.CompositingMode = [System.Drawing.Drawing2D.CompositingMode]::SourceCopy
                $graphics.CompositingQuality = [System.Drawing.Drawing2D.CompositingQuality]::HighQuality
                $graphics.InterpolationMode = [System.Drawing.Drawing2D.InterpolationMode]::NearestNeighbor
                $graphics.PixelOffsetMode = [System.Drawing.Drawing2D.PixelOffsetMode]::Half
                $graphics.SmoothingMode = [System.Drawing.Drawing2D.SmoothingMode]::None
                $graphics.DrawImage($source, 0, 0, $dest.Width, $dest.Height)
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

Get-ChildItem -Path (Join-Path $root 'assets') -Recurse -File -Filter '*.png' |
    ForEach-Object { Resize-Png $_.FullName }

Get-ChildItem -Path (Join-Path $root 'assets') -Recurse -File -Filter '*.plist' |
    ForEach-Object {
        $path = $_.FullName
        $content = [IO.File]::ReadAllText($path)

        if ($content.Contains('<key>spriteOffset</key>')) {
            $content = Replace-KeyedString $content @('spriteOffset', 'spriteSize', 'spriteSourceSize', 'textureRect', 'size')
        }

        if ($path -like '*AnimDesc.plist') {
            $content = Replace-KeyedString $content @('position')
        }

        [IO.File]::WriteAllText($path, $content, [System.Text.UTF8Encoding]::new($false))
    }

Get-ChildItem -Path (Join-Path $root 'assets') -Recurse -File -Filter '*.fnt' |
    ForEach-Object {
        $path = $_.FullName
        $content = [IO.File]::ReadAllText($path)
        $content = [regex]::Replace($content, '(?<name>size|lineHeight|base|scaleW|scaleH|x|y|width|height|xoffset|yoffset|xadvance|amount)=(-?\d+)', {
            param($m)
            return $m.Groups['name'].Value + '=' + (Scale-Int $m.Groups[1].Value)
        })
        [IO.File]::WriteAllText($path, $content, [System.Text.UTF8Encoding]::new($false))
    }
