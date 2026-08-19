import { describe, expect, it } from "vitest";
import { clampRoutineMonth, isWithinTwoYearRetention, planningIsActive } from "./planningLifecycle";

describe("planning lifecycle helpers", () => {
  const reference = new Date(2026, 7, 19, 12);

  it("keeps legacy records active until explicitly completed", () => {
    expect(planningIsActive({})).toBe(true);
    expect(planningIsActive({ status: "completed" })).toBe(false);
  });

  it("retains completed records for two years", () => {
    expect(isWithinTwoYearRetention("2024-08-19T10:00:00.000Z", reference)).toBe(true);
    expect(isWithinTwoYearRetention("2024-08-18T10:00:00.000Z", reference)).toBe(false);
  });

  it("keeps routine calendar browsing inside the last twelve months", () => {
    expect(clampRoutineMonth(new Date(2025, 0, 1), reference)).toEqual(new Date(2025, 8, 1));
    expect(clampRoutineMonth(new Date(2027, 0, 1), reference)).toEqual(new Date(2026, 7, 1));
  });
});
