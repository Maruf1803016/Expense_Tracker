import { describe, expect, it } from "vitest";
import { dashboardMonthLabel } from "./dashboardDate";

describe("dashboardMonthLabel", () => {
  it("uses the active calendar month rather than a fixed design-time month", () => {
    expect(dashboardMonthLabel(new Date(2026, 0, 4))).toBe("January");
    expect(dashboardMonthLabel(new Date(2026, 7, 19))).toBe("August");
  });
});
