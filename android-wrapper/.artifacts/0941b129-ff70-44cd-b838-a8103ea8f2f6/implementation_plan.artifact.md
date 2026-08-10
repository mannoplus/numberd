# Implementation Plan - Fix App Icon and Complete Branding

Address the issue of the app icon not showing on devices and finalize the premium branding.

## Proposed Changes

### Android Manifest Updates

#### [MODIFY] [AndroidManifest.xml](file:///Users/thebass/Documents/BigMisc/projnumbrd/numberd/android-wrapper/app/src/main/AndroidManifest.xml)
- Change `android:icon` from `@mipmap/nmrdlogo_icon` to `@mipmap/ic_launcher`.
- Change `android:roundIcon` from `@mipmap/nmrdlogo_icon_round` to `@mipmap/ic_launcher_round`.

### Icon Resource Updates

#### [MODIFY] [ic_launcher.xml](file:///Users/thebass/Documents/BigMisc/projnumbrd/numberd/android-wrapper/app/src/main/res/mipmap-anydpi-v26/ic_launcher.xml)
- Update to use `@drawable/ic_numberd_logo` as the foreground for a high-quality vector "N" logo.
- Ensure `@color/ic_launcher_background` is used for the background.

#### [MODIFY] [ic_launcher_round.xml](file:///Users/thebass/Documents/BigMisc/projnumbrd/numberd/android-wrapper/app/src/main/res/mipmap-anydpi-v26/ic_launcher_round.xml)
- Update to use `@drawable/ic_numberd_logo` as the foreground.

## Verification Plan

### Automated Tests
- Run `gradle :app:assembleDebug` to verify resources are valid.

### Manual Verification
- Deploy to device/emulator.
- Check if the "N" logo appears correctly on the home screen and in the app drawer.
- Verify the splash screen still looks correct.
