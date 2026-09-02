# Expense Tracker — Complete App & Architecture Documentation

This document provides an exhaustive breakdown of the **Expense Tracker** application, including architecture, functional features, mathematical analysis engines, state management, and backend storage connections (service & collection names only, no external links). Use this document as a complete context reference for Gemini or any AI development assistant.

---

## 1. Executive Summary & Tech Stack

- **Application Name**: Expense Tracker (Personal Ledger & Forward Horizon)
- **Framework**: Flutter (Dart 3.x) with Material 3 & Custom Editorial Design System
- **Architecture Pattern**: Clean Architecture (Presentation, Domain, Data) with Feature-Driven Modular Folder Structure
- **State Management**: `Provider` + `ChangeNotifier` with reactive dependency injection via `GetIt` (`sl`)
- **Backend & Cloud Services**: Firebase Authentication, Cloud Firestore (Offline-First cache enabled)
- **Local Persistence & OS Plugins**:
  - `shared_preferences` (Local configuration, privacy toggles, cache)
  - `path_provider` (Local file path resolution)
  - `image_picker` (Camera & Gallery receipt capture)
  - `file_picker` (CSV/Data import & file selection)
  - `share_plus` (System share sheet for statements & CSVs)
  - `pdf` & `printing` (Client-side vector PDF financial statement generation)
  - `csv` (RFC 4180 compliant CSV parser and serializer)
  - `google_fonts` (Typography: Fraunces, Space Grotesk, Inter)
  - `fl_chart` & Custom Canvas `CustomPainter` (High-performance reactive charting)

---

## 2. Design System & Editorial Visual Language

The app adopts a signature **Warm Paper & Deep Archival Ink** aesthetic:
- **Paper Background**: `#F8F4EC` (`AppTheme.paper`)
- **Card Surface**: `#FFFFFF` (`AppTheme.paperCard`) / `#F1EDE4` (`AppTheme.paper2`)
- **Archival Ink**: `#1B3A2B` (`AppTheme.ink`) / `#12261C` (`AppTheme.ink2`)
- **Ledger Gold Accent**: `#B78A3D` / `#C89B3C` (`AppTheme.gold`, `AppTheme.goldSoft`)
- **Inflow / Positive Green**: `#1E6F55` (`AppTheme.emerald`)
- **Outflow / Expense Brick**: `#A23B3B` / `#C84C32` (`AppTheme.brick`)
- **Typography Matrix**:
  - **Headers & Titles**: *Fraunces* (Editorial Serif)
  - **Numeric Amounts & Metrics**: *Space Grotesk* (Monospace-proportional financial numbers)
  - **Labels, Body & Meta**: *Inter* (Clean neutral sans-serif)

---

## 3. Backend Connections & Data Storage (Names Only, No Links)

### A. Authentication (Firebase Auth)
- **Backend Service Name**: `FirebaseAuth`
- **Supported Methods**:
  - Email & Password Authentication (`signInWithEmailAndPassword`, `createUserWithEmailAndPassword`)
  - Google Sign-In (`GoogleAuthProvider`)
  - Password Reset & Profile Updates (`sendPasswordResetEmail`, `updateDisplayName`, `updatePassword`)
  - Anonymous Guest Session fallback

### B. Database Collections & Document Paths (Cloud Firestore)
Firestore uses a strict multi-tenant user-isolated hierarchy under `/users/{userId}/`:

1. **`users` Collection** (`/users/{userId}`):
   - Stores user profile metadata: `email`, `displayName`, `photoUrl`, `createdAt`, `defaultCurrency` (Default: `BDT` / `৳`), `hideAmounts` boolean.

2. **`expenses` Collection** (`/users/{userId}/expenses/{expenseId}`):
   - **Fields**:
     - `id` (String UUID)
     - `title` / `description` (String)
     - `amount` (Double)
     - `type` (String: `'expense'` | `'income'`)
     - `categoryId` (String UUID)
     - `categoryName` (String)
     - `accountId` (String UUID: Cash, Bank, Mobile Wallet)
     - `date` (Timestamp)
     - `notes` (String)
     - `receiptUrl` / `receiptLocalPath` (String)
     - `tags` (List of Strings)
     - `planId` (String UUID: optional linkage to a Savings Goal or Trip Plan)
     - `isDeleted` (Boolean: soft delete flag)
     - `deletedAt` (Timestamp: for 30-day recycle bin retention)
     - `createdAt`, `updatedAt` (Timestamps)

3. **`categories` Collection** (`/users/{userId}/categories/{categoryId}`):
   - **Fields**: `id`, `name`, `iconName`, `colorHex`, `type` (`'expense'` | `'income'`), `monthlyBudgetLimit`, `isArchived`, `orderIndex`.

