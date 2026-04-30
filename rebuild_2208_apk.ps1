$ErrorActionPreference = 'Stop'

$sourceDir = 'C:\Users\admin\Documents\GD-shrink\gd2208_unpacked'
$stageDir = 'C:\Users\admin\Documents\GD-shrink\gd2208_stage'
$storedApk = 'C:\Users\admin\Documents\GD-shrink\Geometry_Dash_v2.208-shrunk4-stored-unsigned.apk'
$alignedApk = 'C:\Users\admin\Documents\GD-shrink\Geometry_Dash_v2.208-shrunk4-aligned.apk'
$signedApk = 'C:\Users\admin\Documents\GD-shrink\Geometry_Dash_v2.208-shrunk4-signed.apk'
$zipalign = 'C:\Users\admin\Documents\GD-shrink\tools\android-sdk\build-tools\35.0.0\zipalign.exe'
$apksigner = 'C:\Users\admin\Documents\GD-shrink\tools\android-sdk\build-tools\35.0.0\apksigner.bat'
$keystore = 'C:\Users\admin\Documents\GD-shrink\tools\gd-local.keystore'
$javaHome = 'C:\Users\admin\Documents\GD-shrink\tools\jdk-17.0.18+8'
$jarExe = 'C:\Users\admin\Documents\GD-shrink\tools\jdk-17.0.18+8\bin\jar.exe'

foreach ($path in @($storedApk, $alignedApk, $signedApk)) {
    if (Test-Path $path) {
        Remove-Item -Force $path
    }
}

if (Test-Path $stageDir) {
    Remove-Item -Recurse -Force $stageDir
}

New-Item -ItemType Directory -Path $stageDir | Out-Null
Copy-Item -Recurse -Force (Join-Path $sourceDir '*') $stageDir

& $jarExe --create --file $storedApk --no-manifest --no-compress -C $stageDir .
if ($LASTEXITCODE -ne 0) {
    throw 'jar create failed'
}

& $zipalign -f 4 $storedApk $alignedApk
if ($LASTEXITCODE -ne 0) {
    throw 'zipalign failed'
}

$env:JAVA_HOME = $javaHome
& $apksigner sign --ks $keystore --ks-key-alias gdlocal --ks-pass pass:android --key-pass pass:android --out $signedApk $alignedApk
if ($LASTEXITCODE -ne 0) {
    throw 'apksigner sign failed'
}
