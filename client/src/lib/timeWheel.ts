import { reminderTimeFromParts, reminderTimeParts, type ReminderTimeFormat } from "./reminderTime";

export type LedgerTimeWheelField = "hour" | "minute" | "period";

/** Returns the option nearest the visual centre of a scroll wheel. */
export function centredLedgerTimeWheelOption<T extends string>(options: readonly T[], optionCenters: readonly number[], scrollTop: number, viewportHeight: number): T | undefined {
  if (!options.length || options.length !== optionCenters.length) return undefined;
  const viewportCenter = scrollTop + viewportHeight / 2;
  let closestIndex = 0;
  let closestDistance = Math.abs(optionCenters[0] - viewportCenter);
  for (let index = 1; index < optionCenters.length; index += 1) {
    const distance = Math.abs(optionCenters[index] - viewportCenter);
    if (distance < closestDistance) {
      closestIndex = index;
      closestDistance = distance;
    }
  }
  return options[closestIndex];
}

/** Advances one wheel column while leaving the other displayed columns untouched. */
export function stepLedgerTimeWheel(value: string, timeFormat: ReminderTimeFormat, field: LedgerTimeWheelField, delta: number) {
  const parts = reminderTimeParts(value);
  if (field === "hour") {
    if (timeFormat === "24h") {
      const hour = (Number(value.slice(0, 2)) + delta % 24 + 24) % 24;
      return `${String(hour).padStart(2, "0")}:${parts.minute}`;
    }
    const hour = ((parts.hour - 1 + delta % 12 + 12) % 12) + 1;
    return reminderTimeFromParts(hour, parts.minute, parts.meridiem);
  }
  if (field === "minute") {
    const minute = (Number(parts.minute) + delta % 60 + 60) % 60;
    return timeFormat === "24h"
      ? `${value.slice(0, 2)}:${String(minute).padStart(2, "0")}`
      : reminderTimeFromParts(parts.hour, String(minute).padStart(2, "0"), parts.meridiem);
  }
  return reminderTimeFromParts(parts.hour, parts.minute, parts.meridiem === "AM" ? "PM" : "AM");
}
