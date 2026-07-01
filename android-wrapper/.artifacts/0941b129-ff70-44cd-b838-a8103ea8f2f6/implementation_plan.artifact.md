# Implementation Plan - UI/UX Improvements and Bug Fixes

Address mobile navigation overlap, YouTube fullscreen, app branding, and mobile responsiveness in the NumberD Android wrapper.

## Proposed Changes

### Android Wrapper Updates

#### [MODIFY] [MainActivity.kt](file:///Users/thebass/Documents/BigMisc/projnumbrd/numberd/android-wrapper/app/src/main/java/com/numberd/app/MainActivity.kt)
- Update `NumberDAppWrapper` to handle status bar insets using `Modifier.statusBarsPadding()`.
- Implement a custom `WebChromeClient` to support YouTube fullscreen by overriding `onShowCustomView` and `onHideCustomView`.
- Refine the `OfflineFallback` UI to match the new "premium" branding.
- Enable `setSupportMultipleWindows` and other WebView settings for better mobile experience.

#### [NEW] [ic_numberd_logo.xml](file:///Users/thebass/Documents/BigMisc/projnumbrd/numberd/android-wrapper/app/src/main/res/drawable/ic_numberd_logo.xml)
- Create a modern, bold "N" logo as a Vector Drawable with purple gradients.

#### [MODIFY] [nmrdlogo_icon.xml](file:///Users/thebass/Documents/BigMisc/projnumbrd/numberd/android-wrapper/app/src/main/res/mipmap-anydpi-v26/nmrdlogo_icon.xml)
- Update to use the new `ic_numberd_logo.xml` as the foreground.

#### [MODIFY] [nmrdlogo_icon_round.xml](file:///Users/thebass/Documents/BigMisc/projnumbrd/numberd/android-wrapper/app/src/main/res/mipmap-anydpi-v26/nmrdlogo_icon_round.xml)
- Update to use the new `ic_numberd_logo.xml` as the foreground.

## Verification Plan

### Automated Tests
- Build the app to ensure no compilation errors.
- Run `gradle :app:assembleDebug`.

### Manual Verification
- Deploy to an Android emulator/device.
- Verify the hamburger menu is below the status bar.
- Verify YouTube videos can enter fullscreen.
- Check the new app icon on the home screen.
- Verify the offline screen looks professional.
