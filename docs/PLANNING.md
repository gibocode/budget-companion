# Budgeting App – Planning Document (Flutter)

## 1. App purpose

A **bi-weekly paycheck budgeting app** that helps you:
- List fixed monthly expenses and split them by pay period **with clear date ranges**
- Track expected vs actual by category; actual is driven by transaction entries (like your per-category sheets)
- Set a monthly budget and see totals (expected, actual, remaining)
- Allocate amounts to accounts (Cash, GCash, BDO, etc.) so you know how much to put where each period
- Track income (expected vs actual) in one place

**Currency:** Philippine Peso (P). All amounts in P.

---

## 2. Spreadsheet → app mapping (from your main sheet)

### 2.1 Main sheet (dashboard summary)

| Your main sheet | In the app |
|-----------------|------------|
| **Expenses:** category list | **Expense list** (master list of categories) |
| **Expected monthly** (pulled from other sheets) | **Expected amount** per expense — from each category’s “expected” (or fixed per expense) |
| **Actual monthly** (auto from other sheets) | **Actual amount** — auto-computed from **transactions** per category (see 2.2) |
| **Schedule: 1st / 2nd** (bi-weekly split) | **Pay period 1 & 2** with **date ranges** (e.g. 1st: 1–14, 2nd: 15–end) so you know which two weeks |
| **Mode of payment** (Online / Cash / Cash+Online) | **Payment mode** per expense — so you know if you need to withdraw cash |
| **Fixed vs variable** (which categories to adjust when budget changes) | **Category type** per expense: **Fixed** or **Variable** — so you know what to adjust when making budget adjustments |
| **Accounts allocation** (Cash, GCash, PayMaya, BDO, …) | **Accounts** + **amount per period** — how much to put in each account for that period |
| **Incomes:** expected vs actual (from other sheets) | **Income list** — expected vs actual, same pattern (can have transaction log or fixed expected) |

### 2.2 Per-category sheets (one category only)

| Your category sheet | In the app |
|---------------------|------------|
| **Daily transaction log** (Date, Amount) | **Transactions** for that expense/category — add date + amount; manual entry lives here |
| **Monthly summary** (Month, Expected, Actual) | **Per month:** expected (budget for category) + actual = sum of transactions that month |
| Main sheet pulls expected & actual from here | Dashboard **expected** = expense’s expected; **actual** = sum of that category’s transactions for the selected month |

So: **one expense/category** = one place to set **expected** (monthly budget for that category) and to **log transactions** (date + amount). The app then shows expected vs actual on the main view and recomputes totals.

### 2.3 How you split the schedule (1st vs 2nd period)

- **Large monthly expenses** you split evenly across the two pay periods.  
  Example: **House Rent P16,000/month** → **P8,000 per paycheck** (P8,000 in period 1, P8,000 in period 2).
- **Smaller amounts** you can assign entirely to one period for convenience.  
  Example: **Fast Offering P400** → pay in the **first two weeks** only (P400 in period 1, P0 in period 2).
- So the app must let you **set the amount per period per expense** (period 1 and period 2). Optional: suggest an even split (e.g. 50/50) that you can change.

### 2.4 Your pain point we address

- You don’t have **date ranges** for the two-week periods (only “1st” / “2nd”). The app will show **pay period 1: e.g. Feb 1–14** and **pay period 2: Feb 15–28** (or configurable), so you know exactly which two weeks you’re budgeting for.

---

## 3. Your current workflow (summary)

| What you do now | In the app |
|-----------------|------------|
| Fixed list of expenses every month | **Expenses** (reusable list) |
| Expected per category (from category sheet) | **Expected amount** per expense; editable per expense or per month |
| Actual per category (from transactions in category sheet) | **Transactions** per expense (date + amount) → **actual** = sum for the month |
| Split: "1st" vs "2nd" (no dates) | **Pay period 1 & 2** with **date ranges** (e.g. 1–14, 15–end) |
| Mode of payment column | **Payment mode** per expense (Online / Cash / Cash+Online) |
| Which categories are fixed vs variable (for budget adjustments) | **Category type** per expense: **Fixed** or **Variable** |
| Account allocation (how much per account per period) | **Accounts** + **allocation** per pay period |
| Income expected vs actual | **Income** list with expected vs actual (from entries or fixed) |
| Mark as paid / recompute | **Paid status** + auto-recompute totals (and optional “date paid”) |

---

## 4. Core features

