export type RoutineDaysPerWeek = 3 | 4 | 5 | 6 | 7;
/** JavaScript weekday index: Sunday (0) through Saturday (6). */
export type RoutineWeekStartDay = 0 | 1 | 2 | 3 | 4 | 5 | 6;

export interface RoutineCalendarDay {
  date: string;
  dayOfMonth: number;
  inCurrentMonth: boolean;
  expected: boolean;
}

export function toRoutineDate(date: Date) {
  const year = date.getFullYear();
  const month = String(date.getMonth() + 1).padStart(2, "0");
  const day = String(date.getDate()).padStart(2, "0");
  return `${year}-${month}-${day}`;
}

export function isFutureRoutineDate(date: string, today = new Date()) {
  return date > toRoutineDate(today);
}

export function isExpectedRoutineDay(date: Date, daysPerWeek: RoutineDaysPerWeek, weekStartDay: RoutineWeekStartDay = 1) {
  const layoutDay = (date.getDay() - weekStartDay + 7) % 7;
  return layoutDay < daysPerWeek;
}

export function expectedRoutineDaysInMonth(year: number, monthIndex: number, daysPerWeek: RoutineDaysPerWeek, weekStartDay: RoutineWeekStartDay = 1) {
  const lastDay = new Date(year, monthIndex + 1, 0).getDate();
  return Array.from({ length: lastDay }, (_, index) => new Date(year, monthIndex, index + 1))
    .filter((date) => isExpectedRoutineDay(date, daysPerWeek, weekStartDay))
    .map(toRoutineDate);
}

export function routineCalendarDays(year: number, monthIndex: number, daysPerWeek: RoutineDaysPerWeek, weekStartDay: RoutineWeekStartDay = 1): RoutineCalendarDay[] {
  const firstOfMonth = new Date(year, monthIndex, 1);
  const gridOffset = (firstOfMonth.getDay() - weekStartDay + 7) % 7;
  const gridStart = new Date(year, monthIndex, 1 - gridOffset);

  return Array.from({ length: 42 }, (_, index) => {
    const date = new Date(gridStart.getFullYear(), gridStart.getMonth(), gridStart.getDate() + index);
    return {
      date: toRoutineDate(date),
      dayOfMonth: date.getDate(),
      inCurrentMonth: date.getMonth() === monthIndex,
      expected: isExpectedRoutineDay(date, daysPerWeek, weekStartDay),
    };
  });
}
