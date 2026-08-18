# Expense Tracker — Strict Final Review Matrix

## Purpose

This checklist is the release gate for the responsive Ink & Ledger web prototype. A feature is only considered complete at final handoff after its **happy path**, **modification path**, **empty/error state**, and **mobile/desktop presentation** have each been exercised. Any failure returns the feature to the active work list rather than being described as complete.

## Product Flows Already Implemented

| Area | Required final checks | Current implementation status |
|---|---|---|
| Dashboard and ledger | Balance, income/outflow/savings-rate, net worth, account folios, month history, search, filters, and transaction selection | Implemented; requires final end-to-end review |
| Information architecture | Overview shows only the daily snapshot; Accounts & Assets contains folios and liabilities; History contains month-by-month ledger and budget pacing; Insights and Goals & Plans retain their specialized workspaces | Implemented; requires final end-to-end review |
| Transactions | Add income, expense, and transfer; choose account; set category; inspect entry; use **Modify entry**; save edited values | Implemented; requires final end-to-end review |
| Categories | Expense parent selection followed by a separate subcategory sheet; create one-level expense subcategory; add flat income category; observe Settings synchronization; enforce 8/6 category caps | Implemented; requires final end-to-end review |
| Accounts and assets | Add, edit, display masked account details, reflect balances and liabilities in net worth | Implemented in the local prototype; requires final end-to-end review |
| Goals | Create, modify, deposit, withdraw, finance a goal, inspect date-aware daily/weekly pace, and read annotated funding history | Implemented; requires final end-to-end review |
| Trip and event plans | Create a plan, link eligible expenses, inspect planned versus actual spending | Implemented; requires final end-to-end review |
| Debt and loans | Create borrowed/lent record, add repayment, select payment method, store note/reference, inspect repayment history and remaining balance | Implemented; requires final end-to-end review |
| Recurring income and bills | Create/edit bill or income schedule; select amount, cadence, account, category, and due date; mark paid/received; confirm ledger entry and forward next date; pause/resume; inspect occurrence history | Implemented; requires final end-to-end review |
| Insights and budgets | Switch trend/summary views, inspect category mix, open a category context, verify monthly budget pace and warnings | Implemented; requires final end-to-end review |
| Profile and settings | Open profile, edit personal fields, access categories, accounts/assets, preferences, recycle bin, and export actions | Implemented as a local prototype; requires final end-to-end review |
| Responsiveness | Verify compact header, scrolling, raised center action, bottom-navigation clearance, drawers, long labels, and no overlapping controls at mobile and desktop widths | Regression repaired; requires final broad review |

## Work Still Left Before a Production-Ready Personal-Finance App

| Priority | Remaining slice | Why it remains | Acceptance criteria |
|---|---|---|---|
| 1 | Advanced reports and real exports | Current export feedback is a local placeholder, not a user-downloadable reporting workflow | Date-range/account/category filters; CSV and PDF file generation; accurate totals matching the filtered ledger |
| 2 | Firebase authentication and Firestore persistence | The current implementation is intentionally local-state only, so data is not durable or synchronized | Email/password authentication; protected user scope; Firestore CRUD; loading/error/retry states; existing Flutter data-model alignment |
| 3 | Import and robust account management | The app needs an onboarding/import path for real accounts, balances, and historical transactions | CSV import preview and validation; duplicate handling; account number masking; safe balance reconciliation |
| 4 | Final release audit | Visual and functional quality must be tested as a complete product rather than as isolated feature slices | Complete every row in this document on mobile and desktop; log defects; re-test fixes; only then mark release-ready |

## Final Test Record

| Test record | Result |
|---|---|
| Mobile Net Worth collision: “Assets − debts” versus “Account folio” | **Resolved.** The two labels now occupy separate grid positions on narrow screens. |
| Mobile full-scroll review after repair | **Passed.** The long dashboard remains scrollable and the fixed navigation clears the content. |
| Desktop overview after repair | **Passed.** The desktop account-folio treatment remains intact. |
| TypeScript and production build after repair | **Passed.** |
| Recurring income and bills workspace | **Passed.** Schedules are visible on the dashboard and in Goals & Plans; creation, settlement, pause/resume, and history have passing TypeScript and production-build validation. |
| Dashboard information architecture | **Passed.** The Overview now holds daily financial signals only, while account folios and the full history have dedicated destinations. Desktop/mobile rendering, TypeScript, and production build passed. |
| Accounts & Assets and History navigation repair | **Passed.** Both dedicated destinations now include a visible “Return to Overview” control. The History month record was manually expanded, collapsed, and expanded again in the live interface; labels now clearly state “Tap to view” and “Tap to close.” |
| Compact header back control | **Passed.** The long mobile return line was replaced by an accessible circular back arrow in the page-header eyebrow row, preserving the Overview return action without competing with the page label or title. |
| Titled back-button hierarchy | **Passed.** The final header order is now Back to Overview button, destination label, then page title. This preserves both a labeled escape route and independent editorial hierarchy in Accounts & Assets and History. |
| Dashboard destination affordance | **Passed.** The Accounts & Assets and Open full history destinations are now separately placed, outlined, touch-sized buttons with directional arrows and active/focus feedback rather than editorial text links. |

> The final release review is intentionally still open. It will be completed after the remaining product slices are implemented, so that the review measures the complete product rather than a temporary subset of it.
