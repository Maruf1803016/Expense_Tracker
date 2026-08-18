import { describe, expect, it } from "vitest";
import { dueNow, safeTimezone } from "./expenseReminders";

describe("expense reminder scheduling", () => {
  it("matches an enabled reminder at its exact configured local minute", () => {
    const result = dueNow({ enabled: true, time: "22:00", timezone: "UTC" }, new Date("2026-08-18T22:00:30.000Z"));

    expect(result).toMatchObject({ due: true, localDay: "2026-08-18", selectedTime: "22:00", timezone: "UTC" });
  });

  it("does not schedule disabled reminders or different local minutes", () => {
    expect(dueNow({ enabled: false, time: "22:00", timezone: "UTC" }, new Date("2026-08-18T22:00:00.000Z")).due).toBe(false);
    expect(dueNow({ enabled: true, time: "22:00", timezone: "UTC" }, new Date("2026-08-18T21:59:00.000Z")).due).toBe(false);
  });

  it("falls back safely when stored reminder inputs are malformed", () => {
    const result = dueNow({ enabled: true, time: "tomorrow", timezone: "Not/AZone" }, new Date("2026-08-18T22:00:00.000Z"));

    expect(safeTimezone("Not/AZone")).toBe("UTC");
    expect(result).toMatchObject({ due: true, selectedTime: "22:00", timezone: "UTC" });
  });
});
