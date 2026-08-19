export type ReminderMeridiem = "AM" | "PM";

const FALLBACK_TIME = "22:00";

export function reminderTimeParts(time: string): { hour: number; minute: string; meridiem: ReminderMeridiem } {
  const match = /^(?:[01]\d|2[0-3]):[0-5]\d$/.test(time) ? time : FALLBACK_TIME;
  const [hourText, minute] = match.split(":");
  const hour24 = Number(hourText);
  return {
    hour: hour24 % 12 || 12,
    minute,
    meridiem: hour24 >= 12 ? "PM" : "AM",
  };
}

export function reminderTimeFromParts(hour: number, minute: string, meridiem: ReminderMeridiem): string {
  const normalisedHour = Math.min(12, Math.max(1, Math.round(hour)));
  const normalisedMinute = /^[0-5]\d$/.test(minute) ? minute : "00";
  const hour24 = (normalisedHour % 12) + (meridiem === "PM" ? 12 : 0);
  return `${String(hour24).padStart(2, "0")}:${normalisedMinute}`;
}

export function formatReminderTime(time: string): string {
  const { hour, minute, meridiem } = reminderTimeParts(time);
  return `${hour}:${minute} ${meridiem}`;
}
