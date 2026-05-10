param(
    [string]$Endpoint = "https://update-drru.platform.hicloud.com/ring2/v2/CheckEx.action?ruleAttr=true",
    [string]$Model = "NOR-B29",
    [string]$Firmware = "5.0.0.157(SP2C00M04)",
    [string]$DeviceName = "NOR-B29",
    [string]$SmartProductId = "M0EL",
    [string]$OtaProductId = "00M0EL",
    [string]$ProductId = "356aab94-7fec-465b-8936-8afff0c7d811",
    [string]$Language = "ru-RU",
    [string]$OutputPath = "band10_ota_metadata_probe.jsonl"
)

$ErrorActionPreference = "Stop"

function Invoke-OtaProbe {
    param(
        [string]$Name,
        [hashtable]$Body
    )

    $json = $Body | ConvertTo-Json -Depth 10 -Compress
    $record = [ordered]@{
        probe = $Name
        endpoint = $Endpoint
        request = $Body
        statusCode = $null
        response = $null
        error = $null
    }

    try {
        $response = Invoke-WebRequest `
            -Uri $Endpoint `
            -Method Post `
            -ContentType "application/json; charset=utf-8" `
            -Body $json `
            -UseBasicParsing `
            -TimeoutSec 30

        $record.statusCode = [int]$response.StatusCode
        $record.response = $response.Content
    }
    catch {
        $record.error = $_.Exception.Message
        if ($_.Exception.Response -and $_.Exception.Response.StatusCode) {
            $record.statusCode = [int]$_.Exception.Response.StatusCode
        }
    }

    ($record | ConvertTo-Json -Depth 12 -Compress) | Add-Content -Path $OutputPath -Encoding UTF8
    return $record
}

if (Test-Path $OutputPath) {
    Remove-Item $OutputPath
}

$firmwareFull = "$Model $Firmware"
$firmwareOtaProduct = "$OtaProductId $Firmware"

function New-Rules {
    param(
        [string]$RuleDeviceName,
        [string]$RuleFirmware,
        [string]$PackageType = "full"
    )

    return [ordered]@{
        FingerPrint = ""
        DeviceName = $RuleDeviceName
        FirmWare = $RuleFirmware
        PackageType = $PackageType
        Language = $Language
        OS = "Android"
        C_version = ""
        D_version = ""
    }
}

$commonRules = New-Rules -RuleDeviceName $DeviceName -RuleFirmware $firmwareFull
$otaRules = New-Rules -RuleDeviceName $OtaProductId -RuleFirmware $firmwareOtaProduct
$modelOnlyRules = New-Rules -RuleDeviceName $DeviceName -RuleFirmware $Firmware

$candidatePackages = @(
    $Model,
    $SmartProductId,
    $OtaProductId,
    $ProductId,
    $firmwareFull,
    $firmwareOtaProduct
)

$candidateBodies = @()

foreach ($packageName in $candidatePackages) {
    $candidateBodies += [ordered]@{
        name = "components-$packageName-model-rules"
        body = [ordered]@{
            components = @(
                [ordered]@{
                    PackageName = $packageName
                    PackageVersionCode = $Firmware
                    PackageVersionName = $Firmware
                }
            )
            rules = $commonRules
        }
    }

    $candidateBodies += [ordered]@{
        name = "components-$packageName-ota-rules"
        body = [ordered]@{
            components = @(
                [ordered]@{
                    PackageName = $packageName
                    PackageVersionCode = $Firmware
                    PackageVersionName = $Firmware
                }
            )
            rules = $otaRules
        }
    }
}

$candidateBodies += @(
    [ordered]@{
        name = "version-package-rules-type-6-model"
        body = [ordered]@{
            versionPackageRules = @(
                [ordered]@{
                    versionPackageType = 6
                    rules = $commonRules
                }
            )
        }
    },
    [ordered]@{
        name = "version-package-rules-type-6-ota"
        body = [ordered]@{
            versionPackageRules = @(
                [ordered]@{
                    versionPackageType = 6
                    rules = $otaRules
                }
            )
        }
    },
    [ordered]@{
        name = "version-package-rules-type-6-model-only-firmware"
        body = [ordered]@{
            versionPackageRules = @(
                [ordered]@{
                    versionPackageType = 6
                    rules = $modelOnlyRules
                }
            )
        }
    }
)

<#
$commonRules = [ordered]@{
    FingerPrint = ""
    DeviceName = $DeviceName
    FirmWare = $firmwareFull
    PackageType = "full"
    Language = $Language
    OS = "Android"
    C_version = ""
    D_version = ""
}

$candidateBodies = @(
    [ordered]@{
        name = "rules-components-model-firmware"
        body = [ordered]@{
            components = @(
                [ordered]@{
                    PackageName = $Model
                    PackageVersionCode = $Firmware
                    PackageVersionName = $Firmware
                }
            )
            rules = $commonRules
        }
    },
    [ordered]@{
        name = "version-package-rules-type-6"
        body = [ordered]@{
            versionPackageRules = @(
                [ordered]@{
                    versionPackageType = 6
                    rules = $commonRules
                }
            )
        }
    },
    [ordered]@{
        name = "rules-components-product-firmware"
        body = [ordered]@{
            components = @(
                [ordered]@{
                    PackageName = "356aab94-7fec-465b-8936-8afff0c7d811"
                    PackageVersionCode = $Firmware
                    PackageVersionName = $Firmware
                }
            )
            rules = $commonRules
        }
    }
)
#>

foreach ($candidate in $candidateBodies) {
    $result = Invoke-OtaProbe -Name $candidate.name -Body $candidate.body
    Write-Host ("{0}: HTTP {1}" -f $result.probe, $result.statusCode)
    if ($result.error) {
        Write-Host ("  error: {0}" -f $result.error)
    }
}

Write-Host ("Saved responses to {0}" -f (Resolve-Path $OutputPath))
