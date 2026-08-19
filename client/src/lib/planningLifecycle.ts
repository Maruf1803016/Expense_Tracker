export type PlanningLifecycleState = "active" | "completed";

export function planningIsActive(record: { status?: PlanningLifecycleState | string }) {
  return record.status !== "completed";
}

export function isWithinTwoYearRetention(completedAt?: string, reference = new Date()) {
  if (!completedAt) return false;
  const date = new Date(completedAt);
  if (Number.isNaN(date.getTime()) || date.getTime() > reference.getTime()) return false;
  const minimum = new Date(reference.getFullYear() - 2, reference.getMonth(), reference.getDate());
  return date >= minimum;
}

export function clampRoutineMonth(cursor: Date, reference = new Date()) {
  const latest = new Date(reference.getFullYear(), reference.getMonth(), 1);
  const earliest = new Date(reference.getFullYear(), reference.getMonth() - 11, 1);
  const requested = new Date(cursor.getFullYear(), cursor.getMonth(), 1);
  if (requested < earliest) return earliest;
  if (requested > latest) return latest;
  return requested;
}
