import { readFileSync } from "node:fs";
import { fileURLToPath } from "node:url";
import { describe, expect, it } from "vitest";

const homeSource = readFileSync(fileURLToPath(new URL("../pages/Home.tsx", import.meta.url)), "utf8");
const styles = readFileSync(fileURLToPath(new URL("../index.css", import.meta.url)), "utf8");

describe("time-picker viewport safety", () => {
  it("keeps confirmation actions outside the reminder picker’s scrollable control body", () => {
    const bodyStart = homeSource.indexOf('className="ledger-time-wheel-body"');
    const actionStart = homeSource.indexOf('className="ledger-time-wheel-actions"');

    expect(bodyStart).toBeGreaterThan(-1);
    expect(actionStart).toBeGreaterThan(bodyStart);
    expect(homeSource.slice(bodyStart, actionStart)).toContain("LedgerTimeClockDial");
    expect(styles).toContain(".time-picker-sheet .ledger-time-wheel-body { min-height: 0; overflow-y: auto;");
    expect(styles).toContain(".time-picker-sheet .ledger-time-wheel { display: grid; grid-template-rows: auto minmax(0, 1fr) auto;");
  });

  it("anchors the reminder dialog to the viewport and gives the overlay its own safe scroll path", () => {
    expect(homeSource).toContain('className="ledger-calendar-backdrop workspace-picker-backdrop"');
    expect(styles).toContain(".ledger-calendar-backdrop.workspace-picker-backdrop { position: fixed; inset: 0; z-index: 60; display: grid; place-items: center; padding: 14px; overflow-y: auto;");
    expect(styles).toContain(".ledger-calendar-backdrop.workspace-picker-backdrop .time-picker-sheet { width: min(100%, 590px); max-height: min(calc(100dvh - 28px), 720px); margin: auto; }");
    expect(styles).toContain(".workspace-choice-backdrop { position: fixed; inset: 0; z-index: 60; display: grid; place-items: center; padding: 18px; overflow-y: auto;");
    expect(styles).toContain("@media (max-width: 760px) { .ledger-calendar-backdrop.workspace-picker-backdrop { align-items: end; padding: 12px 0 0; }");
  });

  it("keeps a direct minute entry as a draft until both digits are available", () => {
    expect(homeSource).toContain('const [minuteInputDraft, setMinuteInputDraft] = useState<string | null>(null);');
    expect(homeSource).toContain('const digits = input.replace(/\\D/g, "").slice(0, 2);');
    expect(homeSource).toContain("if (digits.length === 2) {");
    expect(homeSource).toContain("value={minuteInputDraft ?? String(parts.minute).padStart(2, \"0\")}");
    expect(homeSource).toContain("onChange={(event) => handleMinuteInput(event.target.value)}");
  });
});
