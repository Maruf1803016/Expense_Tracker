import { formatReminderTime, type ReminderTimeFormat } from "./reminderTime";

const CLOCK_TIME = /^([01]\d|2[0-3]):[0-5]\d$/;

export function isRoutineTimeRangeValid(checkIn: string, checkOut: string) {
  return CLOCK_TIME.test(checkIn) && CLOCK_TIME.test(checkOut) && checkIn < checkOut;
}

export function formatRoutineTimeRange(checkIn: string | undefined, checkOut: string | undefined, format: ReminderTimeFormat) {
  if (!checkIn || !checkOut || !CLOCK_TIME.test(checkIn) || !CLOCK_TIME.test(checkOut)) return "Times not recorded";
  return `${formatReminderTime(checkIn, format)} – ${formatReminderTime(checkOut, format)}`;
}
