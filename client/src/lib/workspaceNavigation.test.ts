import { describe, expect, it } from "vitest";
import { appendWorkspaceTrail, takePreviousWorkspace } from "./workspaceNavigation";

describe("workspace navigation trail", () => {
  it("returns a nested workspace to the actual previous workspace", () => {
    const result = takePreviousWorkspace(["overview", "settings", "settings-history"], "overview");

    expect(result).toEqual({ workspace: "settings-history", trail: ["overview", "settings"] });
  });

  it("uses the declared fallback only when no prior workspace exists", () => {
    expect(takePreviousWorkspace([], "settings")).toEqual({ workspace: "settings", trail: [] });
  });

  it("retains the most recent eight previous workspaces", () => {
    const trail = ["one", "two", "three", "four", "five", "six", "seven", "eight"];

    expect(appendWorkspaceTrail(trail, "nine")).toEqual(["two", "three", "four", "five", "six", "seven", "eight", "nine"]);
  });
});
