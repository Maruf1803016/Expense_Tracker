# Daily Expense Reminder — Operations Record

## Live dispatcher

| Field | Value |
| --- | --- |
| Managed job name | `daily-expense-reminder-dispatch-v1` |
| Managed task UID | `W7K7Y3aTGRsPdXG2RcrF4P` |
| Callback | `POST /api/scheduled/daily-expense-reminders` |
| Schedule | `0 * * * * *` (once per minute, UTC scheduler clock) |
| Production domain | `https://expensetrk-btvssrs3.manus.space` |

The dispatcher evaluates each enabled user reminder in that user’s saved timezone. It sends only when the local time matches the selected reminder time. Firestore stores the local day of the last delivery, making repeated dispatcher runs safe and preventing duplicate daily inbox records.

## Production verification

On 2026-08-20, the production shell at `https://expensetrk-btvssrs3.manus.space` returned HTTP `200`. An unauthenticated public `POST` to the callback returned the expected HTTP `403`, confirming that the deployed callback is present and protected from public invocation. The job is enabled and persisted; its first platform execution record had not yet appeared during the initial activation window, so delivery remains subject to the next managed scheduler run and a real device configured with an enabled reminder.

## Operations

The managed job can be inspected, paused, resumed, or reviewed from the project’s **Schedules** area. For command-line maintenance, use the persisted task UID rather than the display name.

```bash
# Inspect status
manus-heartbeat list

# Inspect recent delivery runs
manus-heartbeat logs --task-uid W7K7Y3aTGRsPdXG2RcrF4P

# Pause if a delivery issue is under investigation
manus-heartbeat update --task-uid W7K7Y3aTGRsPdXG2RcrF4P --enable=false
```

No recipient data or Firebase token is written to this document. Device delivery still requires the user to enable a reminder and allow notifications on the relevant device.
