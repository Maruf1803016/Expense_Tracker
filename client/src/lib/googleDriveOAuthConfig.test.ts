import { describe, expect, it } from "vitest";

const clientId = process.env.VITE_GOOGLE_DRIVE_CLIENT_ID;

describe("Google Drive OAuth client configuration", () => {
  it("contains the configured public Web client ID and Google accepts its authorization request", async () => {
    expect(clientId).toMatch(/^[0-9]+-[a-z0-9]+\.apps\.googleusercontent\.com$/);

    const authorizationUrl = new URL("https://accounts.google.com/o/oauth2/v2/auth");
    authorizationUrl.searchParams.set("client_id", clientId!);
    authorizationUrl.searchParams.set("redirect_uri", "postmessage");
    authorizationUrl.searchParams.set("response_type", "token");
    authorizationUrl.searchParams.set("scope", "https://www.googleapis.com/auth/drive.file");
    authorizationUrl.searchParams.set("prompt", "none");

    const response = await fetch(authorizationUrl, { redirect: "manual" });
    expect([200, 302, 303]).toContain(response.status);
  }, 15_000);
});
