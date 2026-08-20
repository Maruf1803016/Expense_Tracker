export function appendWorkspaceTrail<T>(trail: readonly T[], current: T, limit = 8): T[] {
  return [...trail.slice(-(Math.max(1, limit) - 1)), current];
}

export function takePreviousWorkspace<T>(trail: readonly T[], fallback: T): { workspace: T; trail: T[] } {
  return {
    workspace: trail[trail.length - 1] ?? fallback,
    trail: trail.slice(0, -1),
  };
}
