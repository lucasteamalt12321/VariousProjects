# System Patterns

## Workspace Pattern

This repository is a research and tooling workspace for Android APK inspection, Windows launch automation, and packaging experiments.

## Current Architecture Pattern

The selected solution is a Windows wrapper around an Android runtime/emulator:

1. Windows launcher starts or locates the Android runtime/emulator.
2. Launcher waits until ADB reports the runtime as ready.
3. Launcher installs or updates `2_3_4_player_mini_games_v5_8_2.apk` when needed.
4. Launcher starts the APK launcher activity.
5. Keyboard mapping translates Windows keyboard input into Android touch/key events suitable for local 2-4 player gameplay.

This pattern prioritizes practical playability over a native Windows port.

## APK Pattern

The local APK appears to be a GameMaker/YoYo Android build rather than Unity:

- `assets/game.droid` contains the GameMaker game data.
- `assets/options.ini` contains GameMaker-style runtime options.
- `lib/*/libyoyo.so` contains the YoYo native runtime.
- `lib/x86_64/libyoyo.so` suggests the APK can potentially run efficiently on x86_64 Android emulators/runtimes without ARM translation.

Because the APK depends on Android lifecycle and YoYo Android runtime, it is not directly convertible to a native Windows `.exe` without either original GameMaker project sources or substantial reverse engineering.

## Launcher Pattern

The launcher should be kept small and explicit:

- Validate configured paths.
- Start runtime/emulator.
- Poll readiness via ADB.
- Query installed package version.
- Install APK only when missing or outdated.
- Start package/activity.
- Optionally manage fullscreen/window state.
- Exit cleanly and leave logs for troubleshooting.

Configuration should live outside code in a user-editable file, for example JSON or TOML.

## Input Mapping Pattern

Use an abstraction layer instead of hard-coding raw keys directly into game launch logic:

- `RawInput`: physical keyboard state or host-level hotkeys.
- `Binding`: player/action to host key mapping.
- `AndroidEvent`: translated touch/key event sent to runtime.
- `Profile`: presets for 2, 3, and 4 players.

Default keyboard layout candidate:

- Player 1: `WASD`, `Space`, `Left Shift`.
- Player 2: arrow keys, `Enter`, `Right Shift`.
- Player 3: `IJKL`, `U`, `O`.
- Player 4: numpad `8456`, `Numpad0`, `Numpad1`.

Keyboard ghosting must be tested, especially for four players pressing multiple keys simultaneously.

## Deferred Pattern: Native/GameMaker Port

Reverse engineering `assets/game.droid` may later be used to understand GameMaker internals or input logic, but it is not the primary architecture. It is risky because Android `game.droid` is not a direct Windows `data.win` replacement and may not yield a reliable buildable project.
