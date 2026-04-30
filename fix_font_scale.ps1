$ErrorActionPreference = 'Stop'

$root = 'C:\Users\admin\Documents\GD-shrink\apk_unpacked\assets'

function Scale-Int([string]$value) {
    return ([int][math]::Round([double]$value * 2, [System.MidpointRounding]::AwayFromZero)).ToString()
}

Get-ChildItem -Path $root -Recurse -File -Filter '*.fnt' |
    ForEach-Object {
        $path = $_.FullName
        $content = [IO.File]::ReadAllText($path)
        $content = [regex]::Replace($content, '(?<name>size|lineHeight|base|scaleW|scaleH|x|y|width|height|xoffset|yoffset|xadvance|amount)=(?<value>-?\d+)', {
            param($m)
            return $m.Groups['name'].Value + '=' + (Scale-Int $m.Groups['value'].Value)
        })
        [IO.File]::WriteAllText($path, $content, [System.Text.UTF8Encoding]::new($false))
    }
