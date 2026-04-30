$ErrorActionPreference = 'Stop'

$sourceDir = 'C:\Users\admin\Documents\GD-shrink\apk_unpacked'
$unsignedApk = 'C:\Users\admin\Documents\GD-shrink\gd-2.2.144-lite-nohd-arm64-fixed-unsigned.apk'
$alignedApk = 'C:\Users\admin\Documents\GD-shrink\gd-2.2.144-lite-nohd-arm64-fixed-aligned.apk'
$signedApk = 'C:\Users\admin\Documents\GD-shrink\gd-2.2.144-lite-nohd-arm64-fixed-signed.apk'
$phoneApk = 'C:\Users\admin\Documents\GD-shrink\gd-2.2.144-lite-nohd-arm64-for-phone.apk'
$keystore = 'C:\Users\admin\Documents\GD-shrink\tools\gd-local.keystore'
$zipalign = 'C:\Users\admin\Documents\GD-shrink\tools\android-sdk\build-tools\35.0.0\zipalign.exe'
$apksigner = 'C:\Users\admin\Documents\GD-shrink\tools\android-sdk\build-tools\35.0.0\apksigner.bat'
$javaHome = 'C:\Users\admin\Documents\GD-shrink\tools\jdk-17.0.18+8'

Add-Type -AssemblyName System.IO.Compression
Add-Type -AssemblyName System.IO.Compression.FileSystem

foreach ($path in @($unsignedApk, $alignedApk, $signedApk, $phoneApk)) {
    if (Test-Path $path) {
        Remove-Item -Force $path
    }
}

$fileStream = [IO.File]::Open($unsignedApk, [IO.FileMode]::CreateNew)
try {
    $zip = [IO.Compression.ZipArchive]::new($fileStream, [IO.Compression.ZipArchiveMode]::Create, $false)
    try {
        $files = Get-ChildItem -Path $sourceDir -Recurse -File | Sort-Object FullName
        foreach ($file in $files) {
            $relative = $file.FullName.Substring($sourceDir.Length + 1).Replace('\', '/')
            $compression = [IO.Compression.CompressionLevel]::Optimal
            if ($relative -eq 'resources.arsc' -or $relative.StartsWith('lib/')) {
                $compression = [IO.Compression.CompressionLevel]::NoCompression
            }

            $entry = $zip.CreateEntry($relative, $compression)
            $entryStream = $entry.Open()
            try {
                $input = [IO.File]::OpenRead($file.FullName)
                try {
                    $input.CopyTo($entryStream)
                }
                finally {
                    $input.Dispose()
                }
            }
            finally {
                $entryStream.Dispose()
            }
        }
    }
    finally {
        $zip.Dispose()
    }
}
finally {
    $fileStream.Dispose()
}

& $zipalign -f 4 $unsignedApk $alignedApk
if ($LASTEXITCODE -ne 0) {
    throw 'zipalign failed'
}

$env:JAVA_HOME = $javaHome
& $apksigner sign --ks $keystore --ks-key-alias gdlocal --ks-pass pass:android --key-pass pass:android --out $signedApk $alignedApk
if ($LASTEXITCODE -ne 0) {
    throw 'apksigner sign failed'
}

& $apksigner verify --verbose $signedApk
if ($LASTEXITCODE -ne 0) {
    throw 'apksigner verify failed'
}

Copy-Item -Force $signedApk $phoneApk
