import { readFileSync } from "node:fs";
import path from "node:path";
import { describe, expect, it } from "vitest";

const projectRoot = path.resolve(import.meta.dirname, "../../..");

describe("Android direct-test release configuration", () => {
  it("uses the confirmed Expense Ledger identity and Vite production assets", () => {
    const config = readFileSync(path.join(projectRoot, "capacitor.config.ts"), "utf8");

    expect(config).toContain("appId: 'com.maruf.expenseledger'");
    expect(config).toContain("appName: 'Expense Ledger'");
    expect(config).toContain("webDir: 'dist/public'");

    const androidBuild = readFileSync(path.join(projectRoot, "android/app/build.gradle"), "utf8");
    expect(androidBuild).toContain("versionCode 3");
    expect(androidBuild).toContain('versionName "1.0.2"');
  });

  it("provides repeatable build and sync commands for a direct APK", () => {
    const packageJson = readFileSync(path.join(projectRoot, "package.json"), "utf8");

    expect(packageJson).toContain('"android:sync"');
    expect(packageJson).toContain('"android:apk:debug"');
  });

  it("includes the Capacitor native notification bridge without replacing browser push", () => {
    const packageJson = readFileSync(path.join(projectRoot, "package.json"), "utf8");
    const firebase = readFileSync(path.join(projectRoot, "client/src/lib/firebase.ts"), "utf8");

    expect(packageJson).toContain('"@capacitor/push-notifications"');
    expect(firebase).toContain("isNativeAndroidShell");
    expect(firebase).toContain("enableNativeAndroidReminderPush");
    expect(firebase).toContain("navigator.serviceWorker.register");
  });

  it("includes a native, short-lived Android Drive authorization bridge while retaining the browser flow", () => {
    const gradle = readFileSync(path.join(projectRoot, "android/app/build.gradle"), "utf8");
    const mainActivity = readFileSync(path.join(projectRoot, "android/app/src/main/java/com/maruf/expenseledger/MainActivity.java"), "utf8");
    const nativePlugin = readFileSync(path.join(projectRoot, "android/app/src/main/java/com/maruf/expenseledger/GoogleDriveAuthorizationPlugin.java"), "utf8");
    const nativeActivity = readFileSync(path.join(projectRoot, "android/app/src/main/java/com/maruf/expenseledger/GoogleDriveAuthorizationActivity.java"), "utf8");
    const driveBackup = readFileSync(path.join(projectRoot, "client/src/lib/googleDriveBackup.ts"), "utf8");

    expect(gradle).toContain('com.google.android.gms:play-services-auth:21.6.0');
    expect(mainActivity).toContain("registerPlugin(GoogleDriveAuthorizationPlugin.class)");
    expect(mainActivity.indexOf("registerPlugin(GoogleDriveAuthorizationPlugin.class)")).toBeLessThan(mainActivity.indexOf("super.onCreate(savedInstanceState)"));
    expect(nativePlugin).toContain('@CapacitorPlugin(name = "GoogleDriveAuth")');
    expect(nativeActivity).toContain("https://www.googleapis.com/auth/drive.file");
    expect(nativeActivity).toContain("getAccessToken()");
    expect(driveBackup).toContain("isNativeAndroidDriveBackup");
    expect(driveBackup).toContain("authorizeNativeAndroidDriveBackup");
    expect(driveBackup).toContain("NATIVE_GOOGLE_DRIVE_AUTHORIZATION_TIMEOUT_MS");
    expect(driveBackup).toContain("resolveNativeGoogleDriveAccessToken");
    expect(driveBackup).toContain("authorizeBrowserDriveBackup");
  });
});