### 4.1 Expense list (master list)

- **Add / edit / delete** expenses (name, amount, frequency).
- **Two payment frequencies:**
  - **Monthly** – paid once per month (full amount).
  - **Per paycheck** – paid every two weeks (amount is per pay period).
- **Amount:**
  - For *monthly*: one amount (e.g. P16,000 rent).
  - For *per paycheck*: amount per pay period; app computes monthly total (e.g. 2 pay periods → 2×).
- **Mode of payment** (like your column): **Online**, **Cash**, or **Cash/Online** — so you know if you need to withdraw cash.
- **Fixed vs Variable:** each category is marked **Fixed** (e.g. rent, loans, bills — harder to change) or **Variable** (e.g. groceries, miscellaneous — easier to adjust). When you need to make budget adjustments, you can see at a glance which categories are safe to reduce or shift.
- **Optional:** category/tag for filtering or grouping.
- **Optional:** assign to pay period (1st vs 2nd) for ordering.

This list is your "fixed list of expenses every month" that you reuse.

### 4.2 Pay period and calendar (with date ranges)

- **Pay frequency:** every 2 weeks (configurable if you ever change).
- **Pay period date ranges** (solving “I don’t have the dates”):
  - e.g. **Pay period 1:** 1st–14th of month, **Pay period 2:** 15th–end of month (configurable).
  - Or: true 2-week windows (e.g. “Pay period starts on 1st and 15th”).
  - UI always shows the **date range** for each period (e.g. “Feb 1–14”, “Feb 15–28”).
- Used to: show “this pay period” vs “this month”, and to break schedule amounts into 1st vs 2nd with clear dates.

### 4.3 Per-category expected and actual (transaction log)

- **Per expense/category:** a place to set **expected** (monthly budget for that category) and to **log transactions**.
- **Transaction log:** list of **date + amount** (like your category sheet’s left side). Manual entry here.
- **Monthly summary:** for each month, **expected** (fixed or editable) and **actual** = sum of transactions in that month.
- Main dashboard **expected** and **actual** columns are pulled from these (no manual entry on the main view for actuals).

### 4.4 Monthly budget and schedule (1st / 2nd)

- **One budget per month** (e.g. February 2026): total budget amount (your target).
- **Planned (expected) total** = sum of all expenses’ expected for that month.
- **Schedule (bi-weekly):** for each expense, you set **amount in Pay period 1** and **amount in Pay period 2** (with date ranges shown). Not necessarily 50/50:
  - **Even split:** e.g. House Rent P16,000 → P8,000 + P8,000.
  - **One period only:** e.g. Fast Offering P400 → P400 in first two weeks, P0 in second (smaller amounts can be paid in one period).
  - Optional: app can suggest “Split evenly” (half in 1st, half in 2nd) that you can edit.
  - Totals per period at bottom (Schedule 1st total, Schedule 2nd total).
- **Display:** planned vs budget → over/under; actual vs planned; remaining.

### 4.5 Account allocation

- **Accounts:** list of accounts (e.g. Cash, GCash, PayMaya, BDO, PSBank, BPI, Others) — configurable.
- **Per pay period:** amount to allocate to each account (so you know how much to put where).
- **Totals:** sum of allocations for period 1 = schedule total for period 1; same for period 2. Avoids formula errors like #VALUE! (app validates numbers).

### 4.6 Income

- **Income categories** (e.g. Salary): **expected** and **actual** per month.
- Expected/actual can come from a simple fixed value or from a small transaction log per income source (same pattern as expenses if needed).
- Shown on main dashboard (right side like your sheet).

### 4.7 Summary and totals (main dashboard)

- **This month – expenses:**
  - Total expected (planned)
  - Total actual (from transaction logs)
  - Remaining (expected − actual)
  - Versus monthly budget (over/under)
  - Schedule 1st / 2nd totals with **date ranges** shown
- **This month – income:** expected vs actual.
- **Account allocation:** amounts per account for current (or selected) pay period.

---

## 5. Data model (main entities)

- **Expense (template)**
  - id, name, amount, frequency (monthly | per_paycheck), **paymentMode** (online | cash | cash_online), **budgetType** (fixed | variable), category (optional), order
- **ExpenseExpected** (optional: if expected can vary by month)
  - expenseId, year, month, amount — else use expense.amount as default expected
- **Transaction** (per-category log, like your category sheet)
  - id, expenseId, date, amount — actual for a category = sum of transactions in that month
