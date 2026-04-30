$ErrorActionPreference = 'Stop'

$inputApk = 'C:\Users\admin\Documents\GD-shrink\GeometryDashLDM-unsigned.apk'
$normalizedApk = 'C:\Users\admin\Documents\GD-shrink\GeometryDashLDM-normalized-unsigned.apk'
$alignedApk = 'C:\Users\admin\Documents\GD-shrink\GeometryDashLDM-aligned.apk'
$signedApk = 'C:\Users\admin\Documents\GD-shrink\GeometryDashLDM.apk'
$zipalign = 'C:\Users\admin\Documents\GD-shrink\tools\android-sdk\build-tools\35.0.0\zipalign.exe'
$apksigner = 'C:\Users\admin\Documents\GD-shrink\tools\android-sdk\build-tools\35.0.0\apksigner.bat'
$keystore = 'C:\Users\admin\Documents\GD-shrink\tools\gd-local.keystore'
$javaHome = 'C:\Users\admin\Documents\GD-shrink\tools\jdk-17.0.18+8'

Add-Type -AssemblyName System.IO.Compression
Add-Type -AssemblyName System.IO.Compression.FileSystem

foreach ($path in @($normalizedApk, $alignedApk, $signedApk)) {
    if (Test-Path $path) {
        Remove-Item -Force $path
    }
}

$source = [IO.Compression.ZipFile]::OpenRead($inputApk)
try {
    $outStream = [IO.File]::Open($normalizedApk, [IO.FileMode]::CreateNew)
    try {
        $dest = [IO.Compression.ZipArchive]::new($outStream, [IO.Compression.ZipArchiveMode]::Create, $false)
        try {
            foreach ($entry in $source.Entries) {
                if ([string]::IsNullOrEmpty($entry.Name)) {
                    continue
                }

                $compression = [IO.Compression.CompressionLevel]::Optimal
                if ($entry.FullName -eq 'resources.arsc' -or $entry.FullName.StartsWith('lib/')) {
                    $compression = [IO.Compression.CompressionLevel]::NoCompression
                }

                $newEntry = $dest.CreateEntry($entry.FullName, $compression)
                $inStream = $entry.Open()
                $outEntryStream = $newEntry.Open()
                try {
                    $inStream.CopyTo($outEntryStream)
                }
                finally {
                    $outEntryStream.Dispose()
                    $inStream.Dispose()
                }
            }
        }
        finally {
            $dest.Dispose()
        }
    }
    finally {
        $outStream.Dispose()
    }
}
finally {
    $source.Dispose()
}

& $zipalign -f 4 $normalizedApk $alignedApk
if ($LASTEXITCODE -ne 0) {
    throw 'zipalign failed'
}

$env:JAVA_HOME = $javaHome
& $apksigner sign --ks $keystore --ks-key-alias gdlocal --ks-pass pass:android --key-pass pass:android --out $signedApk $alignedApk
if ($LASTEXITCODE -ne 0) {
    throw 'apksigner sign failed'
}
