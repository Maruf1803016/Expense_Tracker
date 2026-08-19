import { describe, expect, it } from "vitest";
import { formatReminderTime, reminderTimeFromParts, reminderTimeParts } from "./reminderTime";

describe("reminder time selection", () => {
  it("converts saved 24-hour times into clear 12-hour picker parts", () => {
    expect(reminderTimeParts("21:30")).toEqual({ hour: 9, minute: "30", meridiem: "PM" });
    expect(reminderTimeParts("00:15")).toEqual({ hour: 12, minute: "15", meridiem: "AM" });
  });

  it("creates a stable 24-hour value from the picker selections", () => {
    expect(reminderTimeFromParts(9, "45", "PM")).toBe("21:45");
    expect(reminderTimeFromParts(12, "00", "AM")).toBe("00:00");
  });

  it("formats a saved time for the confirmation summary and falls back safely", () => {
    expect(formatReminderTime("17:00")).toBe("5:00 PM");
    expect(formatReminderTime("not-a-time")).toBe("10:00 PM");
  });
});
