export function dashboardMonthLabel(referenceDate: Date = new Date()): string {
  return referenceDate.toLocaleDateString("en-US", { month: "long" });
}
