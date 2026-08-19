# Category Workflow Requirements
1. Expense: click category -> dropdown with parent rows & subcategories, plus inline subcategory creation.
2. Income: click category -> flat income list + "Add income category" button.
3. Shared state with Settings so everything stays consistent.


## Mobile responsive repair
- [x] Hide the desktop sidebar rail on narrow viewports and provide a compact mobile header.
- [x] Stack dashboard cards and prevent horizontal overflow on mobile.
- [x] Rebuild mobile bottom navigation spacing, labels, and center add button.
- [x] Validate mobile and desktop screenshots plus production build.
- [x] Save a checkpoint for the responsive repair.

## Style Decisions
- Preserve the Ink & Ledger editorial system: warm paper background, dark ink/gold accents, hairline cards, Fraunces display headings, Space Grotesk numeric values, and compact mobile-first spacing.


## Horizon and feature-restoration pass
- [x] Audit all main navigation tabs, dashboard actions, and modal submit paths for missing or no-op behavior.
- [x] Make Horizon goal and trip-plan create actions visibly enabled and functional on mobile.
- [x] Give Month in hand a dedicated dashboard section with clear ledger/budget context.
- [x] Check the recent app against the expected overview, insights, goals/plans, settings, profile, categories, accounts, and transaction flows.
- [x] Re-run mobile/desktop verification, production build, and save a new checkpoint.


## Horizon card and Insights interaction repair
- [x] Make savings-goal cards open a goal detail view with modify, deposit, and withdraw actions.
- [x] Make trip-plan cards open a trip-plan detail view with modify and linked-spend context.
- [x] Move Insight/Summary selection into a clearly labeled analytics sub-navigation instead of a redundant header button.
- [x] Verify mobile card taps, edit flows, analytics switching, type checks, production build, and checkpoint.


## Category picker refinement
- [x] Make expense picker select a parent category first, then reveal only its subcategories and the create-subcategory action.
- [x] Make income picker expose an inline Add income category action.
- [x] Keep newly created categories/subcategories immediately available in transaction editing and Settings.
- [x] Verify mobile editor behavior, type checks, production build, and checkpoint.


## Separate expense subcategory sheet
- [x] Open a dedicated subcategory sheet immediately after selecting an expense parent category.
- [x] Show only the selected parent’s existing subcategories and a clear Create subcategory action.
- [x] Return the chosen subcategory to the transaction editor and keep Settings synchronized.
- [x] Verify the mobile flow, checks, production build, and checkpoint.


## Cleaner expense category editor
- [x] Remove the permanently visible subcategory section from the transaction editor.
- [x] Keep subcategory selection and creation available from the parent category interaction.
- [x] Preserve selected values and Settings synchronization.
- [x] Verify mobile layout, checks, production build, and checkpoint.


## Screenshot roadmap — first implementation slice
- [x] Add a collapsible multi-month overview ledger with current and recent month summaries.
- [x] Add average daily expense/income and net-savings summaries to month rows.
- [x] Add category budget pacing with remaining amount, progress, daily burn rate, and projection warning.
- [x] Update the roadmap report with completed and remaining feature groups.
- [x] Verify responsive behavior, TypeScript check, production build, and checkpoint.

## Controlled feature planning
- [x] Reconcile the live web app with every screenshot-derived feature group.
- [x] Publish a completed-versus-remaining feature map with navigation placement and data dependencies.
- [x] Agree the next focused build slice before adding further capabilities.

## Approved slice 1 — finish and verify
- [x] Style and verify the collapsible monthly ledger on desktop and mobile.
- [x] Style and verify the category budget pacing and projection states.
- [x] Mark the completed dashboard slice in the feature roadmap before checkpointing.

## Debt & Loans workspace
- [x] Add local loan records with borrowed/lent direction, counterparty, due date, and repayment terms.
- [x] Add loan summary calculations for original amount, paid amount, remaining balance, and next payment.
- [x] Create Goals & Plans views for loan cards, detail history, add/edit, and record-payment flows.
- [x] Verify Debt & Loans on mobile and desktop, type-check, build, and checkpoint.

## Loan repayment method and note
- [x] Add a payment-method selector for cash, card, bank transfer, bKash, Nagad, and custom methods.
- [x] Add optional repayment notes and reference fields to payment records.
- [x] Show repayment method and note context in each loan history entry.
- [x] Verify payment recording on mobile and desktop, type-check, build, and checkpoint.

