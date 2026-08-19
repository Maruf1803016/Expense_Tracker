import { describe, expect, it } from "vitest";
import { expectedRoutineDaysInMonth, isExpectedRoutineDay, routineCalendarDays } from "./routineCalendar";

describe("Work & Routine calendar", () => {
  it("uses a Monday-first working week and honours the selected number of expected days", () => {
    expect(isExpectedRoutineDay(new Date(2026, 7, 3), 5)).toBe(true); // Monday
    expect(isExpectedRoutineDay(new Date(2026, 7, 8), 5)).toBe(false); // Saturday
    expect(isExpectedRoutineDay(new Date(2026, 7, 8), 6)).toBe(true);
  });

  it("counts expected workdays only inside the selected month", () => {
    expect(expectedRoutineDaysInMonth(2026, 7, 5)).toHaveLength(21);
    expect(expectedRoutineDaysInMonth(2026, 7, 7)).toHaveLength(31);
  });

  it("creates a six-week grid with visible expected-day context", () => {
    const days = routineCalendarDays(2026, 7, 3);
    expect(days).toHaveLength(42);
    expect(days.filter((day) => day.inCurrentMonth && day.expected)).toHaveLength(13);
  });
});

