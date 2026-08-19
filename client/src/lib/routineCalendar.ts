export type RoutineDaysPerWeek = 3 | 4 | 5 | 6 | 7;

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

export function isExpectedRoutineDay(date: Date, daysPerWeek: RoutineDaysPerWeek) {
  const mondayFirstDay = (date.getDay() + 6) % 7;
  return mondayFirstDay < daysPerWeek;
}

export function expectedRoutineDaysInMonth(year: number, monthIndex: number, daysPerWeek: RoutineDaysPerWeek) {
  const lastDay = new Date(year, monthIndex + 1, 0).getDate();
  return Array.from({ length: lastDay }, (_, index) => new Date(year, monthIndex, index + 1))
    .filter((date) => isExpectedRoutineDay(date, daysPerWeek))
    .map(toRoutineDate);
}

export function routineCalendarDays(year: number, monthIndex: number, daysPerWeek: RoutineDaysPerWeek): RoutineCalendarDay[] {
  const firstOfMonth = new Date(year, monthIndex, 1);
  const mondayOffset = (firstOfMonth.getDay() + 6) % 7;
  const gridStart = new Date(year, monthIndex, 1 - mondayOffset);

  return Array.from({ length: 42 }, (_, index) => {
    const date = new Date(gridStart.getFullYear(), gridStart.getMonth(), gridStart.getDate() + index);
    return {
      date: toRoutineDate(date),
      dayOfMonth: date.getDate(),
      inCurrentMonth: date.getMonth() === monthIndex,
      expected: isExpectedRoutineDay(date, daysPerWeek),
    };
  });
}
