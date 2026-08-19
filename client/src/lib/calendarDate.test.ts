import { describe, expect, it } from "vitest";
import { calendarYearChoices, normaliseCalendarDate } from "./calendarDate";

describe("Ink & Ledger calendar dates", () => {
  it("keeps an ISO date unchanged and upgrades older goal labels to a calendar value", () => {
    const fallback = new Date("2026-08-19T12:00:00");

    expect(normaliseCalendarDate("2031-06-14", fallback)).toBe("2031-06-14");
    expect(normaliseCalendarDate("By Dec 2028", fallback)).toBe("2028-12-01");
  });

  it("returns a usable, centred year range for long-term savings goals and trip plans", () => {
    const years = calendarYearChoices(2030);

    expect(years).toHaveLength(12);
    expect(years).toContain(2030);
    expect(years[0]).toBe(2024);
    expect(years.at(-1)).toBe(2035);
  });
});
