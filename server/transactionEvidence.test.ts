import { describe, expect, it } from "vitest";
import { isOwnedEvidenceKey, parseEvidencePayload } from "./transactionEvidence";

describe("transaction evidence validation", () => {
  it("accepts an image or PDF data URL and returns its original bytes", () => {
    const bytes = parseEvidencePayload("data:image/png;base64,aGVsbG8=", "image/png");

    expect(bytes.toString("utf8")).toBe("hello");
  });

  it("rejects a file type outside the supported evidence set", () => {
    expect(() => parseEvidencePayload("data:text/plain;base64,aGVsbG8=", "text/plain")).toThrow("Choose a JPG, PNG, WEBP image, or PDF document.");
  });

  it("rejects empty attachment content", () => {
    expect(() => parseEvidencePayload("data:application/pdf;base64,", "application/pdf")).toThrow("Each attachment must be smaller than 8 MB.");
  });

  it("allows only evidence keys that are scoped to the authenticated Firebase user", () => {
    expect(isOwnedEvidenceKey("transaction-evidence/user-123/receipt.pdf", "user-123")).toBe(true);
    expect(isOwnedEvidenceKey("transaction-evidence/other-user/receipt.pdf", "user-123")).toBe(false);
    expect(isOwnedEvidenceKey("transaction-evidence/user-123/../other-user/receipt.pdf", "user-123")).toBe(false);
  });
});
