# Active Context

## Current Focus

Фокус изменился: теперь цель - разработка приложений, которые запускаются НА самих часах Huawei Band 10 (Lite OS), а не companion на телефон.

## Что уже сделано (предыдущее)

- BLE scanning из PC не дал четкого идентифицируемого устройства Band 10.
- `HuaweiHealth-base.apk` выгружен с телефона.
- Создан Android companion проект в `band10-companion/`.

## Текущая задача

Продолжить исследование разработки под Huawei Band 10: проверить наличие официального Lite OS / wearable SDK, выяснить поддерживается ли установка сторонних приложений на Band 10, и отделить реальный путь разработки под часы от companion-подхода через Android.

## Найдено 2026-04-29

- В `HuaweiHealth_apktool/assets/product_map.json` Band 10 явно присутствует как семейство `NOR`: `NOR-B19` (`deviceId` 823), `NOR-B29` (`deviceId` 824), `NOR-B39` (`deviceId` 825), общий `productId` `356aab94-7fec-465b-8936-8afff0c7d811`, `deviceType` `06E`.
- Публичный Huawei Wear Engine, найденный на developer.huawei.com, предназначен для Android-приложений на телефоне: список сопряженных wearables, статусы, сенсоры, уведомления и phone-wearable communication. Это не SDK для сборки и установки нативных приложений прямо на Band 10.
- В Huawei Health есть конфиги `com.huawei.hms.opendevicesdk` (`assets/grs_sdk_global_route_config_opendevicesdk.json`) и `com.huawei.watchface` (`assets/grs_sdk_global_route_config_watchfaceconnector.json`). Это подтверждает наличие закрытого/внутреннего слоя устройств и отдельного канала циферблатов.
- В `assets/arkui-x/arkuix/resources/rawfile/serviceId_40.json` есть схема передачи файлов с полями `fileName`, `fileType`, `srcPkgName`, `desPkgName`, `watchfaceId`, `watchfaceVersion`, `srcCertificate`, `destCertificate`. Пока это выглядит как служебный протокол передачи ресурсов/циферблатов, а не доказательство установки произвольных приложений.
- В текущих найденных публичных материалах нет подтверждения, что Huawei Band 10 поддерживает установку сторонних нативных приложений пользователем.

## Next Step

1. Исследовать путь установки/передачи пакетов через Huawei Health: `watchface`, `opendevicesdk`, `serviceId_40` и связанные smali-вызовы.
2. Найти, какие `fileType`/`resourceType` поддерживаются для Band 10 и есть ли тип, похожий на приложение, а не циферблат/ресурс.
3. Проверить официальные ограничения Band 10: поддерживает ли модель `NOR-*` вообще сторонние приложения или только циферблаты/служебные ресурсы.
