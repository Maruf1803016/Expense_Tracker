import { describe, expect, it } from "vitest";
import { dialAngleForIndex, dialIndexFromPointer } from "./timeDial";

describe("clock dial mapping", () => {
  it("maps the four cardinal clock positions to the expected 12-value positions", () => {
    expect(dialIndexFromPointer(0, -1, 12)).toBe(0);
    expect(dialIndexFromPointer(1, 0, 12)).toBe(3);
    expect(dialIndexFromPointer(0, 1, 12)).toBe(6);
    expect(dialIndexFromPointer(-1, 0, 12)).toBe(9);
  });

  it("maps a 24-hour dial in the same clockwise direction", () => {
    expect(dialIndexFromPointer(1, 0, 24)).toBe(6);
    expect(dialAngleForIndex(6, 24)).toBe(90);
    expect(dialAngleForIndex(-1, 12)).toBe(330);
  });
});
