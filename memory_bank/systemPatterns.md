# System Patterns

## Workspace Pattern

This repository is acting as a research and tooling workspace rather than a single clean application repository.

## Huawei Band 10 Access Pattern

Observed likely architecture:

1. Huawei Health Android app
2. Internal Huawei device SDK layer (`com.huawei.devicesdk`)
3. Unite-device abstraction (`UniteDevice`)
4. Device-specific transport to Huawei Band 10

This suggests the most promising reverse-engineering entry points are not raw Android BLE APIs in app code, but Huawei's internal devicesdk abstraction and callbacks.

## Band 10 Identification

Huawei Health `assets/product_map.json` maps HUAWEI Band 10 to model family `NOR`:

- `NOR-B19`, `smartProductId` `M0EK`, `deviceId` 823
- `NOR-B29`, `smartProductId` `M0EL`, `deviceId` 824
- `NOR-B39`, `smartProductId` `M0EM`, `deviceId` 825
- shared `productId`: `356aab94-7fec-465b-8936-8afff0c7d811`
- `deviceType`: `06E`

## File Transfer / Watchface Pattern

Huawei Health contains GRS configs for `com.huawei.hms.opendevicesdk` and `com.huawei.watchface`. ArkUI-X raw protocol file `serviceId_40.json` describes file/resource transfer fields including `fileName`, `fileType`, `resourceType`, package names, certificates, `watchfaceId`, and `watchfaceVersion`.

Current interpretation: this is a promising reverse-engineering path for resource/watchface deployment, but not yet evidence of arbitrary app installation on Band 10.

## Companion App Pattern

The prepared app at `band10-companion/` follows an Android companion pattern:

- `WearEngineClient` for wearable discovery/integration path
- `HealthKitClient` for health data path
- `HuaweiAuthClient` for Huawei auth/config path

Huawei Wear Engine documentation confirms this is a phone-side API for Android apps to interact with paired wearables. It does not provide a native Band 10 application runtime or installer path.
