# Release Readiness Notes

## Non-destructive verification — 19 August 2026

An unauthenticated Firestore REST read against a user-scoped transaction path was rejected with `403 PERMISSION_DENIED`, confirming the owner-only rules block anonymous ledger access.

The live preview was also reviewed after the Settings repair. The Settings landing view now presents Daily Ledger Reminder, Currency, Accounts, Expense Categories, Income Sources, and Export as distinct, readable destinations. The reminder correctly remains labelled **Not set** for an unsigned-in preview because no account-scoped preference has been saved.

The approved account was signed in successfully for the reminder preference review. The profile panel confirmed that verification and password-reset messages remain unsent unless their respective explicit action is selected.

The Daily Ledger Reminder was then enabled at 10:00 PM in the signed-in workspace. The app completed the Firestore save and displayed both the **Configured** state and the confirmation message, “Daily reminder saved for 22:00.”

After a full page reload, Settings continued to show the reminder as **Set** with “Daily check-in at 22:00,” confirming that the preference is persisted and reloaded from Firestore rather than being only local UI state.

## GitHub source synchronization status

The local validated branch currently points to checkpoint `6f2f2271`; the requested GitHub `manus_repo` branch remains at `8a49a02`. Standard HTTPS, direct CLI-token, and SSH Git routes could not write with the pre-existing automation credential. A fresh GitHub Device Activation request is now open in a signed-in `Maruf1803016` session and awaits the owner’s authorization before the branch can be updated.

The owner completed GitHub Device Activation successfully; GitHub confirmed, “Congratulations, you’re all set! Your device is now connected.” The refreshed CLI credential can now be used to attempt the requested source synchronization.

## Actions deliberately awaiting user approval

No local prototype records have been migrated. No verification or password-reset email has been sent. The app has not been published, so the scheduled background reminder has not been tested on a closed device. The GitHub `manus_repo` branch exists at commit `8a49a02`, but the validated local source has not been pushed because write authorization remains pending.
