# Product Context

## User Goal

Пользователь хочет разрабатывать приложения, которые запускаются НА самих часах Huawei Band 10 (не companion на телефоне). Пример: калькулятор.

## User Experience

- Huawei Band 10 на руке пользователя
- Ранее не занимался разработкой под носимые устройства

## Constraints

- Huawei Band 10 does not appear to expose an obvious direct ADB path.
- Official Huawei developer access is partially blocked until Huawei Developer Console is available and usable.
- Direct BLE discovery has not yielded a stable, clearly identified Band 10 advertisement.
- Band 10 работает на Huawei Lite OS (RTOS) - нужен соответствующий SDK.
- Публичный Huawei Wear Engine решает companion-сценарии через Android-телефон и не является SDK для установки приложений непосредственно на Band 10.
- Пока не найдено публичного подтверждения, что Band 10 поддерживает пользовательские сторонние приложения; наиболее подтвержденный канал кастомизации - циферблаты/ресурсы через Huawei Health.

## Current Product Direction (ПЕРЕСМОТР)

Цель - разработка приложений под саму систему часов (Lite OS), а не companion на телефон.