## Goal intelligence
- [x] Add an optional financing contribution and a deadline-aware remaining-savings calculation to each goal.
- [x] Show daily and weekly savings requirements plus progress and deadline pacing in goal cards and detail sheets.
- [x] Expand goal funding history with dated, annotated deposit and withdrawal context.
- [x] Verify responsive desktop/mobile presentation, TypeScript, and production build before checkpointing.

## Reported mobile visual regression and final review discipline
- [x] Fix the Net Worth header collision between the “Assets − debts” label and the “Account folio” stamp on narrow mobile screens.
- [x] Re-check the complete mobile scroll path after the layout repair, including bottom navigation clearance and long-card spacing.
- [x] Build and retain a strict final review matrix for each requested feature flow before the final product handoff.

## Recurring income and bills
- [x] Add recurring income and recurring expense schedule records with name, amount, frequency, account, category, and next due date.
- [x] Surface an Upcoming income and Upcoming bills workspace that makes the next payment timing obvious.
- [x] Allow users to mark a schedule paid/received, create the corresponding ledger entry, and correctly advance the next due date.
- [x] Support add, edit, pause, and resume flows without losing the schedule history.
- [x] Verify the schedule workspace on mobile and desktop, type-check, build, and checkpoint it.

## Information architecture and dashboard simplification
- [x] Reduce Overview to the daily financial snapshot: balance, month totals, net worth, upcoming schedules, and a concise recent ledger.
- [x] Create a dedicated Accounts & Assets destination for account folios, balances, liabilities, and account-level details.
- [x] Create a dedicated History destination for the full monthly ledger and budget pacing, with clear navigation from Overview.
- [x] Keep Insights analytical and Goals & Plans operational, avoiding duplicate dashboard content.
- [x] Validate desktop/mobile navigation, type-check, build, and checkpoint the reorganized information architecture.

## Reported mobile navigation and History defects
- [x] Add an obvious return control from Accounts & Assets to Overview on mobile and desktop destinations.
- [x] Add an obvious return control from History to Overview on mobile and desktop destinations.
- [x] Repair and verify month-record expand/collapse controls in the History workspace, including repeat toggles.
- [x] Validate navigation recovery and History interaction on mobile and desktop, type-check, build, and checkpoint the repair.

## Reported back-control presentation defect
- [x] Replace the oversized “Return to Overview” text line with a compact header-level back control on Accounts & Assets and History.
- [x] Preserve a clear return action while allowing the page eyebrow and title hierarchy to remain uncluttered on mobile.
- [x] Verify the compact back control on mobile and desktop, type-check, build, and checkpoint the visual refinement.

## Revised titled back-button layout
- [x] Put a compact titled “Back to Overview” button on its own line in Accounts & Assets and History.
- [x] Place the destination label (Account register or Recorded movement) on the following line before the page title.
- [x] Verify the revised header order on mobile and desktop, type-check, build, and checkpoint it.

## Reported dashboard action-affordance defect
- [x] Restyle the Net Worth “Accounts & Assets” control as an obvious touch-sized destination button.
- [x] Restyle the Recent Ledger “Open full history” control as an obvious touch-sized destination button.
- [x] Include visible arrow, pressed, hover, and keyboard-focus feedback while preserving the Ink & Ledger visual system.
- [x] Verify the controls and their navigation on mobile and desktop, type-check, build, and checkpoint the refinement.

## Reports and export
- [x] Create a dedicated Reports destination with date range, account, category, and transaction-type filters.
- [x] Calculate filtered inflow, outflow, net movement, transaction count, and category allocation from the selected ledger records.
- [x] Add a readable filtered-register preview with clearly visible active filter context and reset behavior.
- [x] Generate a client-side CSV file and a print-ready PDF report from the filtered ledger without sending data to an external service.
- [x] Verify filter accuracy, exported file content, mobile/desktop controls, TypeScript, production build, and checkpoint the slice.

## Firebase authentication and persistence
- [x] Obtain the Firebase Web App configuration for the existing project.
- [x] Confirm that Firebase Email/Password authentication is enabled for the Web App.
- [x] Confirm Firestore rules protect every user’s financial data by authenticated user ID before enabling real writes.
- [x] Model user-scoped transactions, categories, accounts, goals, trips, loans, and recurring schedules without changing the existing visual workflows.
- [x] Implement Email/Password sign-in, loading, error/retry, and sign-out states with durable Firestore reads and writes.
- [x] Assess existing local prototype records after a verified authenticated session and confirm that migration is not required because no browser-local ledger dataset exists.
- [x] Run the TypeScript checker and production build for the Firebase browser integration.
- [x] Validate persistence across a signed-in refresh and logout/login.
- [x] Validate the visible Firestore-permission recovery state as part of the final security and resilience audit, with focused regression coverage and no data exposure.
- [x] Checkpoint the verified Firebase integration.

