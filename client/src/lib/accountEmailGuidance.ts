export const accountEmailGuidance = {
  preflight: "Verification and recovery emails are delivered through Firebase Authentication for Expense Ledger. Their secure link may look long because it contains a one-time account code. Open it only if you requested it.",
  verificationRequested: (email: string) => `Verification email requested for ${email}. It is delivered through Firebase Authentication for Expense Ledger. The secure link may look long; open it only if you requested it, then return here and choose Refresh status.`,
  passwordResetRequested: (email: string) => `Password-reset instructions were requested for ${email}. Check Inbox, Spam, and Promotions for an Expense Ledger email delivered through Firebase Authentication. The secure link may look long; use only the newest link you requested.`,
};
