import { importPKCS8, SignJWT } from "jose";
import { describe, expect, it } from "vitest";

type FirebaseServiceAccount = {
  client_email: string;
  private_key: string;
  token_uri?: string;
};

describe("Firebase service account", () => {
  it("obtains a short-lived Google OAuth token for scheduled FCM delivery", async () => {
    const rawCredential = process.env.FIREBASE_SERVICE_ACCOUNT_JSON;
    expect(rawCredential).toBeTruthy();

    const credential = JSON.parse(rawCredential!) as FirebaseServiceAccount;
    expect(credential.client_email).toContain("@");
    expect(credential.private_key).toContain("BEGIN PRIVATE KEY");

    const tokenUri = credential.token_uri ?? "https://oauth2.googleapis.com/token";
    const privateKey = await importPKCS8(credential.private_key, "RS256");
    const assertion = await new SignJWT({ scope: "https://www.googleapis.com/auth/firebase.messaging" })
      .setProtectedHeader({ alg: "RS256", typ: "JWT" })
      .setIssuer(credential.client_email)
      .setSubject(credential.client_email)
      .setAudience(tokenUri)
      .setIssuedAt()
      .setExpirationTime("5m")
      .sign(privateKey);

    const response = await fetch(tokenUri, {
      method: "POST",
      headers: { "Content-Type": "application/x-www-form-urlencoded" },
      body: new URLSearchParams({
        grant_type: "urn:ietf:params:oauth:grant-type:jwt-bearer",
        assertion,
      }),
    });

    expect(response.ok).toBe(true);
    const payload = await response.json() as { access_token?: string };
    expect(payload.access_token).toBeTruthy();
  }, 20_000);
});
