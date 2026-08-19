export type LedgerOperation = "access" | "save" | "remove" | "prepare";

type FirebaseErrorLike = { code?: unknown };

function errorCode(error: unknown) {
  return error && typeof error === "object" && "code" in error && typeof (error as FirebaseErrorLike).code === "string"
    ? (error as FirebaseErrorLike).code
    : "";
}

function operationLabel(operation: LedgerOperation) {
  if (operation === "save") return "save this change";
  if (operation === "remove") return "remove this record";
  if (operation === "prepare") return "prepare your starter ledger";
  return "open your cloud ledger";
}

export function ledgerErrorMessage(error: unknown, operation: LedgerOperation) {
  const code = errorCode(error);
  const action = operationLabel(operation);

  if (code === "permission-denied") {
    return `Your signed-in account is not allowed to ${action}. Sign out, sign in with the account that owns this ledger, then refresh. If it continues, verify the owner-only Firestore rules.`;
  }

  if (code === "unauthenticated") {
    return `Your sign-in session needs attention before you can ${action}. Sign in again, then retry.`;
  }

  if (code === "unavailable" || code === "deadline-exceeded") {
    return `Your cloud ledger is temporarily unavailable. Check your connection, keep this tab open, and retry when it is stable.`;
  }

  if (operation === "save") return "This change could not be saved to your cloud ledger. Keep this tab open and retry after checking your connection.";
  if (operation === "remove") return "This record could not be removed from your cloud ledger. Keep this tab open and retry after checking your connection.";
  if (operation === "prepare") return "Your starter account and categories could not be prepared. Refresh to retry once your connection is stable.";
  return "Cloud ledger access was interrupted. Check your Firestore rules or connection, then refresh to retry.";
}
