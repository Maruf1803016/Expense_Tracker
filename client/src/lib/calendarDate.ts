export function normaliseCalendarDate(value: string, fallback: Date): string {
  if (/^\d{4}-\d{2}-\d{2}$/.test(value)) return value;
  const parsed = new Date(value.replace(/^By\s+/i, ""));
  if (Number.isNaN(parsed.getTime())) {
    const year = fallback.getFullYear();
    const month = String(fallback.getMonth() + 1).padStart(2, "0");
    const day = String(fallback.getDate()).padStart(2, "0");
    return `${year}-${month}-${day}`;
  }
  const year = parsed.getFullYear();
  const month = String(parsed.getMonth() + 1).padStart(2, "0");
  const day = String(parsed.getDate()).padStart(2, "0");
  return `${year}-${month}-${day}`;
}

export function calendarYearChoices(focusedYear: number, count = 12): number[] {
  const start = focusedYear - Math.floor(count / 2);
  return Array.from({ length: count }, (_, index) => start + index);
}
