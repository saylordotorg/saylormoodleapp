# Saylor University app

This is Saylor University's branded build of the Moodle app. It opens on a choice between
`https://learn.saylor.org` (Free Courses) and `https://degrees.saylor.org` (Degree Programs).

## Store identity

This app is meant to replace the existing "Saylor Academy" listing in both stores, so it uses
that listing's ID on both platforms: `com.moodle.saylor` (App Store ID `1481507148`). Updating
the listing needs the same developer accounts and signing keys that published it, and a version
code higher than the one currently in the stores.

## Where the branding lives

| What | File |
| --- | --- |
| App name, app ID, the two sites, URL scheme, privacy link | `moodle.config.json`, `config.xml`, `package.json` (`URL_SCHEME`) |
| Colours (navy `#173140`, blue `#469dcc`, orange `#f87c12`) | `src/theme/globals.custom.scss`, `src/theme/theme.custom.scss` |
| Logo sources and the image generator | `resources/saylor/` |
| Opening-screen wording | `src/core/features/login/lang.json` (`selectsite`, `connecttomoodle`) |

To regenerate every icon, splash screen and logo after changing an SVG in `resources/saylor/`:

```bash
./resources/saylor/generate.sh
```

## Building

Requirements: Node 24 (`>=24.16 <25`), Xcode with CocoaPods for iOS, and JDK 21, Gradle and the
Android SDK (platform 37, build-tools 36) for Android.

```bash
npm ci
```

Build the web bundle through Cordova, once **per platform**. A plain `npm run build:prod` leaves
out `cordova.js` and the app hangs on the splash screen; a bundle built for one platform also
hangs on the other.

iOS simulator:

```bash
NODE_ENV=production npx ionic cordova prepare ios --prod
npx cordova compile ios --emulator --debug --buildFlag="IPHONEOS_DEPLOYMENT_TARGET=15.0"
```

Android debug APK (`platforms/android/app/build/outputs/apk/debug/app-debug.apk`):

```bash
NODE_ENV=production npx ionic cordova prepare android --prod
npx cordova compile android --debug
```

## Things to know

- If the app ID in `config.xml` ever changes, remove and recreate the Android platform
  (`npx cordova platform rm android --nosave`, then prepare again). Cordova cannot rename an
  existing Android project and fails with "No Java files found that extend CordovaActivity".
- `IPHONEOS_DEPLOYMENT_TARGET=15.0` is needed because the Firebase pods still declare iOS 9-11,
  which Xcode 27 rejects.
- `patches/@moodlehq+cordova-plugin-advanced-http+*.patch` removes an import Xcode 27 treats as
  private. `scripts/cordova-hooks/after_prepare_ios.sh` keeps the Swift header name the push
  plugin expects now that the app is no longer called "Moodle".
- **Push notifications are not set up.** `google-services.json` and `GoogleService-Info.plist`
  are still Moodle's. The Android build fails with "No matching client found for package name"
  until `google-services.json` comes from a Firebase project that includes `com.moodle.saylor`.
