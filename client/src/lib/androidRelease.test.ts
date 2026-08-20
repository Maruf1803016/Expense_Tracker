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
});
