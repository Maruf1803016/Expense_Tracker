import { describe, expect, it } from "vitest";
import { formatRoutineTimeRange, isRoutineTimeRangeValid } from "./routineTime";

describe("routine work times", () => {
  it("accepts a check-out time after check-in and rejects invalid ranges", () => {
    expect(isRoutineTimeRangeValid("09:00", "17:30")).toBe(true);
    expect(isRoutineTimeRangeValid("17:30", "09:00")).toBe(false);
    expect(isRoutineTimeRangeValid("09:00", "09:00")).toBe(false);
    expect(isRoutineTimeRangeValid("09:99", "17:30")).toBe(false);
  });

  it("formats saved work times in the selected clock format", () => {
    expect(formatRoutineTimeRange("09:00", "17:30", "12h")).toBe("9:00 AM – 5:30 PM");
    expect(formatRoutineTimeRange("09:00", "17:30", "24h")).toBe("09:00 – 17:30");
    expect(formatRoutineTimeRange(undefined, "17:30", "12h")).toBe("Times not recorded");
  });
});
