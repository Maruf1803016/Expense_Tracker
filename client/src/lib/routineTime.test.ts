import { describe, expect, it } from "vitest";
import { calculateRoutineShiftMinutes, formatRoutineShiftDuration, formatRoutineShiftTimeline, formatRoutineTimeRange, isRoutineShiftOvernight, isRoutineTimeRangeValid } from "./routineTime";

describe("routine work times", () => {
  it("accepts normal and overnight ranges while rejecting a zero-length same-day shift", () => {
    expect(isRoutineTimeRangeValid("09:00", "17:30")).toBe(true);
    expect(isRoutineTimeRangeValid("17:30", "09:00")).toBe(true);
    expect(isRoutineTimeRangeValid("09:00", "09:00")).toBe(false);
    expect(isRoutineTimeRangeValid("09:00", "09:00", true)).toBe(true);
    expect(isRoutineTimeRangeValid("09:99", "17:30")).toBe(false);
  });

  it("detects next-day shifts and calculates their duration without storing it", () => {
    expect(isRoutineShiftOvernight("14:00", "08:00")).toBe(true);
    expect(isRoutineShiftOvernight("09:00", "17:00")).toBe(false);
    expect(calculateRoutineShiftMinutes("14:00", "08:00")).toBe(18 * 60);
    expect(calculateRoutineShiftMinutes("12:00", "08:00")).toBe(20 * 60);
    expect(formatRoutineShiftDuration(10 * 60)).toBe("10h 00m");
  });

  it("formats saved work times and the date-aware timeline in the selected clock format", () => {
    expect(formatRoutineTimeRange("09:00", "17:30", "12h")).toBe("9:00 AM – 5:30 PM");
    expect(formatRoutineTimeRange("09:00", "17:30", "24h")).toBe("09:00 – 17:30");
    expect(formatRoutineTimeRange(undefined, "17:30", "12h")).toBe("Times not recorded");
    expect(formatRoutineShiftTimeline("2026-08-18", "14:00", "08:00", "12h")).toBe("Tue · 2:00 PM → Wed · 8:00 AM");
    expect(formatRoutineShiftTimeline("2026-08-18", undefined, undefined, "12h")).toBe("Attendance recorded — times optional");
  });
});
