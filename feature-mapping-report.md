# Expense Tracker Feature Mapping & Implementation Roadmap

**Author:** Manus AI  
**Project:** Expense Tracker (`expense-tracker-web`)  
**Design System:** Ink & Ledger (Warm paper, archival ink, antique-gold rules, Fraunces editorial headings, Space Grotesk numerals) [1].

---

## 1. Executive Summary

An analysis of the supplied feature screenshots indicates a comprehensive personal finance capability set—ranging from multi-month historical overview cards and granular budget pacing to debt/loan tracking and savings goals [2]. Rather than blindly cloning the reference application's UI (which mixes varied visual languages), our objective is to **integrate these valuable financial mechanics directly into our refined Ink & Ledger web interface**. 

This document establishes how each discovered feature maps to our existing architecture, the data-model updates required, and a prioritized rollout roadmap.

---

## 2. Feature Inventory & Architectural Mapping

The features identified across the reference screenshots have been classified into four functional tiers and mapped to our existing pages:

| Feature Category | Reference Capability | Target Web App Location | Proposed UI & Data Approach |
| :--- | :--- | :--- | :--- |
| **Multi-Month Overview** | Historical accordion cards showing monthly expense/income summaries and pacing [2]. | **Overview Tab (Dashboard)** | Replace the single-month summary with a collapsible historical ledger (Current Month + past 3–6 months) showing net savings capsules and daily averages. |
| **Advanced Budget Pacing** | Category-level progress bars with daily burn rate and projected overspend warnings [3]. | **Insights / Budget Section** | Enhance category budget bars to display "Avg Daily Expense" and intelligent pacing alerts (*"At current rate, you will overshoot by the 17th"*). |
| **Debt & Loan Tracking** | Tracking borrowed/lent amounts, repayment schedules, and per-loan progress [4]. | **Horizon Tab (New Sub-section)** | Add a "Debt & Loans" card alongside Goals & Plans, supporting borrowed/lent status, remaining balance, and daily repayment burden. |
| **Wealth Goals & Timelines** | Savings targets with deadline countdowns, completion percentages, and daily savings required [5]. | **Horizon Tab (Goals Workspace)** | Upgrade existing goals to display target completion dates, daily savings recommendations, and historical status notes. |

---

## 3. Recommended Phased Implementation Roadmap

To maintain stability and ensure high-fidelity execution, features will be introduced in three controlled development increments:

### Phase 1: Historical Overview & Pacing Enhancements
- **Monthly Accordion Ledger:** Allow users to expand past months (November 2025, October 2025, etc.) right from the Overview dashboard [2].
- **Burn-Rate Projections:** Calculate average daily spend dynamically and display budget overshoot warnings when spending exceeds safe monthly thresholds [3].

#### Implementation status — completed

The Overview dashboard now derives a **collapsible monthly ledger** from the actual transaction dates available in the app. Every populated month is represented as a fieldbook folio with income, expenses, net savings, average daily outflow, and a compact transaction excerpt. The current seed data contains August 2026 entries only, so the interface intentionally shows one month until additional historic records are created or imported; no artificial historical values have been introduced.

The Insights workspace now includes a **budget pacing sheet** for every top-level expense category with a monthly budget. It calculates amount spent, amount remaining, average daily outflow, a projected month-end spend, and an early warning when spending has exceeded the safe pace for the current day of the month. These calculations are transaction-derived and will update as the local ledger changes.

### Phase 2: Debt & Loan Management Workspace
- **Loan Entities:** Introduce `Loan` data structures (`title`, `type: borrowed/lent`, `totalAmount`, `paidAmount`, `dueDate`, `counterparty`).
- **Horizon Tab Extension:** Add a dedicated loan tracking card within the Goals & Plans workspace, complete with progress meters and quick payment logging.

### Phase 3: Advanced Analytics & Statement Export
- **Category Drill-Downs:** Tap any category spend breakdown to view historical subcategory trends across selected months.
- **Statement Generation:** Wire CSV and PDF export handlers to filter transactions by date range and account.

---

## 4. References

[1] Expense Tracker Design Token Specification, `client/src/index.css`.  
[2] Reference UI Capture, Overview & Monthly Summaries, `1000052279.png`.  
[3] Reference UI Capture, Budget Pacing & Projections, `1000052280.png`.  
[4] Reference UI Capture, Loan & Debt Management, `1000052281.png`.  
[5] Reference UI Capture, Goal Timelines & Daily Savings, `1000052282.png`.
