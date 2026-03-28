# Run on Android Device

## Prerequisites
- Android phone with Developer Options enabled.
- USB debugging enabled.
- Android SDK + Flutter installed.

## Connect Device
1. Connect phone via USB.
2. Run:
   ```bash
   flutter devices
   ```
3. Accept USB debugging prompt on phone if shown.

## Run App
1. From `frontend/` run:
   ```bash
   flutter pub get
   flutter run
   ```
2. If multiple devices are connected, run:
   ```bash
   flutter run -d <device_id>
   ```

## Common Fixes
- If no device appears: run `adb devices` and re-authorize USB debugging.
- If Gradle build fails once, run `flutter clean` then `flutter run`.
- If notifications do not appear, verify app notification permission/settings on device.
