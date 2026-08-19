import { describe, expect, it } from "vitest";
import { GOOGLE_DRIVE_FILE_SCOPE, GOOGLE_DRIVE_MULTIPART_UPLOAD_URL, createLedgerBackupFile, getGoogleDriveClientId } from "./googleDriveBackup";

describe("Google Drive ledger backup", () => {
  it("accepts only the public Google Web client ID shape", () => {
    expect(getGoogleDriveClientId("657477735157-74m42hh9s280ner0mad72hthi60a1bs7.apps.googleusercontent.com")).toBe("657477735157-74m42hh9s280ner0mad72hthi60a1bs7.apps.googleusercontent.com");
    expect(getGoogleDriveClientId("not-a-google-client")).toBeNull();
    expect(getGoogleDriveClientId(undefined)).toBeNull();
  });

  it("builds a dated private JSON ledger backup without requiring a download", async () => {
    const backup = createLedgerBackupFile({
      ownerUid: "ledger-owner",
      exportedAt: "2026-08-19T10:00:00.000Z",
      data: { transactions: [{ id: "txn-1", amount: 42 }], userPrefs: { timeFormat: "12h" } },
    });

    expect(backup.filename).toBe("expense-ledger-backup-2026-08-19.json");
    expect(backup.file.type).toBe("application/json");
    await expect(backup.file.text()).resolves.toContain('"ownerUid": "ledger-owner"');
    await expect(backup.file.text()).resolves.toContain('"id": "txn-1"');
  });

  it("requests the narrow file-creation scope and sends the backup through Drive’s multipart upload endpoint", () => {
    expect(GOOGLE_DRIVE_FILE_SCOPE).toBe("https://www.googleapis.com/auth/drive.file");
    expect(GOOGLE_DRIVE_MULTIPART_UPLOAD_URL).toContain("uploadType=multipart");
    expect(GOOGLE_DRIVE_MULTIPART_UPLOAD_URL).toContain("fields=id,name,webViewLink");
  });
});
