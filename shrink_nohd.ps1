$ErrorActionPreference = 'Stop'

$root = 'C:\Users\admin\Documents\GD-shrink\gd2208_nohd\assets'

Add-Type -AssemblyName System.Drawing

function Scale-QuarterInt([string]$value) {
    $n = [double]::Parse($value, [Globalization.CultureInfo]::InvariantCulture)
    return ([int][math]::Round($n / 4.0, [System.MidpointRounding]::AwayFromZero)).ToString()
}

function Scale-QuarterTuple([string]$value) {
    return [regex]::Replace($value, '-?\d+(?:\.\d+)?', {
        param($m)
        Scale-QuarterInt $m.Value
    })
}

function Replace-KeyedTuple([string]$content, [string[]]$keys) {
    foreach ($key in $keys) {
        $pattern = "(<key>$([regex]::Escape($key))</key>\s*<string>)([^<]+)(</string>)"
        $content = [regex]::Replace($content, $pattern, {
            param($m)
            $scaled = Scale-QuarterTuple $m.Groups[2].Value
            $m.Groups[1].Value + $scaled + $m.Groups[3].Value
        })
    }

    return $content
}

function Resize-Png([string]$path) {
    $tempPath = "$path.tmp"
    $source = [System.Drawing.Bitmap]::new($path)
    try {
        $newWidth = [math]::Max(1, [int][math]::Round($source.Width / 4.0, [System.MidpointRounding]::AwayFromZero))
        $newHeight = [math]::Max(1, [int][math]::Round($source.Height / 4.0, [System.MidpointRounding]::AwayFromZero))
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

Get-ChildItem -Path $root -Recurse -File -Filter '*.png' |
    ForEach-Object { Resize-Png $_.FullName }

Get-ChildItem -Path $root -Recurse -File -Filter '*.plist' |
    ForEach-Object {
        $path = $_.FullName
        $content = [IO.File]::ReadAllText($path)
        $content = Replace-KeyedTuple $content @('textureRect', 'spriteSize', 'spriteOffset', 'spriteSourceSize', 'position')
        [IO.File]::WriteAllText($path, $content, [System.Text.UTF8Encoding]::new($false))
    }

Get-ChildItem -Path $root -Recurse -File -Filter '*.fnt' |
    ForEach-Object {
        $path = $_.FullName
        $content = [IO.File]::ReadAllText($path)
        $fields = @('size','lineHeight','base','scaleW','scaleH','width','height','xoffset','yoffset','xadvance')
        foreach ($field in $fields) {
            $pattern = "(?<=\b$([regex]::Escape($field))=)-?\d+"
            $content = [regex]::Replace($content, $pattern, {
                param($m)
                Scale-QuarterInt $m.Value
            })
        }
        [IO.File]::WriteAllText($path, $content, [System.Text.UTF8Encoding]::new($false))
    }