## Approved live Firebase verification
- [x] Create or sign in to the approved test account and verify the authenticated profile state.
- [x] Add, modify, reload, and remove a clearly labeled test ledger entry; verify it remains scoped to the signed-in account.
- [x] Verify sign-out/sign-in session behavior and remove approved test artifacts after testing.

## Authentication language correction
- [x] Replace developer/demo-centric authentication language with clear, user-owned personal-ledger copy.
- [x] Verify the revised sign-in and account-creation drawer remains readable and reassuring on mobile.

## Authenticated schedule prerequisites
- [x] Make an empty Account selector clearly explain what is missing and provide a direct create/select path.
- [x] Make an empty Category selector clearly explain what is missing and provide a direct create/select path for the selected schedule type.
- [x] Verify that a new signed-in user can finish creating a recurring income or bill without navigating away from the schedule workflow.

## First-run personal ledger setup
- [x] Create a user-scoped Main Account automatically when a signed-in ledger has no accounts.
- [x] Create editable starter expense categories, one-level expense subcategories, and income categories when a signed-in ledger has no categories.
- [x] Make the initialization idempotent so reconnecting, refreshing, or retrying never duplicates starter records.
- [x] Verify the starter records make transaction and recurring-schedule selectors immediately usable.

## Category and subcategory icon system
- [x] Define a curated, sufficiently broad Lucide icon catalogue for finance categories and subcategories.
- [x] Give every starter category and subcategory an appropriate default icon.
- [x] Add a searchable icon picker to custom category and subcategory create/edit flows.
- [x] Persist selected icons and show them consistently in Settings, selectors, schedules, transactions, budgets, and reports.
- [x] Verify icon selection and display on both mobile and desktop before checkpointing.

## Compact permanent expense taxonomy
- [x] Define four to five protected, generic top-level expense categories with rich one-level starter subcategories.
- [x] Preserve user-created subcategories as editable records while preventing accidental deletion of the permanent top-level containers.
- [x] Apply permanent-category markers and compatible icons throughout Settings and expense selection.
- [x] Validate category selection, subcategory creation, responsive presentation, TypeScript, production build, and checkpoint.

## Profile completion
- [x] Add signed-in email-verification status and an actionable verification-email control.
- [x] Add a safe password-reset request flow for the account email.
- [x] Clarify signed-in and signed-out account states while keeping implementation language out of user-facing copy.
- [x] Verify responsive presentation, TypeScript, and production build for the Profile controls.
- [ ] Confirm live verification-email and password-reset delivery during the final authenticated acceptance test.

## Loan money flow and notifications
- [x] Create ledger cash movements when a loan is borrowed, lent, repaid, or collected, without double-counting loan balances in net worth.
- [x] Show loan cash movements in Overview, History, and relevant money-flow totals with clear source context.
- [x] Replace the temporary browser alert on the notification icon with an in-app notification panel.
- [x] Validate loan/account cash effects, mobile interactions, TypeScript, production build, and checkpoint.

## Notification inbox and daily expense reminder
- [x] Create persistent in-app notification records with clear unread and read states.
- [x] Make the bell use a distinct unread color, show a capped 9+ badge, and decrement the unread count as individual messages are opened.
- [x] Hide the count when all notifications are read while retaining a readable notification history.
- [x] Add a Settings notification section where users can enable the daily expense reminder and choose the reminder time, defaulting to 10:00 PM.
- [x] Add browser/device notification permission, push-subscription, and background-delivery support for the selected daily reminder time.
- [ ] Publish the reminder callback, register the platform Heartbeat, and live-verify an in-app reminder plus a closed/background device notification.
- [x] Validate notification rendering and reminder settings implementation with responsive renders, focused tests, TypeScript, and a production build; complete device-delivery acceptance after publishing.

