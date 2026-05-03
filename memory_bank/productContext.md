# Product Context

## User Goal

Пользователь хочет превратить Android APK **2 3 4 Player Mini Games** в вариант, который запускается на Windows как `.exe` или другой Windows-поддерживаемый пакет.

## Target Experience

- Пользователь запускает Windows launcher.
- Launcher автоматически поднимает Android runtime/emulator.
- APK устанавливается или обновляется без ручных действий пользователя.
- Игра стартует в окне или fullscreen.
- Управление выполняется с клавиатуры для 2-4 локальных игроков.

## Source Artifact

- `C:\Users\admin\Documents\GD-shrink\2_3_4_player_mini_games_v5_8_2.apk`

## Current Decision

Выбран **Variant A**: Windows launcher + Android runtime/emulator + keyboard mapping.

Причина: APK нельзя надежно конвертировать в native `.exe` одной командой. APK содержит Android-приложение и GameMaker/YoYo Android runtime, поэтому самый практичный путь - запускать его внутри Android runtime, скрывая сложность за Windows launcher.

## Constraints

- Это practical wrapper, а не native Windows port.
- Итоговый пакет может быть крупным из-за Android runtime/emulator.
- Keyboard mapping должен учитывать touch-зоны игры и одновременный ввод 2-4 игроков.
- Распространение APK/ассетов/брендинга может требовать прав правообладателя; текущий технический фокус - personal-use/локальный запуск.
- Не выполнять обход DRM, платежей, рекламы или защит.

## Alternatives Deferred

- GameMaker reverse engineering `assets/game.droid` для потенциального native-like порта отложен как рискованный исследовательский путь.
- Clean remake отложен, потому что пользователь хочет использовать имеющийся APK.
