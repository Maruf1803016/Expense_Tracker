import { describe, expect, it } from "vitest";
import { stepLedgerTimeWheel } from "./timeWheel";

describe("stepLedgerTimeWheel", () => {
  it("wraps the 24-hour hour wheel without changing the selected minute", () => {
    expect(stepLedgerTimeWheel("23:17", "24h", "hour", 1)).toBe("00:17");
    expect(stepLedgerTimeWheel("00:17", "24h", "hour", -1)).toBe("23:17");
  });

  it("wraps minutes without changing the selected hour or period", () => {
    expect(stepLedgerTimeWheel("14:59", "24h", "minute", 1)).toBe("14:00");
    expect(stepLedgerTimeWheel("11:00", "12h", "minute", -1)).toBe("11:59");
  });

  it("keeps period explicit in the 12-hour wheel", () => {
    expect(stepLedgerTimeWheel("11:15", "12h", "hour", 1)).toBe("00:15");
    expect(stepLedgerTimeWheel("11:15", "12h", "period", 1)).toBe("23:15");
  });
});
