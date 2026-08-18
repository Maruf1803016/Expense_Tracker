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
- [ ] Agree the next focused build slice before adding further capabilities.

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
- [ ] Migrate the existing local prototype records only after a verified authenticated session and with clear failure recovery.
- [x] Run the TypeScript checker and production build for the Firebase browser integration.
- [x] Validate persistence across a signed-in refresh and logout/login.
- [ ] Exercise the visible Firestore-permission error state as part of the final security and resilience audit.
- [ ] Checkpoint the verified Firebase integration.

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
