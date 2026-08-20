export const GOOGLE_DRIVE_FILE_SCOPE = "https://www.googleapis.com/auth/drive.file";
import { Capacitor, registerPlugin } from "@capacitor/core";

export const GOOGLE_IDENTITY_SERVICES_URL = "https://accounts.google.com/gsi/client";
export const GOOGLE_DRIVE_MULTIPART_UPLOAD_URL = "https://www.googleapis.com/upload/drive/v3/files?uploadType=multipart&fields=id,name,webViewLink";

type GoogleTokenResponse = {
  access_token?: string;
  error?: string;
  error_description?: string;
};

type GoogleTokenClient = {
  requestAccessToken: (config?: { prompt?: string }) => void;
};

type GoogleOAuth2 = {
  initTokenClient: (config: {
    client_id: string;
    scope: string;
    callback: (response: GoogleTokenResponse) => void;
    error_callback?: (error: { type?: string; message?: string }) => void;
  }) => GoogleTokenClient;
};

type GoogleIdentityWindow = Window & {
  google?: {
    accounts?: {
      oauth2?: GoogleOAuth2;
    };
  };
};

type NativeGoogleDriveAuthorizationPlugin = {
  authorize: () => Promise<{ accessToken?: string }>;
};

const NativeGoogleDriveAuthorization = registerPlugin<NativeGoogleDriveAuthorizationPlugin>("GoogleDriveAuth");
export const NATIVE_GOOGLE_DRIVE_AUTHORIZATION_TIMEOUT_MS = 15_000;
export const BROWSER_GOOGLE_IDENTITY_LOAD_TIMEOUT_MS = 12_000;
export const BROWSER_GOOGLE_DRIVE_AUTHORIZATION_TIMEOUT_MS = 20_000;

function getGoogleOAuth2(): GoogleOAuth2 | undefined {
  return (window as GoogleIdentityWindow).google?.accounts?.oauth2;
}

export function isNativeAndroidDriveBackup() {
  return Capacitor.isNativePlatform() && Capacitor.getPlatform() === "android";
}

export type LedgerBackupFile = {
  filename: string;
  file: Blob;
};

export type GoogleDriveBackupResult = {
  id: string;
  name: string;
  webViewLink?: string;
};

export function getGoogleDriveClientId(clientId: string | undefined): string | null {
  const normalized = clientId?.trim();
  return normalized && /^[0-9]+-[a-z0-9]+\.apps\.googleusercontent\.com$/i.test(normalized) ? normalized : null;
}

export function isGoogleDriveBackupConfigured(clientId: string | undefined): boolean {
  return isNativeAndroidDriveBackup() || Boolean(getGoogleDriveClientId(clientId));
}

export function createLedgerBackupFile({ ownerUid, data, exportedAt = new Date().toISOString() }: {
  ownerUid: string;
  data: Record<string, unknown>;
  exportedAt?: string;
}): LedgerBackupFile {
  const backup = {
    format: "expense-ledger-backup",
    version: 1,
    exportedAt,
    ownerUid,
    data,
  };
  const filename = `expense-ledger-backup-${exportedAt.slice(0, 10)}.json`;
  return {
    filename,
    file: new Blob([JSON.stringify(backup, null, 2)], { type: "application/json" }),
  };
}

export async function preloadGoogleIdentityServices(): Promise<void> {
  if (isNativeAndroidDriveBackup()) return;
  if (typeof window === "undefined" || typeof document === "undefined") {
    throw new Error("Google Drive backup is available only in a browser.");
  }
  if (getGoogleOAuth2()) return;

  const selector = "script[data-expense-ledger-google-identity]";
  const existing = document.querySelector<HTMLScriptElement>(selector);
  const script = existing ?? document.createElement("script");
  if (!existing) {
    script.src = GOOGLE_IDENTITY_SERVICES_URL;
    script.async = true;
    script.defer = true;
    script.dataset.expenseLedgerGoogleIdentity = "true";
    document.head.appendChild(script);
  }

  await new Promise<void>((resolve, reject) => {
    let settled = false;
    let timeoutId: ReturnType<typeof setTimeout> | undefined;
    const finish = (error?: Error) => {
      if (settled) return;
      settled = true;
      if (timeoutId !== undefined) clearTimeout(timeoutId);
      if (error) reject(error);
      else resolve();
    };
    const settle = () => getGoogleOAuth2()
      ? finish()
      : finish(new Error("Google’s authorization service did not finish loading. Please try again."));
    script.addEventListener("load", settle, { once: true });
    script.addEventListener("error", () => finish(new Error("Google’s authorization service could not be loaded. Please check your connection and try again.")), { once: true });
    timeoutId = setTimeout(() => finish(new Error("Google’s authorization service did not become ready. Please check the browser’s pop-up/privacy settings and try again.")), BROWSER_GOOGLE_IDENTITY_LOAD_TIMEOUT_MS);
    if (getGoogleOAuth2()) finish();
  });
}

