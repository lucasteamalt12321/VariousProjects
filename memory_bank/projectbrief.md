# Project Brief

## Overview

Проект сменил фокус: нужно получить Windows-запускаемый вариант Android APK **2 3 4 Player Mini Games** с клавиатурным управлением для локальной игры 2-4 игроков.

Исходный APK:

- `2_3_4_player_mini_games_v5_8_2.apk`

Выбранный практический путь: **Variant A** - Windows launcher/обертка, которая запускает Android runtime/emulator, устанавливает/обновляет APK при необходимости, стартует игру и применяет keyboard mapping.

Это не native Windows port и не clean remake. Цель первого этапа - рабочий запуск на Windows через `.exe` или близкий Windows-friendly launcher.

## Scope

- Провести read-only диагностику APK и зафиксировать package/activity/engine/runtime clues.
- Выбрать подходящий Android runtime/emulator для Windows.
- Сделать прототип запуска APK с Windows через ADB/runtime automation.
- Настроить клавиатурное управление для 2, 3 и 4 игроков.
- Упаковать результат как Windows-запускаемый комплект.

## Out of Scope

- Native reverse engineering GameMaker `game.droid` как основной путь.
- Clean remake игры с нуля.
- Распространение чужого APK/ассетов как публичного продукта без прав.
- Изменение APK, обход DRM, рекламы, платежей или защит.

## Project Deliverables

- [D1] APK diagnostics and launch metadata - completed - 15%
- [D2] Android runtime/emulator selection - pending - 15%
- [D3] Windows launcher prototype - in_progress - 25%
- [D4] Keyboard mapping for 2-4 players - in_progress - 25%
- [D5] Packaged Windows distribution - pending - 20%
