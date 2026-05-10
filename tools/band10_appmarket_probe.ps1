$ErrorActionPreference = "Stop"

$repoRoot = Split-Path -Parent $PSScriptRoot
$adb = Join-Path $repoRoot "tools\platform-tools\adb.exe"

if (-not (Test-Path $adb)) {
    throw "ADB not found: $adb"
}

Write-Host "Checking connected Android devices..."
& $adb devices

Write-Host ""
Write-Host "Open Huawei Health, go to the paired Huawei Band 10 device page, then wait here for 90 seconds."
Write-Host "The probe watches for App Market / DeviceCapability logs that decide whether executable wear apps are available."
Write-Host ""

$matchLogPath = Join-Path $repoRoot "band10_appmarket_probe.log"
$fullLogPath = Join-Path $repoRoot "band10_huawei_health_full.log"
foreach ($path in @($matchLogPath, $fullLogPath)) {
    if (Test-Path $path) {
        Remove-Item $path -Force
    }
}

& $adb logcat -c

$healthPid = (& $adb shell pidof com.huawei.health).Trim()
if ([string]::IsNullOrWhiteSpace($healthPid)) {
    Write-Host "Huawei Health is not running. Trying to start it..."
    & $adb shell monkey -p com.huawei.health -c android.intent.category.LAUNCHER 1 | Out-Null
    Start-Sleep -Seconds 3
    $healthPid = (& $adb shell pidof com.huawei.health).Trim()
}

if ([string]::IsNullOrWhiteSpace($healthPid)) {
    throw "Huawei Health process was not found after launch attempt."
}

Write-Host "Huawei Health PID: $healthPid"

$patterns = @(
    "initAppMarketCard",
    "fetchAppMarketCapability",
    "isSupportMarketFace",
    "isSupportMarketParams",
    "isSupportAppGallery",
    "isSingleWatchSupportAppGallery",
    "handMarketCapability",
    "COMMAND_ID_MARKET",
    "COMMAND_ID_MARKET_PARAMS",
    "AppMarketStrategy",
    "openAppMarketView",
    "HwSmartAppMarketLoadingActivity",
    "AppGalleryProxy",
    "PluginWearAbility",
    "wearAppInstallState",
    "QUERY_DEVICE_APP_INSTALL_INFO_ENUM",
    "WEAR_APP_INSTALLATION_REPORT_ENUM"
)

$regex = $patterns -join "|"
$fullJob = Start-Job -ScriptBlock {
    param($adbPath, $processId, $outPath)
    & $adbPath logcat -v time --pid=$processId | Tee-Object -FilePath $outPath
} -ArgumentList $adb, $healthPid, $fullLogPath

$matchJob = Start-Job -ScriptBlock {
    param($adbPath, $processId, $filterRegex, $outPath)
    & $adbPath logcat -v time --pid=$processId | Select-String -Pattern $filterRegex | ForEach-Object {
        $_.Line | Tee-Object -FilePath $outPath -Append
    }
} -ArgumentList $adb, $healthPid, $regex, $matchLogPath

Start-Sleep -Seconds 90
Stop-Job $fullJob,$matchJob -ErrorAction SilentlyContinue
Receive-Job $fullJob,$matchJob -ErrorAction SilentlyContinue | Out-Null
Remove-Job $fullJob,$matchJob -Force -ErrorAction SilentlyContinue

Write-Host ""
Write-Host "Probe complete. Matched log saved to: $matchLogPath"
Write-Host "Full Huawei Health log saved to: $fullLogPath"

if (Test-Path $matchLogPath) {
    Write-Host ""
    Write-Host "Matched lines:"
    Get-Content $matchLogPath
} else {
    Write-Host "No matching lines captured. The full Huawei Health log may still contain useful obfuscated tags."
}