## Expandable settings and enriched transaction records
- [x] Make Expense Categories, Income Categories, Notification Settings, and Export Data compact, independently expandable Settings sections.
- [x] Add a persistent currency setting in Settings and format ledger, analytics, and export monetary values using the saved preference.
- [x] Add a reminder enabled indicator that turns green only when the daily reminder is configured, alongside a selectable notification time zone.
- [x] Move the Reports & Export entry point into an expandable Export Data section in Settings without removing the existing report workspace.
- [x] Extend expense, income, and transfer records with optional payee, payer, and settlement status fields.
- [x] Add an attachment workflow for transaction evidence: camera capture, image selection, and digital receipt/document upload.
- [x] Store transaction attachments securely, retain their metadata with the ledger record, and present them in the transaction detail view.
- [x] Validate the new Settings and transaction workflows with responsive renders, focused tests, TypeScript, and a production build.
- [x] Save a checkpoint for the completed expandable Settings and transaction-evidence slice.

## Final Settings, payment, profile, and account refinement
- [x] Expand the saved currency catalogue with the primary international and regional choices, presented through a polished selector rather than a large raw list.
- [x] Replace the reminder status dot with a restrained, accessible configured-state treatment and keep Notification Settings collapsed when Settings opens.
- [x] Place a clear Pending/Paid state chip before each transaction amount and add a focused Overview list of unresolved pending entries.
- [x] Present optional form labels consistently as parenthesized, visually de-emphasized “(optional)” text.
- [x] Repair and optimize the profile verification and password-recovery actions, with clear feedback for success, failure, resend limits, and refresh state.
- [x] Remove every remaining Insights export shortcut so data export is accessed only from Settings.
- [x] Add an Account workspace inside Settings and move Accounts & Assets out of the Overview while preserving access to account registers.
- [x] Validate the final-review refinements with focused tests, TypeScript, production build, and responsive renders.
- [x] Save a checkpoint for the final Settings, payment, profile, and account refinement.

## Security-first release and source synchronization
- [x] Review the user-facing Firebase profile, recovery, attachment, and reminder flows for secure defaults and document the recommended acceptance path.
- [x] Verify the local repository branch, remote, working tree, and latest validated checkpoint before source synchronization.
- [x] Push the latest validated expense-tracker source to the GitHub `manus_repo` branch and verify the remote commit.
- [x] Restrict transaction-evidence downloads to the authenticated owner instead of exposing storage paths through a bearerless proxy.
- [x] Add the intended GitHub `manus_repo` remote or branch tracking after confirming its canonical repository URL.
- [x] Add an owner-authenticated evidence retrieval endpoint that validates Firebase identity and storage-key ownership before streaming a file.
- [x] Replace direct transaction-evidence links with an authenticated client viewing flow that never persists a bearerless storage URL.
- [x] Add focused ownership and route-validation tests for protected evidence retrieval.

## Category, ledger, settings, schedule, and date-control refinement
- [x] Expand useful default expense subcategories and income-source choices while preserving the existing one-level category model and category caps.
- [x] Improve monthly history so the current and earlier monthly summaries are more useful without duplicating the full ledger.
- [x] Make pending payments unmistakable in Overview and provide a direct, persistent way to filter pending entries within the full history.
- [x] Move the full-history action into the unused header space and restyle it as a visible Ink & Ledger control without a black background.
- [x] Return account-register and history subpages to Settings rather than Overview where they are launched from Settings.
- [x] Redesign the currency selector and rename Notification Settings with clearer, more polished configuration language.
- [x] Redesign recurring-schedule category selection so category and subcategory choices are clear, scoped, and consistent with the transaction workflow.
- [x] Replace the dated native date controls with an Ink & Ledger-compatible calendar-picker experience across relevant entry forms.
- [x] Validate responsive category, pending-history, Settings, schedule, and date-picker flows with tests, type checking, production build, and screenshots.

## Dedicated settings workspaces and picker polish
- [x] Replace expandable Settings content with dedicated focused workspaces for expense categories, income categories, currency, and daily ledger reminders.
- [x] Give every dedicated Settings workspace a clear return path to Settings and retain the Ink & Ledger editorial sheet hierarchy.
- [x] Replace the remaining legacy-looking picker interactions with consistent custom paper-sheet selection controls.
- [x] Refine the calendar date picker into a beautiful, touch-friendly choice experience across transaction, goal, plan, report, and schedule flows.
- [x] Restore the Recent Ledger heading to its original fixed hierarchy while retaining a visible, right-aligned full-history action.
- [x] Validate the workspace navigation, picker controls, and ledger hierarchy with automated checks, production build, and desktop/mobile screenshots.

