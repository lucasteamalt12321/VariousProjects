# Tech Context

## Environment

- OS: Windows
- Workspace: `C:\Users\admin\Documents\GD-shrink`
- Local ADB: `tools/platform-tools/adb.exe`
- Apktool available locally:
  - `tools/apktool.jar`
  - `tools/apktool.bat`
- Node.js available
- .NET SDK installed: `8.0.420`
- No local `aapt` found in the workspace during the latest check.

## Current Source Artifact

- `2_3_4_player_mini_games_v5_8_2.apk`
  - Size: `81802469` bytes
  - Top-level APK contents include `classes*.dex`, `lib/`, `assets/`, `res/`, `AndroidManifest.xml`, `resources.arsc`.

## APK Technical Findings

- Engine/runtime clues:
  - `lib/arm64-v8a/libyoyo.so`
  - `lib/armeabi-v7a/libyoyo.so`
  - `lib/x86_64/libyoyo.so`
  - `assets/game.droid` (~76 MB)
  - `assets/options.ini`
- Audio/resources:
  - `assets/music*.ogg`
  - `assets/sfx*.ogg`
  - `assets/splash.png`
  - `assets/portrait_splash.png`
- Interpretation: GameMaker/YoYo Android build.

## Connected Phone Findings

ADB device observed:

- `0C64924I2510270B`

Installed package candidates observed on the phone:

- `com.ction.playergames`
  - versionName: `5.7.4`
  - versionCode: `5007004`
  - launcher activity: `com.ction.playergames/.RunnerActivity`
  - primary ABI: `arm64-v8a`
  - installer: `com.android.vending`
- `com.PlayMax.playergames`
  - versionName: `2.4.9.2`
  - launcher activity: `com.PlayMax.playergames/com.unity3d.player.UnityPlayerActivity`
  - Unity split APKs present

The local `v5.8.2` APK should be inspected directly before assuming package/activity, but its GameMaker structure aligns more closely with the `com.ction.playergames` style than the Unity package.

## Tools Needed Next

- Apktool decode of local APK into a subdirectory, not root.
- Android runtime/emulator choice for Windows. In this session, do not use BlueStacks per user instruction.
- ADB launch/install automation.
- Keyboard-to-touch/key mapping strategy. Depending on chosen runtime, this can be:
  - runtime-native keymap config;
  - ADB `input` event injection prototype;
  - Windows overlay/hook launcher;
  - emulator-specific macro/keymap file.

## Risks

- Emulator distribution can be large and licensing/redistribution terms must be checked.
- APK may require Google Play Services or runtime permissions.
- Some mini-games may use dynamic touch zones, making a single static keymap insufficient.
- Four-player keyboard ghosting can break simultaneous input on common keyboards.
- ADB `input tap` may be too slow for real-time gameplay; emulator-native key mapping is likely better for final playability.

## Runtime Search 2026-05-01

- BlueStacks was detected locally but user instructed not to use it in this session.
- Alternative runtimes were not found in common paths/registry: Android Studio Emulator, LDPlayer, Nox, MEmu, Genymotion, MuMu, GameLoop, WSA.
- `windows-launcher` is now runtime-neutral and supports manual runtime executable paths plus optional `adbConnectEndpoint`.

## Historical Note

Previous Huawei Band 10 research is no longer the active project direction. It remains in git history and older artifacts, but current work should target APK-to-Windows wrapper delivery.
