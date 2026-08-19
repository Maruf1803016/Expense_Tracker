import { describe, expect, it } from "vitest";
import { ledgerErrorMessage } from "./ledgerError";

describe("ledgerErrorMessage", () => {
  it("gives a safe, actionable recovery path for a Firestore permission failure", () => {
    const message = ledgerErrorMessage({ code: "permission-denied" }, "access");

    expect(message).toContain("not allowed to open your cloud ledger");
    expect(message).toContain("Sign out");
    expect(message).toContain("owner-only Firestore rules");
    expect(message).not.toContain("uid");
  });

  it("distinguishes expired sign-in sessions from temporary cloud outages", () => {
    expect(ledgerErrorMessage({ code: "unauthenticated" }, "save")).toContain("Sign in again");
    expect(ledgerErrorMessage({ code: "unavailable" }, "save")).toContain("temporarily unavailable");
  });

  it("preserves a clear generic fallback for unknown failures", () => {
    expect(ledgerErrorMessage(new Error("unexpected"), "remove")).toContain("could not be removed");
  });
});
