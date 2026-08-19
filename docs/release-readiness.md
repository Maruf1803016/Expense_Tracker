# Release Readiness Notes

## Non-destructive verification — 19 August 2026

An unauthenticated Firestore REST read against a user-scoped transaction path was rejected with `403 PERMISSION_DENIED`, confirming the owner-only rules block anonymous ledger access.

The live preview was also reviewed after the Settings repair. The Settings landing view now presents Daily Ledger Reminder, Currency, Accounts, Expense Categories, Income Sources, and Export as distinct, readable destinations. The reminder correctly remains labelled **Not set** for an unsigned-in preview because no account-scoped preference has been saved.

The approved account was signed in successfully for the reminder preference review. The profile panel confirmed that verification and password-reset messages remain unsent unless their respective explicit action is selected.

The Daily Ledger Reminder was then enabled at 10:00 PM in the signed-in workspace. The app completed the Firestore save and displayed both the **Configured** state and the confirmation message, “Daily reminder saved for 22:00.”

After a full page reload, Settings continued to show the reminder as **Set** with “Daily check-in at 22:00,” confirming that the preference is persisted and reloaded from Firestore rather than being only local UI state.

## GitHub source synchronization status

The local validated branch currently points to checkpoint `312ca50b`; the requested GitHub `manus_repo` branch remains at `8a49a02`. Standard HTTPS, direct CLI-token, and SSH Git routes could not write with the pre-existing automation credential. A fresh GitHub Device Activation request was then completed successfully in the signed-in `Maruf1803016` session.

The owner subsequently supplied a valid fine-grained token. GitHub’s repository API confirms that it authenticates as `Maruf1803016` and has `admin`, `push`, and `pull` permissions for `Expense_Tracker`. The standard push was therefore authenticated, but GitHub rejected it as non-fast-forward.

The local web application and remote `manus_repo` have no merge base: the remote branch holds the prior Flutter history, while local `main` contains the separately built web application and its validation checkpoints. Replacing `manus_repo` with the complete current web source consequently requires an explicit user-approved `--force-with-lease` update, which will replace that branch’s visible history without deleting the preserved commits from GitHub’s object store.

## Actions deliberately awaiting user approval

No local prototype records have been migrated. No verification or password-reset email has been sent. The app has not been published, so the scheduled background reminder has not been tested on a closed device. The GitHub `manus_repo` branch exists at commit `8a49a02`, but the validated local source has not been pushed because replacing its unrelated existing branch history requires explicit confirmation.
