# Expense Ledger Android APK — Direct Test Release

The Android wrapper uses Capacitor with the fixed application ID **`com.maruf.expenseledger`** and copies the web production bundle from `dist/public`. The supported direct-test command is:

```bash
pnpm android:apk:debug
```

The resulting test APK is generated at:

```text
android/app/build/outputs/apk/debug/app-debug.apk
```

This debug package is automatically signed with Android's debug signing configuration and is appropriate for direct, limited friend testing. Testers must permit installation from the selected sharing/browser app on their phone. The final Google Play release must use a separately generated release signing key that is retained by the owner and never committed to source control.

## Before first Android test

The Android project must be registered in the existing Firebase project using package ID `com.maruf.expenseledger`. Download the resulting `google-services.json` only to `android/app/google-services.json`; do not commit it if it contains project-specific credentials outside the intended repository policy.

Google Drive backup needs an Android OAuth client registered with this same package ID and the signing SHA-1 fingerprint. The current browser OAuth client remains unchanged for the published web app. Native Drive sign-in should not rely on the browser-only Google Identity Services flow inside the Android WebView.

### Native reminders and Google Drive

The current reminder implementation uses the browser Service Worker and web Firebase Messaging APIs. A Capacitor APK needs the native `@capacitor/push-notifications` bridge, Firebase Android registration, and the downloaded `google-services.json` before it can receive native FCM reminders. The Android package ID must match this project exactly. Android 13+ also prompts the user for notification permission during the first native registration.

The debug APK is signed by Android's default debug key. Its observed SHA-1 fingerprint in this build environment is `6D:9F:6E:ED:CD:CC:FB:8D:BC:7F:64:81:A1:49:20:58:72:36:2B`; the final release key will have a different fingerprint and must be added separately to Firebase and the Android OAuth client before Play Store distribution.

For direct friend testing, first verify ledger login and Firestore data on-device. Enable native reminders only after the Firebase Android app is registered and configuration file is present. Enable native Google Drive backup only after an Android OAuth client exists and a native Google sign-in bridge has replaced the browser-only flow in the APK.

## Repeatable update workflow

After any frontend update, run `pnpm android:sync` before rebuilding the APK so the latest `dist/public` files are copied into the Android project. For device debugging, use `pnpm android:open` to open the native project in Android Studio.

## Reference implementation notes

Capacitor's documented workflow is to build the web bundle, synchronize it into the Android project with `cap sync`, and compile or test the native project afterward. The same documentation supports terminal-based Android builds as well as Android Studio. Capacitor treats the resulting Android project as a regular native application for later Google Play distribution.

- [Capacitor Workflow](https://capacitorjs.com/docs/basics/workflow)
- [Capacitor Android Play deployment](https://capacitorjs.com/docs/android/deploying-to-google-play)
- [Capacitor Firebase Cloud Messaging guide](https://capacitorjs.com/docs/guides/push-notifications-firebase)
- [Android command-line tools](https://developer.android.com/tools)
