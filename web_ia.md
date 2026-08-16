# Responsive Web Information Architecture

The web app preserves the Flutter product’s four primary destinations while adapting them to a desktop-first ledger rail and a mobile reading stack.

| Web destination | Flutter source | First web delivery |
| --- | --- | --- |
| **Overview** | Expenses dashboard | Balance, income/expense summary, accounts, transaction search/filter, upcoming items, and an add-transaction drafting sheet. |
| **Insights** | Stats tab | Cash-flow trend, category spend allocation, and monthly budget performance. |
| **Horizon** | Goals + Trip Plans | Separate savings-goal and trip-plan views, progress context, and plan-aware transactions. |
| **Settings** | Settings tab | A concise account and export-ready settings surface that preserves the route without overbuilding it in the first static delivery. |

## Web Data Vocabulary

The first delivery keeps the existing domain vocabulary visible in a local browser state model: `Transaction`, `Account`, `Goal`, and `TripPlan`. A `Transaction` can retain a legacy `goalId` for savings mechanics and a separate `tripPlanId` for budgeted trips/events, matching the Dart rename/split that exists in `manus_repo`.

## Responsive Rules

Desktop uses a 260px ledger rail, a wide dashboard field, and a secondary analysis column. Tablet retains the rail at reduced width. Mobile collapses the rail to a compact header and bottom action strip; card collections become a reading stack and tables become labeled transaction rows.

## First-Delivery Interaction Contract

The site is intentionally frontend-only. Search, transaction type filters, Horizon tabs, selected navigation, add-transaction drafting, goal creation, and trip-plan creation operate in local browser state. The project can be upgraded later with authenticated persistence without changing the visual model.
