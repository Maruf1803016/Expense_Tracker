# Background Reminder Delivery Notes

The chosen reminder experience requires a web client, a browser service worker, and a trusted sender. Firebase Cloud Messaging (FCM) requires HTTPS, notification permission, a web-push VAPID key, and a `firebase-messaging-sw.js` service worker for background delivery. The client must register and persist its device registration; the trusted server sends the scheduled notification through FCM. The background notification may open or focus the tracker when tapped.

For this project, the reminder setting should persist per authenticated user alongside a device subscription and notification records. A scheduled backend job must evaluate the user-selected local reminder time and send only one reminder per day. The frontend will mirror every reminder in the in-app notification inbox and manage unread/read state there.

## Sources

1. Firebase, [Get started with Firebase Cloud Messaging in Web apps](https://firebase.google.com/docs/cloud-messaging/web/get-started), accessed 2026-08-18.
2. Firebase, [Receive messages in Web apps](https://firebase.google.com/docs/cloud-messaging/web/receive-messages), accessed 2026-08-18.
3. Firebase, [Firebase Cloud Messaging overview](https://firebase.google.com/docs/cloud-messaging), updated 2026-08-13.

## Project delivery decision

The project has been upgraded with its server and database capabilities so background delivery can be performed by a trusted backend rather than the browser alone. End-user reminder schedules must use the platform-managed Heartbeat pattern, not an in-process timer. Each user-owned reminder setting therefore needs a stored Heartbeat task identifier; the scheduled callback must be placed under `/api/scheduled/`, authenticate the cron request, and be idempotent. A production deployment is required before a user schedule can be created or updated.

## Upgrade compatibility finding

The upgrade added an example authentication declaration to the existing Firebase-authenticated ledger page, causing a duplicate `user` identifier. The example declaration was removed, leaving the existing Firebase `AuthProvider` and Profile workflow intact. The application wrapper also correctly retained the original ledger page and Firebase provider.

The backend entry point supports mounting an explicit Express handler before the Vite/static fallthrough. The installed Heartbeat helper exposes create, update, and delete calls using a six-field UTC cron expression. The current reminder design will store a task UID beside the reminder setting and resolve scheduled work only through the task UID, as required.

The existing tracker authenticates with Firebase rather than the platform's server session. To preserve this established model, the production reminder will use a single owner-managed scheduled callback that reads each Firebase user's saved reminder settings and sends only to that user's registered browser token. The callback will run through the platform scheduler and must be configured only after a production deployment. No in-process browser or server timer will be used.

## Notification inbox integration boundary

The existing bell currently derives notices from due loans and recurring schedules at render time. The completed inbox must merge those actionable notices with user-scoped Firestore notification records, preserve read state, cap the visual unread badge at `9+`, and mark a record read only when its card is opened. Reminder preferences belong in a user-scoped Firestore record; browser permission and FCM token registration stay client-side, while the secured scheduled callback owns idempotent background delivery and companion inbox creation.
