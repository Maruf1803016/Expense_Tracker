import { formatReminderTime, type ReminderTimeFormat } from "./reminderTime";

const CLOCK_TIME = /^([01]\d|2[0-3]):[0-5]\d$/;
const MINUTES_PER_DAY = 24 * 60;

export function isRoutineClockTime(value: string | undefined): value is string {
  return typeof value === "string" && CLOCK_TIME.test(value);
}

export function routineTimeToMinutes(value: string) {
  if (!isRoutineClockTime(value)) return null;
  const [hours, minutes] = value.split(":").map(Number);
  return hours * 60 + minutes;
}

/** A checkout before check-in naturally crosses into the following calendar day. */
export function isRoutineShiftOvernight(checkIn: string | undefined, checkOut: string | undefined) {
  const start = checkIn ? routineTimeToMinutes(checkIn) : null;
  const end = checkOut ? routineTimeToMinutes(checkOut) : null;
  return start !== null && end !== null && end < start;
}

export function calculateRoutineShiftMinutes(checkIn: string | undefined, checkOut: string | undefined, nextDay = isRoutineShiftOvernight(checkIn, checkOut)) {
  const start = checkIn ? routineTimeToMinutes(checkIn) : null;
  const end = checkOut ? routineTimeToMinutes(checkOut) : null;
  if (start === null || end === null) return null;

  const duration = end - start + (nextDay ? MINUTES_PER_DAY : 0);
  return duration > 0 ? duration : null;
}

export function isRoutineTimeRangeValid(checkIn: string, checkOut: string, nextDay = isRoutineShiftOvernight(checkIn, checkOut)) {
  return calculateRoutineShiftMinutes(checkIn, checkOut, nextDay) !== null;
}

export function formatRoutineShiftDuration(minutes: number | null | undefined) {
  if (minutes === null || minutes === undefined || minutes <= 0) return "—";
  const hours = Math.floor(minutes / 60);
  const remainingMinutes = minutes % 60;
  return `${hours}h ${String(remainingMinutes).padStart(2, "0")}m`;
}

export function formatRoutineTimeRange(checkIn: string | undefined, checkOut: string | undefined, format: ReminderTimeFormat) {
  if (!isRoutineClockTime(checkIn) || !isRoutineClockTime(checkOut)) return "Times not recorded";
  return `${formatReminderTime(checkIn, format)} – ${formatReminderTime(checkOut, format)}`;
}

/**
 * Creates the compact, date-aware label used by the workday timeline, for
 * example: "Tue · 2:00 PM → Wed · 8:00 AM".
 */
export function formatRoutineShiftTimeline(date: string, checkIn: string | undefined, checkOut: string | undefined, format: ReminderTimeFormat, nextDay = isRoutineShiftOvernight(checkIn, checkOut)) {
  if (!isRoutineClockTime(checkIn) || !isRoutineClockTime(checkOut)) return "Attendance recorded — times optional";
  const startDate = new Date(`${date}T12:00:00`);
  if (Number.isNaN(startDate.getTime())) return formatRoutineTimeRange(checkIn, checkOut, format);

  const endDate = new Date(startDate);
  if (nextDay) endDate.setDate(endDate.getDate() + 1);
  const dayFormatter = new Intl.DateTimeFormat("en-US", { weekday: "short" });

  return `${dayFormatter.format(startDate)} · ${formatReminderTime(checkIn, format)} → ${dayFormatter.format(endDate)} · ${formatReminderTime(checkOut, format)}`;
}