4. **`accounts` Collection** (`/users/{userId}/accounts/{accountId}`):
   - **Fields**: `id`, `name`, `type` (`'cash'`, `'bank'`, `'mobile_banking'`, `'credit_card'`), `initialBalance`, `currentBalance`, `currency`, `isDefault`.

5. **`budgets` Collection** (`/users/{userId}/budgets/{budgetId}`):
   - **Fields**: `id`, `categoryId`, `monthYear` (e.g. `'2026-09'`), `limitAmount`, `alertThresholdPercent` (e.g. `80%`).

6. **`plans` / `goals` Collection** (`/users/{userId}/plans/{planId}`):
   - **Fields**: `id`, `title`, `targetAmount`, `currentSavedAmount`, `targetDate`, `category`, `notes`, `isArchived`, `linkedExpenseIds`.

7. **`trip_plans` Collection** (`/users/{userId}/trip_plans/{tripId}`):
   - **Fields**: `id`, `destination`, `startDate`, `endDate`, `budgetAmount`, `totalSpent`, `currency`, `itineraryNotes`, `isCompleted`.

8. **`loans` / `debts` Collection** (`/users/{userId}/loans/{loanId}`):
   - **Fields**: `id`, `borrowerOrLenderName`, `type` (`'borrowed'` [Payable] | `'lent'` [Receivable]), `principalAmount`, `remainingAmount`, `interestRate`, `issueDate`, `dueDate`, `repaymentHistory` (Array of sub-payments).

9. **`recurring_sources` Collection** (`/users/{userId}/recurring/{recurringId}`):
   - **Fields**: `id`, `title`, `type` (`'expense'` | `'income'`), `expectedAmount`, `frequency` (`'daily'`, `'weekly'`, `'monthly'`, `'yearly'`), `nextDueDate`, `autoPost`, `categoryId`, `accountId`.

10. **`work_routines` Collection** (`/users/{userId}/work_routines/{routineId}`):
    - **Fields**: `id`, `title`, `hourlyRate` / `monthlySalary`, `plannedDaysPerMonth`, `attendedDates` (List of ISO dates `'YYYY-MM-DD'`), `shiftType`, `notes`.

11. **`notifications` Collection** (`/users/{userId}/notifications/{notificationId}`):
    - **Fields**: `id`, `title`, `body`, `type` (`'bill_due'`, `'budget_over'`, `'goal_milestone'`), `timestamp`, `isRead`.

---

## 4. Complete Feature Breakdown & How It Works

### Feature 1: Core Expense & Income Management (`/features/expense`)
- **Transaction Entry Modal**: Quick amount input, category picker, payment account selector, date-time picker, receipt photo attachment (camera/gallery), and custom tags.
- **Bi-directional Flow**: Supports both Outflows (Expenses) and Inflows (Income / Salary / Cashback / Refund).
- **Soft Delete & Recycle Bin**:
  - Deleting a transaction sets `isDeleted = true` and records `deletedAt`.
  - Recycle bin allows one-tap restoration or permanent deletion.
- **Privacy Masking**: Global toggle instantly masks numeric values to `••••••` across the UI.

### Feature 2: Account & Multi-Wallet Balancing (`/features/account`)
- **Accounts**: Supports Multiple Wallets (Cash, Bank Accounts, bKash, Nagad, Credit Cards).
- **Reassignment & Merging**: When an account is deleted, all past transactions can be reassigned to a default account seamlessly (`delete_account_and_reassign`).

### Feature 3: Smart Category Engine (`/features/category`)
- Pre-seeded default categories with dynamic color palettes and vector icon bindings.
- Users can create, edit, archive, and set budget limits on individual categories.

### Feature 4: Financial Analytics, Insights & Trends (`/features/analytics`, `/features/analysis`)
- **Interactive Multi-Scale Cash Flow Line Chart**:
  - **Dynamic Time Lenses**: `This Month` (1M), `3 Months` (3M), `6 Months` (6M), `This Year` (12M).
  - **Smart Granularity Auto-Switching**:
    - 12M view collapses data into **12 monthly aggregate points** to prevent cluttered labels.
    - Pinching to zoom in (>2.2x) or tapping granularity pills expands points into **Weekly** (~52 points) and **Daily** (~365 points) resolution.
  - **Continuous Pan & Zoom**: High-performance `CustomPainter` with Catmull-Rom cubic bezier smoothing and smooth canvas clipping.
  - **Collision-Free X-Axis**: Bounding-box label positioning algorithm guarantees zero text overlap at any screen density.
  - **Interactive Touch Scrubber & HUD**: Touching the graph drops a vertical gold guideline, lights up glowing dual beacons on both Inflow & Outflow curves, and displays period totals (`[ Jul 2026 ] · ৳350,580.90 In · ৳76,964.91 Out · 76 txns`).
  - **Deep-Dive Itemized Modal**: Tapping the HUD banner opens a bottom modal sheet listing all transactions for that exact day/week/month.
