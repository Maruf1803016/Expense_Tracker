# Security and Release Acceptance Notes

## Implemented controls

The personal ledger uses **Firebase Email/Password authentication** and Firestore user-scoped collections. The published Firestore rule allows access only when the authenticated Firebase user ID matches the `users/{uid}` document path.

Transaction evidence uses a server-side route rather than a public storage link. Uploads require a Firebase ID token, accept only JPG, PNG, WEBP, or PDF files up to 8 MB, and write under `transaction-evidence/{uid}/...`. Downloads require the same token and validate that the requested storage key has the current owner’s prefix before streaming it with `private, no-store` caching and content-type protection.

The daily reminder handler only accepts an authenticated scheduled caller. It evaluates each enabled reminder in the user’s configured time zone, uses a Firestore transaction to claim one reminder per local day, creates an inbox notification, and then sends any registered device tokens in batches. The transaction claim prevents duplicate inbox reminders across retry attempts.

## Final owner acceptance checklist

| Area | Owner action | Expected result |
| --- | --- | --- |
| Email verification | Sign in, request verification from Profile, open the email, return, and refresh the verification status. | Profile reports the verified account state. |
| Password recovery | Use the Profile recovery action for a test address. | Firebase sends a reset email and the reset link opens securely. |
| Evidence retrieval | While signed in, upload an allowed attachment and open it from the transaction detail. Then sign out and revisit the same action. | The signed-in owner can view the file; signed-out access is denied. |
| Device reminders | Add `VITE_FIREBASE_VAPID_KEY` and `FIREBASE_SERVICE_ACCOUNT_JSON`, publish the site, enable the reminder, grant notification permission, and register the scheduled callback. | The inbox receives one reminder at the selected local time; the registered device receives a web push when supported. |
| Firestore isolation | Sign in with a second test account after recording a clearly labeled entry in the first account. | The second account cannot read or modify the first account’s ledger data. |
| GitHub release sync | At final delivery, reconnect GitHub with repository write access and push the verified checkpoint to `manus_repo`. | The GitHub branch points to the final validated source revision. |

## Release prerequisites

The scheduled reminder endpoint is implemented at `/api/scheduled/daily-expense-reminders`; it must be published before a Heartbeat job can reach it. Device push additionally requires a valid Firebase Web Push VAPID key and Firebase service-account JSON. The user controls publication and final GitHub synchronization; no externally visible release action is taken automatically.
