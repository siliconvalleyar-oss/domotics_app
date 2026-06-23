# Deploy Flutter App to Mobile

Build the Flutter APK and install it on a connected Android device via ADB.

## Prerequisites

- Android device connected via USB or ADB WiFi (`adb devices` should show the device)
- Flutter SDK installed

## Usage

Call this skill when the user wants to build and install the Flutter app on their phone. Phrases like "subir al móvil", "install on phone", "deploy to device", "build and install".

## Steps

### 1. Check connected devices
```bash
adb devices
flutter devices
```

Verify an Android device appears in the list (look for `android-arm64` or `android-arm`).

### 2. Clean previous build (optional)
If the user wants a clean build:
```bash
flutter clean && flutter pub get
```

### 3. Build release APK
```bash
flutter build apk --release
```

### 4. Install on device
```bash
adb install -r build/app/outputs/flutter-apk/app-release.apk
```

### 5. Verify
Check the exit code of `adb install` — it should say `Success`.

## Notes

- If the build fails with dependency issues, run `flutter pub outdated` to check for newer compatible versions.
- The APK is ~45 MB for this project.
- The app name in pubspec.yaml is `liquid_glass_app`.