- **Waterfall Cash Flow Staircase**: Continuous step-by-step financial cascade from Gross Inflow $\rightarrow$ Category Outflows $\rightarrow$ Net Surplus.
- **Category Allocation Mix**: Donut chart and progress bars breaking down category percentages with ranking.

### Feature 5: Forward Horizon (Planning & Targets) (`/features/plan`, `/features/loan`, `/features/work_routine`)
Accessible via the bottom navigation `Horizon` tab. Features an interactive **2-Column Uniform Grid** with toggle to List View:
1. **Savings Goals (`GoalsTabView`)**: Target amount, target deadline, saved amount calculated from tagged savings transactions, percentage completion bar.
2. **Trip & Event Plans (`TripPlansTabView`)**: Dedicated budget for vacations or weddings, linking expenses directly via `planId`, remaining budget alert.
3. **Debt & Loans (`LoansTabView`)**:
   - Tracks Borrowed (Payables) vs Lent (Receivables).
   - Proximity warnings when loans are due within 7 days.
4. **Recurring Income & Bills (`RecurringTabView`)**:
   - Automated schedule manager for subscriptions, rent, and utility bills.
   - Calculates 7-day upcoming cash flow requirement (`dueIn7Days`).
5. **Work & Routine (`WorkRoutinePage`)**:
   - Shift, tuition, and work attendance tracker.
   - Computes attended days vs planned days per month with attendance check-in calendar.

### Feature 6: Pure Math & Analysis Engine (`/features/analysis/domain/logic/`)
- **`ExpenseAggregator`**: Daily, weekly, monthly rolling aggregations and income-to-expense ratios.
- **`TrendCalculator`**: Computes percentage changes, rolling averages, and burn-rate velocity.
- **`BudgetCalculator`**: Compares category spend against threshold targets, computing projected end-of-month overrun.
- **`AnomalyDetector`**: Flags abnormal single transactions ($> 2.5\times$ standard deviation of normal category spending).

### Feature 7: Statement Export & Audit (`/features/export`)
- **Vector PDF Generator**: Generates formatted formal bank-like statements with date range, category breakdown tables, and totals.
- **CSV Data Exporter & Importer**: Imports and exports raw transaction spreadsheets compatible with Excel/Google Sheets.

---

## 5. Directory Structure & Key Files

```
expense_tracker/
├── lib/
│   ├── main.dart                          # App entry point & Firebase initialization
│   ├── app.dart                           # Root MaterialApp, Routing & Theme binding
│   ├── injection.dart                     # GetIt dependency injection registry
│   ├── core/
│   │   ├── theme/
│   │   │   └── app_theme.dart             # Editorial colors, typography & shapes
│   │   └── utils/
│   │       └── currency_formatter.dart    # Currency formatting (৳ BDT & global codes)
│   ├── features/
│   │   ├── account/                       # Multi-wallet & account management
│   │   ├── alerts/                        # Smart alert generators & notifications
│   │   ├── analysis/                      # Pure financial calculation engines
│   │   ├── analytics/                     # Insights page, charts, and waterfall
│   │   │   └── presentation/
│   │   │       ├── pages/insights_page.dart
│   │   │       └── widgets/trend_line_chart.dart
│   │   ├── auth/                          # Login, Signup, Google Auth & Profile
│   │   ├── budget/                        # Monthly & Category budget limits
│   │   ├── category/                      # Category CRUD & palette mappings
│   │   ├── expense/                       # Core transactions, ledger & recycle bin
│   │   ├── export/                        # PDF & CSV generation services
│   │   ├── loan/                          # Debt & loan amortization tracking
│   │   ├── notifications/                 # In-app notification inbox
│   │   ├── plan/                          # Savings goals & Trip planner
│   │   │   └── presentation/pages/horizon_page.dart
│   │   ├── recurring_transactions/        # Automated recurring rules & bill forecast
│   │   ├── settings/                      # Preferences, PIN, hide amounts mode
│   │   └── work_routine/                  # Shift & attendance tracking
```

---

## 6. How to Ask Gemini App for Help with this Codebase

When asking Gemini for help with new features or debugging, use prompts structured like:

1. **For Adding Features**:
   > *"I have a Flutter Clean Architecture Expense Tracker app using Cloud Firestore and Provider. I want to add [Feature X] to `lib/features/[feature_name]`. The data model has [fields]. How should I implement the domain entity, repository, provider, and presentation widget matching the Warm Paper & Archival Ink theme?"*

2. **For Chart / Canvas Customization**:
   > *"In `lib/features/analytics/presentation/widgets/trend_line_chart.dart`, the chart uses CustomPainter with `_TrendPoint` models. I want to modify the gesture pan/zoom or add [new indicator]. Here is the mathematical calculation..."*

3. **For Database / Firestore Queries**:
   > *"My Firestore schema stores data in `/users/{userId}/[collection_name]`. How can I write an efficient compound index query or batch transaction for [task]?"*
