# Architecture Overview

## Project Shape

This repository is now focused on creating a Windows-runnable wrapper for the Android APK `2_3_4_player_mini_games_v5_8_2.apk`.

The selected implementation path is **Variant A**: a Windows launcher that starts an Android runtime/emulator, installs or updates the APK, launches the game, and applies keyboard mapping for local 2-4 player gameplay.

## Main Areas

- `memory_bank/` stores the current project context, deliverables, progress, and decisions.
- `windows-launcher/` contains the current .NET 8 launcher prototype for ADB/runtime automation.
- `2_3_4_player_mini_games_v5_8_2.apk` is the current source artifact for the Windows-wrapper effort.
- `tools/platform-tools/adb.exe` is available for Android runtime/device automation.
- `tools/apktool.jar` and `tools/apktool.bat` are available for APK manifest/resource inspection.
- Existing APK/Huawei/Band 10 artifacts remain in the workspace as historical research material and are not the current focus.

## Current APK Findings

The local APK appears to be a GameMaker/YoYo Android build:

- `assets/game.droid`
- `assets/options.ini`
- `lib/arm64-v8a/libyoyo.so`
- `lib/armeabi-v7a/libyoyo.so`
- `lib/x86_64/libyoyo.so`
- `assets/music*.ogg` and `assets/sfx*.ogg`

The presence of `lib/x86_64/libyoyo.so` is useful for Android emulators/runtimes on Windows because it may reduce dependence on ARM translation.

## Target Runtime Architecture

The intended runtime flow is:

1. User starts a Windows launcher.
2. Launcher starts or connects to an Android runtime/emulator.
3. Launcher waits for ADB readiness.
4. Launcher installs the APK when missing or outdated.
5. Launcher starts the game package/activity.
6. Keyboard mapping converts host keyboard input into Android input/touch actions.

This is a practical wrapper, not a native Windows port. A native port would require original GameMaker project sources or substantial reverse engineering of `assets/game.droid`, which is deferred.

## Launcher Prototype

`windows-launcher/` contains the first executable prototype:

- `PlayerGamesLauncher.csproj` - .NET 8 console project.
- `Program.cs` - launcher workflow.
- `launcher-config.json` - paths and package/activity settings.
- `keymap.example.json` - keyboard profile source for the selected emulator/runtime.
- `configs/manual-adb.json` - runtime-neutral config for any already-visible ADB device/runtime.
- `configs/android-studio-emulator.example.json`, `configs/ldplayer.example.json`, `configs/nox.example.json` - editable templates for non-BlueStacks runtimes.

Current launcher behavior:

1. Load config.
2. Validate `adb.exe` and APK paths.
3. Optionally start a configured Android runtime executable.
4. Start ADB server and wait for a device/runtime.
5. Install APK when missing, unless install is skipped.
6. Launch configured package/activity.

Example command from repository root:

```powershell
dotnet run --project .\windows-launcher\PlayerGamesLauncher.csproj
```

The launcher can target any runtime/device visible to `tools/platform-tools/adb.exe`. Runtime-specific startup should be added to `launcher-config.json` once the Android runtime/emulator is selected.

Per current user instruction, BlueStacks is not used in this session. The launcher is kept runtime-neutral and currently focuses on manual ADB plus non-BlueStacks templates.

Latest smoke test:

```powershell
dotnet run --project .\windows-launcher\PlayerGamesLauncher.csproj -- --no-install
```

This successfully started `com.ction.playergames/.RunnerActivity` on the currently connected ADB device. The next step is to choose and automate a Windows Android runtime/emulator instead of relying on a phone.

## Keyboard Mapping Direction

Candidate default keyboard layout:

- Player 1: `WASD`, `Space`, `Left Shift`
- Player 2: arrow keys, `Enter`, `Right Shift`
- Player 3: `IJKL`, `U`, `O`
- Player 4: numpad `8456`, `Numpad0`, `Numpad1`

The final mapping must be validated in real gameplay because mini-games may use different touch zones or dynamic controls. Four-player keyboard ghosting must be tested.

## Current Risks

- APK-to-native-EXE conversion is not realistic as a direct transformation.
- Emulator/runtime choice affects input latency, packaging size, and redistribution constraints.
- ADB `input tap` is likely insufficient for fast action gameplay, so emulator-native key mapping or lower-level input integration may be needed.
- Public redistribution of the APK/brand/assets may require rights from the owner.
