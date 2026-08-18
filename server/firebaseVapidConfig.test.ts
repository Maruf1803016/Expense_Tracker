import { describe, expect, it } from "vitest";

describe("Firebase Web Push configuration", () => {
  it("provides a URL-safe public VAPID key for browser reminder registration", () => {
    const vapidKey = process.env.VITE_FIREBASE_VAPID_KEY;

    expect(vapidKey).toBeTruthy();
    expect(vapidKey).toMatch(/^[A-Za-z0-9_-]{80,}$/);
  });
});