function uploadLedgerBackupToDrive(accessToken: string, backup: LedgerBackupFile): Promise<GoogleDriveBackupResult> {
  const boundary = `expense-ledger-${crypto.randomUUID()}`;
  const metadata = {
    name: backup.filename,
    mimeType: "application/json",
    description: "Private Expense Ledger backup created by the account holder.",
  };
  const body = new Blob([
    `--${boundary}\r\n`,
    "Content-Type: application/json; charset=UTF-8\r\n\r\n",
    JSON.stringify(metadata),
    `\r\n--${boundary}\r\n`,
    "Content-Type: application/json\r\n\r\n",
    backup.file,
    `\r\n--${boundary}--`,
  ]);

  return fetch(GOOGLE_DRIVE_MULTIPART_UPLOAD_URL, {
    method: "POST",
    headers: {
      Authorization: `Bearer ${accessToken}`,
      "Content-Type": `multipart/related; boundary=${boundary}`,
    },
    body,
  }).then(async (response) => {
    if (!response.ok) {
      throw new Error("Google Drive could not save the backup. Please try again.");
    }
    return response.json() as Promise<GoogleDriveBackupResult>;
  });
}

export async function resolveNativeGoogleDriveAccessToken(
  authorize: () => Promise<{ accessToken?: string }>,
  timeoutMs = NATIVE_GOOGLE_DRIVE_AUTHORIZATION_TIMEOUT_MS,
): Promise<string> {
  let timeoutId: ReturnType<typeof setTimeout> | undefined;

  try {
    const response = await new Promise<{ accessToken?: string }>((resolve, reject) => {
      timeoutId = setTimeout(() => {
        reject(new Error("Google Drive did not open its account picker. Please close this screen, reopen the app, and try again."));
      }, timeoutMs);

      void authorize().then(resolve, reject);
    });
    const accessToken = response.accessToken?.trim();
    if (!accessToken) {
      throw new Error("Android Google Drive authorization did not return a usable access token.");
    }
    return accessToken;
  } catch (error) {
    if (error instanceof Error) throw error;
    throw new Error("Android Google Drive authorization could not be completed. Please try again.");
  } finally {
    if (timeoutId !== undefined) clearTimeout(timeoutId);
  }
}

async function authorizeNativeAndroidDriveBackup(): Promise<string> {
  return resolveNativeGoogleDriveAccessToken(() => NativeGoogleDriveAuthorization.authorize());
}

function browserAuthorizationError(error: unknown): Error {
  if (error instanceof Error) return error;
  if (typeof error === "object" && error !== null && "message" in error && typeof error.message === "string") {
    return new Error(error.message);
  }
  return new Error("Google Drive connection was cancelled or could not be opened.");
}

export function resolveBrowserDriveAccessToken(
  requestAuthorization: (
    onResponse: (response: GoogleTokenResponse) => void,
    onError: (error: unknown) => void,
  ) => void,
  timeoutMs = BROWSER_GOOGLE_DRIVE_AUTHORIZATION_TIMEOUT_MS,
): Promise<string> {
  let timeoutId: ReturnType<typeof setTimeout> | undefined;

  return new Promise<string>((resolve, reject) => {
    let settled = false;
    const finish = (result: { token?: string; error?: Error }) => {
      if (settled) return;
      settled = true;
      if (timeoutId !== undefined) clearTimeout(timeoutId);
      if (result.error) reject(result.error);
      else resolve(result.token!);
    };
    const onResponse = (response: GoogleTokenResponse) => {
      const accessToken = response.access_token?.trim();
      if (!accessToken) {
        finish({ error: new Error(response.error_description || response.error || "Google Drive permission was not granted.") });
        return;
      }
      finish({ token: accessToken });
    };
    const onError = (error: unknown) => finish({ error: browserAuthorizationError(error) });

    timeoutId = setTimeout(() => {
      finish({ error: new Error("Google Drive did not return from the account picker. Please close any blocked pop-up, then try again.") });
    }, timeoutMs);

    try {
      requestAuthorization(onResponse, onError);
    } catch (error) {
      onError(error);
    }
  });
}

async function authorizeBrowserDriveBackup(clientId: string | undefined): Promise<string> {
  const usableClientId = getGoogleDriveClientId(clientId);
  if (!usableClientId) {
    throw new Error("Google Drive backup is not configured yet. Please try again after the app is updated.");
  }
  await preloadGoogleIdentityServices();
  const oauth2 = getGoogleOAuth2();
  if (!oauth2) {
    throw new Error("Google’s authorization service is not ready. Please try again.");
  }

  return resolveBrowserDriveAccessToken((onResponse, onError) => {
    const tokenClient = oauth2.initTokenClient({
      client_id: usableClientId,
      scope: GOOGLE_DRIVE_FILE_SCOPE,
      callback: onResponse,
      error_callback: onError,
    });
    tokenClient.requestAccessToken({ prompt: "select_account" });
  });
}

export async function authorizeAndUploadLedgerBackup({ clientId, backup }: { clientId: string | undefined; backup: LedgerBackupFile }): Promise<GoogleDriveBackupResult> {
  const accessToken = isNativeAndroidDriveBackup()
    ? await authorizeNativeAndroidDriveBackup()
    : await authorizeBrowserDriveBackup(clientId);
  return uploadLedgerBackupToDrive(accessToken, backup);
}