## Reported mobile Settings and calendar regressions
- [x] Rebuild the mobile Settings destination cards so their icons, eyebrow text, titles, summaries, counts, and chevrons never collide or overflow.
- [x] Rework all dedicated Settings workspace lists and controls for readable touch targets, consistent card spacing, and a mobile-first single-column layout.
- [x] Repair Daily Ledger Reminder persistence so enabling the setting saves successfully and shows a configured state only after confirmation.
- [x] Clarify that verification and password-recovery emails are sent only after an explicit user action and retain the current no-automatic-email safeguard.
- [x] Add a clear month-and-year selection path to the custom Goal and Trip Plan deadline picker, including useful future-year navigation.
- [x] Verify the repaired mobile Settings, reminder, email-action language, and Goal/Plan calendar flows with tests, type checking, production build, and responsive screenshots.

## Owner final review
- [x] Prepare a feature-by-feature final-review checklist covering the complete Ink & Ledger experience, release-only checks, and expected outcomes.

## Non-destructive release readiness audit
- [x] Review the visible Firestore permission-error path and verify it gives a safe, understandable recovery message without exposing ledger data.
- [x] Inspect browser-local prototype data only to determine whether migration is necessary, without migrating, deleting, or altering any record.
- [x] Push the validated Firestore-resilience audit checkpoint to the GitHub `manus_repo` branch and verify the remote commit.

## Persistent inbox, Plans & Progress, and currency directory
- [x] Make the full Firestore-backed notification history permanently reachable from the bell and preserve unread/read behavior.
- [x] Rename the operational Goals & Plans destination to Plans & Progress across mobile and desktop navigation.
- [x] Add user-scoped Work & Routine records with a name, an expected 3–7-day working week, and monthly attendance history.
- [x] Add a calendar-style monthly Work & Routine Log that lets the user tap attendance days and shows attended versus expected workdays.
- [x] Replace the mobile currency tiles with a beautiful, searchable directory containing flag, code, name, symbol, and selected-state context.
- [x] Add regression coverage and validate the new flows with TypeScript, Vitest, production build, and responsive screenshots.
- [x] Save a checkpoint and synchronize the validated work to GitHub `manus_repo`.

## Reminder time-picker usability refinement
- [x] Replace the cramped single-line reminder time options with an accessible, touch-friendly hour-and-minute picker.
- [x] Preserve the current reminder time until the user explicitly confirms the new choice, with a clear selected-time summary.
- [x] Validate the revised picker on mobile, run TypeScript, Vitest, and production-build checks, then synchronize the checkpoint to GitHub `manus_repo`.

## Reminder time-format consistency
- [x] Use the 12-hour AM/PM display format in every user-facing reminder status and confirmation message.
- [x] Add regression coverage, validate the correction, and synchronize the checkpoint to GitHub `manus_repo`.

## Two-year retention and active planning history
- [x] Retain routine attendance and completed goal, trip/event, and loan records for two years without silently deleting historic data.
- [x] Limit the routine tracker to a clear rolling 12-month browsing experience under each named routine, while keeping the retained two-year record available from Settings.
- [x] Keep Plans & Progress limited to active records; move completed goals, trips/events, and loans to a readable Overview history area.
- [x] Allow completed records to be edited and automatically return to Plans & Progress when an edit makes them active again.
- [x] Add clear Overview and Settings navigation for browsing the retained history without overwhelming the dashboard.
- [x] Add regression coverage, validate mobile and desktop history flows, checkpoint, and synchronize the work to GitHub `manus_repo`.

## Settings history and routine archive refinement
- [x] Return from History to Settings when the History workspace was opened from Settings.
- [x] Replace the monotonous retained-attendance feed with a routine-first archive, using named routine cards and month selection.
- [x] Present selected routine months as a calendar with an attended/not-attended summary, while preserving the two-year retained record.
- [x] Validate the revised History and archive paths on mobile and desktop, then checkpoint and synchronize to GitHub `manus_repo`.

## Routine archive drill-down and payment wording
- [x] Rename the payment-method fallback from “Custom” to “Other” across the loan payment flow.
- [x] Keep routine archive details closed by default, then guide the user from routine selection to month selection to one calendar history view.
- [x] Validate the progressive routine archive and payment wording on mobile and desktop, then checkpoint and synchronize to GitHub `manus_repo`.
