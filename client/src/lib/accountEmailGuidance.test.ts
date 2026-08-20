import { describe, expect, it } from "vitest";
import { accountEmailGuidance } from "./accountEmailGuidance";

describe("accountEmailGuidance", () => {
  it("explains why the free Firebase email link can look long without suggesting an unsafe shortener", () => {
    expect(accountEmailGuidance.preflight).toContain("Firebase Authentication");
    expect(accountEmailGuidance.preflight).toContain("one-time account code");
    expect(accountEmailGuidance.preflight).toContain("only if you requested it");
  });

  it("keeps verification and recovery notices specific to the requested account email", () => {
    expect(accountEmailGuidance.verificationRequested("owner@example.com")).toContain("owner@example.com");
    expect(accountEmailGuidance.verificationRequested("owner@example.com")).toContain("Refresh status");
    expect(accountEmailGuidance.passwordResetRequested("owner@example.com")).toContain("Inbox, Spam, and Promotions");
    expect(accountEmailGuidance.passwordResetRequested("owner@example.com")).toContain("newest link");
  });
});
