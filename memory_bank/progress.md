# Progress

## Status

Проект переориентирован на Windows-запускаемый вариант APK **2 3 4 Player Mini Games**. Пользователь выбрал **Variant A**: Windows launcher/обертка, которая запускает Android runtime/emulator, устанавливает или обновляет APK, стартует игру и обеспечивает клавиатурное управление для 2-4 игроков.

Канонический прогресс считается по `memory_bank/projectbrief.md` / `## Project Deliverables`. Сейчас завершенность: `15%` подтвержденно завершенных deliverables; `D1` завершен, `D3` и `D4` находятся в работе.

## Known Issues

- APK нельзя напрямую превратить в native Windows `.exe` без Android runtime или полноценного портирования.
- Локальный APK выглядит как GameMaker/YoYo Android build (`libyoyo.so`, `assets/game.droid`), а не Unity.
- Нужно напрямую подтвердить package name и launcher activity локального APK `v5.8.2` через decode/manifest-анализ.
- Нужно выбрать Android runtime/emulator с приемлемой автоматизацией, производительностью и условиями распространения.
- ADB `input tap` может быть недостаточно быстрым для gameplay; финальный keyboard mapping лучше делать средствами runtime/emulator или более низкоуровневой интеграцией.
- Необходимо проверить, требуют ли игра и выбранный runtime Google Play Services, интернет или дополнительные разрешения.
- Нужно проверить клавиатурный ghosting для 4 игроков.
- Распространение APK/ассетов/брендинга может требовать прав правообладателя; текущий фокус - локальный технический запуск.

## Changelog

- 2026-05-01: Пользователь предоставил локальный APK `2_3_4_player_mini_games_v5_8_2.apk` и уточнил цель: получить `.exe` или другой Windows-поддерживаемый запуск.
- 2026-05-01: Проведена первичная read-only диагностика APK: размер `81802469` bytes; обнаружены `assets/game.droid`, `assets/options.ini`, `lib/*/libyoyo.so`, `lib/x86_64/libyoyo.so`, `assets/*.ogg`; сделан вывод о GameMaker/YoYo Android build.
- 2026-05-01: На подключенном телефоне найдены пакеты `com.ction.playergames` (`5.7.4`, `.RunnerActivity`) и `com.PlayMax.playergames` (Unity, `2.4.9.2`); локальный APK по структуре относится к GameMaker/YoYo-пути.
- 2026-05-01: Выбран Variant A: Windows launcher + Android runtime/emulator + keyboard mapping как основной практический путь.
- 2026-05-01: `memory_bank` переписан под новый фокус APK-to-Windows wrapper; старое направление Huawei Band 10 закрыто как историческое и неактивное.
- 2026-05-01: Добавлен `windows-launcher/` - .NET 8 console launcher с JSON-конфигом. Он запускает ADB, ждет Android runtime/device, устанавливает APK при необходимости и стартует package/activity.
- 2026-05-01: Добавлен `windows-launcher/keymap.example.json` со стартовыми раскладками для 2 и 4 игроков. Финальная реализация mapping зависит от выбранного emulator/runtime.
- 2026-05-01: `windows-launcher` успешно собран через `dotnet build`; dry-run с `--no-install` запустил `com.ction.playergames/.RunnerActivity` на подключенном Android-устройстве.
- 2026-05-01: По просьбе пользователя BlueStacks исключен из текущей сессии; BlueStacks-specific code/config удалены. Добавлены runtime-neutral example configs для manual ADB, Android Studio Emulator, LDPlayer и Nox.
- 2026-05-01: Проверка альтернативных runtime не нашла установленный Android Studio Emulator/LDPlayer/Nox/MEmu/Genymotion/MuMu/GameLoop/WSA. Launcher успешно собирается и manual ADB smoke test остается рабочим.
- 2026-05-10: Синхронизация локального репозитория с GitHub. Применены изменения из удаленной ветки origin/master с приоритетом GitHub в случае конфликтов.

## last_checked_commit

ca64b82
