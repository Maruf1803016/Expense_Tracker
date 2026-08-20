/** Maps a point around a clock centre to the nearest selectable dial position.
 * Index zero is the 12 o'clock position and values proceed clockwise. */
export function dialIndexFromPointer(x: number, y: number, optionCount: number): number {
  if (!Number.isInteger(optionCount) || optionCount < 1) return 0;
  const radians = Math.atan2(x, -y);
  const clockwiseTurn = (radians + Math.PI * 2) % (Math.PI * 2);
  return Math.round((clockwiseTurn / (Math.PI * 2)) * optionCount) % optionCount;
}

/** Provides an SVG-ready hand angle where zero degrees points straight up. */
export function dialAngleForIndex(index: number, optionCount: number): number {
  if (!Number.isInteger(optionCount) || optionCount < 1) return 0;
  return ((index % optionCount) + optionCount) % optionCount * (360 / optionCount);
}
