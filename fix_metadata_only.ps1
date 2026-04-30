$ErrorActionPreference = 'Stop'

$root = 'C:\Users\admin\Documents\GD-shrink\apk_compact'

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

Get-ChildItem -Path (Join-Path $root 'assets') -Recurse -File -Filter '*.plist' |
    ForEach-Object {
        $path = $_.FullName
        $content = [IO.File]::ReadAllText($path)

        if ($content.Contains('<key>spriteOffset</key>')) {
            $content = Replace-KeyedString $content @('spriteOffset', 'spriteSize', 'spriteSourceSize')
        }

        if ($path -like '*AnimDesc.plist') {
            $content = Replace-KeyedString $content @('position')
        }

        [IO.File]::WriteAllText($path, $content, [System.Text.UTF8Encoding]::new($false))
    }