- **MonthlyBudget**
  - id, year, month, budgetAmount
- **ScheduleAmount** (bi-weekly split per expense per month)
  - expenseId, year, month, period (1 | 2), amount — 1st and 2nd period amounts; UI shows date ranges
- **Account**
  - id, name (e.g. Cash, GCash, BDO), order
- **AccountAllocation** (how much to put in each account per period)
  - accountId, year, month, period (1 | 2), amount
- **Income (template)**
  - id, name (e.g. Salary)
- **IncomeRecord** (expected/actual per month)
  - incomeId, year, month, expectedAmount, actualAmount — or separate IncomeTransaction like expenses
- **PayPeriodConfig** (settings)
  - e.g. period1EndDay (14), or periodStartDays [1, 15] — to compute and show date ranges (e.g. "Feb 1–14", "Feb 15–28")

Computed:
- Monthly **planned** = sum of expenses' expected (or 2× per-paycheck amount).
- Monthly **actual** = sum over expenses of (sum of transactions for that expense in that month).
- **Remaining** = planned − actual; vs budget = budgetAmount − planned (or − actual).

---

## 6. Screens and navigation (suggested)

1. **Home / Dashboard** (like your main sheet)
   - Year + month selector.
   - **Expenses:** list with Expected, Actual, Schedule (1st / 2nd with date ranges), Mode of payment, **Fixed/Variable**; totals at bottom. Filter or sort by variable when looking for categories to adjust.
   - **Account allocation:** amounts per account for period 1 and period 2; totals match schedule.
   - **Income:** expected vs actual.
   - Quick links: Expenses list, Month view, Settings.

2. **Expenses (list)**
   - All expenses: name, amount, frequency, payment mode, **fixed/variable**, category; add/edit/delete; reorder optional. Show fixed vs variable so you know what to adjust when budgeting.
   - Tap expense → **Expense detail:** set expected (if per-month), **transaction log** (date + amount), monthly expected/actual summary.

3. **Month view / Payment record**
   - Select month → table: expense, expected, actual (from transactions), paid toggle, date paid, notes.
   - Schedule 1st/2nd with date ranges; totals; account allocation for that month.

4. **Monthly budget**
   - Select month → set total budget; see planned vs budget.

5. **Accounts**
   - List of accounts (Cash, GCash, BDO, …); add/edit/delete. Used in allocation.

6. **Settings**
   - Pay period date ranges (e.g. 1–14 and 15–end, or custom).
   - Currency (P), first day of month.

---

## 7. User flows

- **Setup (once):** Add expenses (name, amount, frequency, payment mode). Add accounts. Set pay period dates (e.g. 1–14, 15–end). Optionally set first month's budget and expected per expense.
- **Each month:** Set budget; set or confirm expected per expense; set schedule (1st/2nd) amounts; set account allocation per period.
- **As you pay:** Open expense → add transaction (date + amount) or mark paid in month view. Dashboard actual and totals update.
- **Check dashboard:** See expected vs actual, schedule with date ranges, account allocation, income; adjust as needed.
- **Ongoing:** Edit expense list and accounts when things change.

---

## 8. Features to add later (v2)

- Copy previous month's budget (and optionally schedule/allocations) to next month.
- Charts: planned vs actual over months.
- Export month/year to CSV.
- Notifications: "Bills due this pay period" or "X still unpaid".
- Support 3 pay periods in a month (e.g. 3 paychecks).
- Link expense to specific pay period (e.g. "from 1st paycheck").

---

## 9. Flutter-specific notes

- **State:** One source of truth for expenses, transactions, accounts, budgets (e.g. Provider, Riverpod, or Bloc).
- **Storage:** Local first (e.g. `shared_preferences` + JSON or `sqflite`/`isar`/`hive`). No backend required.
- **Offline-first:** Optional sync later if you want multiple devices.
- **Platform:** Mobile (iOS/Android) first; desktop/web later if needed.

---

## 10. Next steps

1. Confirm this plan matches your main sheet and category sheets (expected/actual from transactions, date ranges, mode of payment, account allocation).
2. Decide minimal v1: e.g. expenses + transactions (so actual is computed) + pay period date ranges + dashboard with schedule and totals; then add account allocation and income.
3. Implement: data model + local storage → Expenses list + expense detail with transaction log → pay period config and date range display → Dashboard (expected, actual, schedule, totals) → Monthly budget → Account allocation → Income.
