# Active Context

## Current Focus

**Прерванная задача:** Установка **OpenCode** на подключенный Android-телефон `0C64924I2510270B` через Termux. Требуется завершить настройку PATH и проверить запуск `opencode`.

**Предыдущая задача (в паузе):** Начать **Variant A** для `2_3_4_player_mini_games_v5_8_2.apk` - сделать Windows-запускаемый вариант через Android runtime/emulator и клавиатурный mapping.

## User Request

Пользователь уточнил: нужно не переписывать игру, а превратить APK в `.exe` или другой Windows-поддерживаемый запуск. После объяснения вариантов выбран Variant A. APK получен с телефона (`adb pull`).

## Known APK Facts

- Локальный APK: `2_3_4_player_mini_games_v5_8_2.apk`.
- Размер APK: около 78 MB (`81802469` bytes).
- APK содержит признаки GameMaker/YoYo runtime:
  - `lib/arm64-v8a/libyoyo.so`
  - `lib/armeabi-v7a/libyoyo.so`
  - `lib/x86_64/libyoyo.so`
  - `assets/game.droid`
  - `assets/options.ini`
- В APK есть `x86_64` native library, что полезно для Android emulator/runtime на Windows.
- APK содержит музыку и звуки в `assets/*.ogg`.

## Device APK Facts

На подключенном Android-телефоне были найдены два похожих пакета:

- `com.ction.playergames` - версия `5.7.4`, launcher activity `.RunnerActivity`, установлен из `com.android.vending`.
- `com.PlayMax.playergames` - Unity-приложение, версия `2.4.9.2`, launcher activity `com.unity3d.player.UnityPlayerActivity`.

Локальный APK `v5.8.2` по структуре соответствует GameMaker/YoYo-пути, а не Unity.

## Working Plan

1. Выбрать Android runtime/emulator для автоматизированного Windows запуска.
2. Проверить установку и запуск APK через `windows-launcher` на видимом ADB runtime/device.
3. Настроить клавиатурный mapping для touch-зон игры в выбранном runtime/emulator.
4. Расширить launcher под выбранный runtime: fullscreen/window management, boot wait, logs.
5. Упаковать рабочий комплект и проверить запуск.

## Current Implementation

- Добавлен проект `windows-launcher/PlayerGamesLauncher.csproj`.
- `windows-launcher/Program.cs` реализует консольный launcher:
  - читает `launcher-config.json`;
  - проверяет ADB и APK;
  - опционально запускает Android runtime executable из конфига;
  - запускает ADB server;
  - ждет устройство/runtime через `adb wait-for-device`;
  - устанавливает APK в режиме `ifMissing`/`always`/`skip`;
  - запускает `package/activity` через `adb shell am start` или fallback `monkey`.
- `windows-launcher/keymap.example.json` содержит стартовые keyboard profiles для 2 и 4 игроков.
- Локально `java` не найден в `PATH`, поэтому apktool-анализ пока не использован; package/activity взяты из установленного пакета `com.ction.playergames` и должны быть подтверждены запуском локального APK.
- Dry-run `dotnet run --project windows-launcher -- --no-install` успешно отработал на подключенном ADB-устройстве `0C64924I2510270B` и запустил `com.ction.playergames/.RunnerActivity`.
- По просьбе пользователя BlueStacks не используется в текущей сессии. BlueStacks-specific код и sample config были удалены из launcher.
- Добавлены neutral/example конфиги для альтернативных runtime:
  - `windows-launcher/configs/manual-adb.json`
  - `windows-launcher/configs/android-studio-emulator.example.json`
  - `windows-launcher/configs/ldplayer.example.json`
  - `windows-launcher/configs/nox.example.json`
- Локально альтернативный Android runtime/emulator не найден: Android SDK emulator, LDPlayer, Nox, MEmu, Genymotion, MuMu, GameLoop и WSA не обнаружены в обычных путях/registry.

## OpenCode on Phone (In Progress)

- **Termux v0.118.3** установлен на телефон `0C64924I2510270B` через ADB (`adb install`).
- **Node.js v25.8.2** установлен в Termux через `pkg install nodejs`.
- **OpenCode v1.14.46** установлен в `~/.opencode/bin/` через официальный скрипт `curl -fsSL https://opencode.ai/install | bash`.
- Создан скрипт `/sdcard/setup_opencode.sh` для настройки PATH и проверки версии.
- **Проблема при запуске:** `opencode --version` выдает ошибку `bash: export: '--version': not a valid identifier`. Возможно, бинарник отсутствует или файл `opencode` является shell-скриптом с некорректным заголовком.
- Создан диагностический скрипт `/sdcard/diag.sh` для проверки содержимого `~/.opencode/bin/` и тестового запуска.
- **Следующий шаг:** Запустить диагностический скрипт в Termux и по результатам решить: переустановить OpenCode, или исправить бинарник, или использовать альтернативный способ установки.

## Notes

- Старый фокус Huawei Band 10 закрыт и больше не является текущей целью проекта.
- Не вносить изменения в APK без отдельной необходимости; первый путь - wrapper/runtime automation.
- ADB input injection не выбран для финального игрового управления из-за ожидаемой задержки; keymap должен применяться средствами runtime/emulator или отдельной низкоуровневой интеграцией.
- Следующий практический шаг: установить/подготовить non-BlueStacks runtime, предпочтительно Android Studio Emulator или LDPlayer/Nox, затем подключить его через соответствующий config.
