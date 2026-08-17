# Refinement Checklist: Category Hierarchy, Caps & Navigation

- [x] Replace isolated screen values with unified local records and derived calculations.
- [x] Add category hierarchy (`parent_id`, `type`, one level deep for expense categories, flat list for income).
- [x] Enforce category caps (`maxExpenseCategories: 8`, `maxIncomeCategories: 6`, `maxSubcategoriesPerCategory: 5`) with UI counters and disabling "+ Add category/subcategory".
- [x] Roll up subcategory spend to parent categories automatically for budgets and insights.
- [x] Update Settings → Edit categories into separate Expense and Income sections with expandable top-level rows and subcategory management.
- [x] Update transaction form category picker to a flat searchable list showing path (`"Food & Dining → Restaurants"`).
- [x] Connect donut chart slice clicks to drill into that category's subcategory breakdown.
- [x] Remove top-right "+ Add transaction" action and rely solely on the bottom/ledger navigation add button.
- [x] Verify build success (`pnpm check`) and responsive behavior.
