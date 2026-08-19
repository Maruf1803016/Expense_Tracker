import { describe, expect, it } from "vitest";
import { expectedRoutineDaysInMonth, isExpectedRoutineDay, isFutureRoutineDate, routineCalendarDays } from "./routineCalendar";

describe("Work & Routine calendar", () => {
  it("uses a Monday-first working week and honours the selected number of expected days", () => {
    expect(isExpectedRoutineDay(new Date(2026, 7, 3), 5)).toBe(true); // Monday
    expect(isExpectedRoutineDay(new Date(2026, 7, 8), 5)).toBe(false); // Saturday
    expect(isExpectedRoutineDay(new Date(2026, 7, 8), 6)).toBe(true);
  });

  it("reorders the week and expected days when Sunday is chosen as the first day", () => {
    expect(isExpectedRoutineDay(new Date(2026, 7, 2), 5, 0)).toBe(true); // Sunday
    expect(isExpectedRoutineDay(new Date(2026, 7, 7), 5, 0)).toBe(false); // Friday
    expect(routineCalendarDays(2026, 7, 3, 0)[0].date).toBe("2026-07-26");
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

  it("keeps later calendar days unavailable until they arrive", () => {
    const today = new Date(2026, 7, 19, 12);
    expect(isFutureRoutineDate("2026-08-19", today)).toBe(false);
    expect(isFutureRoutineDate("2026-08-22", today)).toBe(true);
    expect(isFutureRoutineDate("2026-07-31", today)).toBe(false);
  });
});
