# Android Google Drive Authorization Research

## Post-consent result contract

Google’s Android authorization guidance describes requesting Drive scope through `AuthorizationClient.authorize()`. If the returned `AuthorizationResult` has a resolution, the app launches its `PendingIntent`; when that UI returns, the result `Intent` must be parsed through `getAuthorizationResultFromIntent()` before reading the short-lived access token. This project uses the narrow `https://www.googleapis.com/auth/drive.file` scope so a consenting user grants access only to files created or opened through the app.

Source: [Google Identity Authorization for Android](https://developer.android.com/identity/authorization), accessed 2026-08-20.

## Capacitor bridge contract

Capacitor’s Android plugin API uses an `@ActivityCallback` method associated with `startActivityForResult(PluginCall, Intent, callbackName)`. The host activity must register the plugin before Capacitor’s bridge is created. The remaining issue is therefore the nested Google consent result return inside the helper activity, not Android OAuth client registration or initial Capacitor plugin visibility.

Source: [Capacitor Android plugin guide](https://capacitorjs.com/docs/plugins/android), accessed 2026-08-20.
