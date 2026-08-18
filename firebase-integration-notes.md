# Firebase Web Integration Notes

The web tracker connects directly to the existing **expense-tracker-79ef7** Firebase project through Firebase's browser SDK. Firebase's web configuration identifies the project rather than granting privileged access; access control remains entirely dependent on Firebase Authentication and Firestore rules.

## Authentication boundary

The supported sign-in method for this release is **Email/Password** only. The application keeps the present Ink & Ledger sample ledger available while signed out, but must never write sample records to Firestore. A signed-in user receives only documents beneath `users/{uid}`.

| Concern | Web approach |
| --- | --- |
| Authentication state | A single application-level observer watches Firebase Authentication and exposes the active user, loading state, and understandable errors. |
| Sign-up and sign-in | Firebase's `createUserWithEmailAndPassword` and `signInWithEmailAndPassword` methods; users are signed in automatically after account creation. |
| Sign-out | Firebase's `signOut`; the app immediately returns to its local demonstration ledger. |
| Live updates | One Firestore collection listener per ledger area, cleaned up when the signed-in user changes or signs out. |
| Write feedback | Local UI stays responsive through Firestore's latency-compensated snapshots; failures are displayed with a retry-safe error message. |

## User-scoped collection mapping

The web client deliberately keeps the established Flutter collection names where they describe the same financial object, allowing both clients to use the same user scope. It will normalize differing presentation field names at the browser boundary rather than introducing duplicate financial tables.

| Firestore path below `users/{uid}` | Web model | Compatibility handling |
| --- | --- | --- |
| `accounts/{accountId}` | `Account` | Reads Flutter's `initialBalance` when present and preserves identifying display fields. |
| `categories/{categoryId}` | `Category` | Reads top-level categories and flattens legacy embedded expense subcategories for the web selector. New web categories use a nullable `parentId`; income remains flat. |
| `expenses/{transactionId}` | `Transaction` | Maps Flutter's `title` to the web's ledger label and retains account, category, type, date, plan/link, and payment context. |
| `plans/{goalId}` | `Goal` | Existing Flutter `Plan` documents are displayed as savings goals until its source-model rename is completed. |
| `tripPlans/{tripId}` | `Trip` | New, distinct budget-versus-actual trip/event plans; no collision with legacy savings goals. |
| `loans/{loanId}` | `Loan` | Web debt and repayment records, scoped to the same owner. |
| `recurringIncomeSources/{scheduleId}` | `RecurringSchedule` | Retains the existing Flutter schedule collection name while supporting both income and expense entries. |

## Required Firestore rule shape

Before real writes are enabled, Firestore rules must authorize only the signed-in owner of each subtree. The following **shape** is the required baseline; the project owner should confirm or deploy its equivalent in the Firebase console before real data is entered.

```firestore
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    match /users/{userId}/{document=**} {
      allow read, write: if request.auth != null && request.auth.uid == userId;
    }
  }
}
```

The recursive wildcard requires rules version 2 and deliberately prevents a user from listing another user's financial records. More restrictive field validation can be layered on later once all clients have converged on their shared schema.

## Sources

Firebase documents the browser Email/Password setup, including enabling the provider in the console and observing authentication state, in its password-based account guide.[1] Firebase documents `onSnapshot` listeners as the real-time update mechanism and notes that local writes update listeners before backend acknowledgement.[2] Firebase's rules guidance uses `request.auth.uid` to restrict access to the matching user document and explains that rules are evaluated against queries rather than acting as filters.[3]

[1]: https://firebase.google.com/docs/auth/web/password-auth
[2]: https://firebase.google.com/docs/firestore/query-data/listen
[3]: https://firebase.google.com/docs/firestore/security/rules-conditions
