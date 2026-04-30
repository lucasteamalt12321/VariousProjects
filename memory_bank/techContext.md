# Tech Context

## Environment

- OS: Windows
- Local JDK: `tools/jdk-17.0.18+8`
- Local Android SDK: `tools/android-sdk`
- Local ADB: `tools/platform-tools/adb.exe`
- .NET SDK installed: `8.0.420`
- Node.js available
- Apktool available locally

## Key Artifacts

- Huawei Health APK pulled from device:
  - `HuaweiHealth-base.apk`
- Decompiled Huawei Health APK:
  - `HuaweiHealth_apktool/`
- Android companion starter app:
  - `band10-companion/`
- BLE scanner prototype:
  - `BleScan.csproj`
  - `Program.cs`

## Notes

- Official Huawei path is blocked until Huawei Developer Console access is usable.
- BLE scanning on PC works, but Band 10 has not been identified as a stable openly named BLE peripheral.
- Public Wear Engine docs were reachable and describe Android-side wearable integration: device list, status, health/fitness status, phone-wearable communication, sensor management.
- Local Huawei Health APK contains `assets/product_map.json`, `assets/grs_sdk_global_route_config_opendevicesdk.json`, `assets/grs_sdk_global_route_config_watchfaceconnector.json`, and ArkUI-X raw protocol configs useful for further reverse engineering.
