# Supplied Mobile Reference Review Notes

## `1000052528.png` — Add Income flow

The reference shows an income entry flow with a prominent **Category** control that opens into a tall, full-width selection surface. The flow includes common income sources—**Salary**, **Bonus**, **Pension**, **Rent**, and **Others**—with distinct recognizable symbols. This supports enriching the web app’s default income-source choices while retaining its flatter income taxonomy.

The lower portion combines a readable date/time field with a compact camera affordance, followed by payment-mode chips. For the web refinement, retain the Ink & Ledger light editorial palette rather than copying the dark styling, but keep the reference’s clear control hierarchy: one purpose per row, a large tap target for choices, and category names that are immediately scannable.

## Interpretation limits

These notes cover tiles 1–2 of the tall source screenshot. Subsequent tiles and screenshots will be reviewed in source order where they are relevant to the user’s stated category, schedule, pending-ledger, Settings, and date-picker concerns.

## `1000052527.png` — Add Expense category hierarchy

The expense reference keeps the **parent category** visible as the selected primary control, then opens a separate **“Investments Subcategories”** surface beneath it. The list begins with an intentional **None** choice and then presents related choices such as **Fixed Deposit**, **Recurring Deposit**, and **Mutual Funds**. The interaction confirms the desired order: choose a parent category first, then choose or add a child category in a distinctly scoped second step.

For the web app, the recurring-schedule and transaction forms should follow this staged pattern rather than exposing parent and child selectors simultaneously. Use the existing muted category icon language and warm surfaces rather than the reference’s dark panel, and provide an explicit inline action for creating an allowed child category.

## `1000052526.png` and `1000052525.png` — scoped selector hierarchy

Both references reinforce the same hierarchy with two neighbouring controls: the parent category remains the prominent left control, while the child choice is initially **None** and is only populated after the parent is selected. The open child surface uses a direct heading such as **“Utilities Subcategories”** or **“Healthcare Subcategories”**, making the context unambiguous.

The redesign will translate this into an Ink & Ledger sheet: a parent category selector with an icon and quiet chevron, followed by a separate **Subcategory** field whose copy explains when a parent must be chosen. The child sheet will include a deliberate **No subcategory** option plus the appropriate related choices and a concise **Create subcategory** affordance. This resolves the confusing simultaneous category/subcategory arrangement without reproducing the reference’s heavy dark visual treatment.
