# Budget Companion — User Guide

**Budget Companion** is a budgeting app that helps you plan and track bills and income around your **pay periods** (e.g. bi-weekly or every two weeks). You set expected amounts per expense and income, then record actual transactions. The app shows how you’re doing versus your budget and keeps everything in sync with your pay schedule.

**Currency:** Philippine Peso (₱).

---

## Table of contents

1. [Getting started](#1-getting-started)
2. [App navigation](#2-app-navigation)
3. [Configuration (set up first)](#3-configuration-set-up-first)
4. [Dashboard](#4-dashboard)
5. [Transactions](#5-transactions)
6. [Budgets](#6-budgets)
7. [Accounts](#7-accounts)
8. [Debts](#8-debts)
9. [Settings](#9-settings)
10. [Security and backup](#10-security-and-backup)
11. [Tips and troubleshooting](#11-tips-and-troubleshooting)

---

## 1. Getting started

### First launch

- When you open the app, you go straight to the **Dashboard**.
- If **App lock** is enabled (see [Security](#10-security-and-backup)), you’ll see the **lock screen** first: enter your PIN or use fingerprint/Face ID if enabled.

### What to set up first

For the app to be most useful, configure these in order:

1. **Pay period** — When your first pay period starts and how long each period is (e.g. 14 days).  
   **Settings → Configuration → Pay period**
2. **Categories** — Expense and income categories (e.g. Rent, Utilities, Salary).  
   **Settings → Configuration → Categories**
3. **Expenses** — Your recurring bills (from the **Budgets** tab: add expenses and set amounts).
4. **Accounts** (optional) — Cash or bank/e-wallet accounts if you want to track balances by account.

You can still use the app without a pay period; it will fall back to simple calendar-month ranges.

---

## 2. App navigation

The main screen has **six tabs** in the bottom bar:

| Tab | Purpose |
|-----|--------|
| **Dashboard** | Overview: expected vs actual, remaining, charts, and quick views of expenses, budgets, and accounts for the selected month. |
| **Transactions** | List of all transactions for the selected month. Add, edit, or remove actual income and expense entries. |
| **Budgets** | Plan expected amounts per expense and income, by pay period. Copy budgets between periods. |
| **Accounts** | Manage accounts (e.g. Cash, Bank, E-wallet) and see planned/actual amounts by period. |
| **Debts** | Track debts: monthly payment, months left, next due date, and “fully out of debt” date. |
| **Settings** | Configuration, security, backup, and app info. |

- **Month selector** — On Dashboard, Transactions, Budgets, and Accounts you can change the month with the **left/right arrows** or by swiping left/right.
- **Pull to refresh** — On most lists, pull down to refresh data from storage.

---

## 3. Configuration (set up first)

Go to **Settings**, then use the **Configuration** section.

### 3.1 Pay period

**Settings → Pay period**

- **First period start date**  
  The **first day** of your first pay period (e.g. your first payday). Tap to open the date picker and set it. This anchors all future periods.

- **Interval**  
  Length of each period in **days** (e.g. **14** for bi-weekly). Use the **−** and **+** buttons (range 7–31 days).

- **Example**  
  The screen shows a sample month with labels like “P1” and “P2” and their date ranges so you can confirm the periods match your schedule.

- **Month reporting**  
  When you view data “by month,” the app can include pay periods in a month in three ways:
  - **By period start** — A period belongs to the month where it **starts**.
  - **By period end (payroll at close)** — A period belongs to the month where it **ends**.
  - **Accrual (prorate by day overlap)** — Periods that overlap the month are included and amounts are prorated by how many days fall in that month.

Choose the option that matches how you think about “this month’s” pay (e.g. payday at end of period → “By period end”).

### 3.2 Categories

**Settings → Categories**

Categories group your expenses and income (e.g. Rent, Utilities, Salary). You’ll assign each **expense** and **income** item to a category.

- **Tabs:** **Expense** and **Income** — Add and edit categories for each type.
- **Add category:** Tap the **+** button. Choose **Expense** or **Income** (from the active tab), enter a name, pick an **icon** and **color**, and optionally set a **parent** to make it a subcategory.
- **Edit:** Tap a category to change name, icon, color, or parent.
- **Delete:** Swipe a category left and confirm (or use delete in the edit sheet). Deleting a category does not delete expenses/income that used it; they may show as “Uncategorized” or need to be reassigned elsewhere.

Create at least a few expense and income categories before adding expenses and budgets.

---

## 4. Dashboard

The Dashboard gives a **single-month** overview and charts.

### 4.1 Month selector

At the top, use **&lt;** and **&gt;** to change the month (or swipe left/right). The rest of the Dashboard applies to this selected month.

### 4.2 Warnings

If your **budgeted expenses** are higher than **budgeted income**, or you’ve **spent more** than you budgeted, the app shows a short warning message so you can adjust.

### 4.3 Summary cards

Four cards show, for the selected month:

- **Expected Expenses** — Total **budgeted expenses** for the selected month’s included pay periods (based on your pay period settings), or the calendar month when no pay period is configured.
- **Actual Expenses** — Total **actual expense transactions** for those same pay periods (or month). Shown in green while at or under the expected amount, red when over.
- **Remaining Expenses** — Expected expenses minus actual expenses (positive = under budget, negative = over).
- **Actual Budget** — Total **actual income transactions** for the selected month’s included pay periods (or calendar month when no pay schedule is configured).

### 4.4 Charts

- **Expenses this month** — Pie chart of expense transactions by category (or expense item), with a legend and percentages.
- **Last 6 months trend** — Line chart of expense and income over the last six months.
- **Monthly comparison** — Bar chart comparing expenses and income for the last six months.

### 4.5 Tabs: Expenses, Budgeted, Incoming

Below the charts, three sub-tabs show details for the **same selected month**:

- **Expenses** — Actual expense transactions by pay period (P1, P2, etc.) with subtotals, using the configured pay schedule.
- **Budgeted** — Budgeted amounts (expected expenses and income) by pay period.
- **Incoming** — Amounts per account by period, focused on incoming funds and allocations.

Use these to see at a glance how much is planned vs spent in each period and per account.

---

## 5. Transactions

**Transactions** are the **actual** income and expenses you record (e.g. “Paid rent ₱10,000 on March 5”).

### 5.1 Viewing transactions

- Select the **month** with the arrows or swipe.
- The list shows all transactions for that month. Each row shows:
  - Name (from the linked budget/expense or income),
  - Amount,
  - Optional category/type indicator.
- **Net for the month** (income − expenses) is shown at the top.

### 5.2 Adding a transaction

- Tap the **+** (FAB) button.
- In the sheet:
  - Choose **Expense** or **Income**.
  - Pick the **budget** (or expense/income item) this transaction belongs to.
  - Enter **amount** and optional **date** and **notes**.
- Tap **Add** (or **Save**). The transaction appears in the list and is included in Dashboard totals and charts.

### 5.3 Editing a transaction

- Tap a transaction in the list.
- Change amount, date, notes, or the linked budget/item, then tap **Save**.

### 5.4 Removing a transaction

- Swipe the transaction **left** and confirm **Remove**. The transaction is deleted and totals update. This cannot be undone.

### 5.5 Empty state

If there are no transactions for the selected month, the app shows a short message and suggests tapping **+** to add one.

---

## 6. Budgets

**Budgets** are your **planned** amounts per expense and income for each pay period (and month).

### 6.1 Budget screen layout

- **Month** — Change with arrows or swipe.
- **Expenses / Income** — Segmented control: switch between planning **expenses** and **income**.
- **Pay period** — If you’ve set a pay period (see [Pay period](#31-pay-period)), you’ll see periods (e.g. P1, P2) for that month. Tap a period to focus it; tap again to clear and see all.
- **Copy budgets** — Use the **copy** icon in the app bar to copy budgets from one period to another (e.g. copy last month’s plan to this month).

### 6.2 Adding a budget item

- Tap **+**.
- Choose whether it’s an **expense** or **income** budget.
- Select the **expense** or **income** item (from your Expenses/Income list) and the **amount** you expect for that period (or month).
- Optionally give it a **custom name** and link an **account**.
- Save. The item appears in the budget list and feeds into Dashboard “Expected” and related totals.

### 6.3 Editing and deleting

- Tap a budget row to edit amount, name, account, or the linked expense/income.
- Delete via the sheet or the delete action; confirm when asked.

### 6.4 Warning

If **budgeted expenses** for the month are higher than **budgeted income**, the app shows a warning so you can rebalance.

---

## 7. Accounts

**Accounts** represent where you hold money: e.g. **Cash**, **Bank**, **E-wallet**.

### 7.1 What accounts are used for

- You can assign **budget amounts** to accounts (e.g. “Rent from Checking”).
- The **Accounts** tab (and the Accounts section on the Dashboard) show **total balance** and per-period planned amounts by account.
- **Account type** can be **Cash** (physical) or **Online** (bank, e-wallet).

### 7.2 Adding an account

- On the **Accounts** tab, tap **+**.
- Enter **name** (e.g. “Checking”, “Wallet”). Optionally set **type** (Cash/Online), **color**, and **starting balance**.
- Save.

### 7.3 Editing and deleting

- Tap an account to edit name, type, color, or balance.
- You can delete an account; confirm in the dialog. This does not delete transactions or budgets, but they may no longer be tied to that account.

### 7.4 Total balance

The app shows a **Total balance** (sum of all account amounts). Use this as a simple view of “how much I have” across accounts when you keep balances updated.

---

## 8. Debts

**Debts** track loans or payments you’re paying off (e.g. car loan, BNPL).

### 8.1 Debt list

- Debts are grouped by **category** (or “Uncategorized”).
- For each debt you see: **name**, **monthly amount**, **months remaining**, **remaining total**, **next due date**, and **expected paid-off date**.

### 8.2 Overview card

At the top:

- **Monthly total** — Sum of monthly payments for all active debts.
- **Total remaining** — Sum of remaining totals.
- **Fully out of debt by** — The **latest** expected paid-off date among all active debts. If you have no active debts, it shows “You’re debt-free.”

### 8.3 Adding a debt

- Tap **+**.
- Enter **name**, **category** (optional), **monthly amount** (₱), **months remaining**, and **next due date** (next payment date).
- Save. The app computes remaining total and expected paid-off date.

### 8.4 Adjusting months remaining

- On each debt card, use **−** and **+** next to “X mo” to decrease or increase **months remaining**. Useful when you make an extra payment or need to extend the term.

### 8.5 Marking complete / unmarking

- **Mark complete** — Long-press a debt and choose to mark it complete. It moves to a “Completed” list and no longer counts toward monthly total or “fully out of debt” date.
- **Unmark** — Long-press a completed debt to move it back to active and set months remaining to 1 so you can edit again.

### 8.6 Editing and deleting

- Tap a debt to edit name, category, monthly amount, months remaining, or next due date.
- Delete from the edit sheet; confirm when asked.

---

## 9. Settings

**Settings** holds configuration, security, backup, and general info.

### 9.1 Configuration

- **Pay period** — First period start date, interval (days), and month reporting policy. See [Pay period](#31-pay-period).
- **Categories** — Expense and income categories. See [Categories](#32-categories).

### 9.2 Security

- **App lock** — Turn on to require a **4-digit PIN** when opening the app (and when returning from background). When enabled, you can:
  - **Change PIN** — Set a new PIN (current PIN required).
  - **Unlock with biometrics** — If your device supports it, use fingerprint or Face ID to unlock instead of (or in addition to) the PIN.
- **Biometrics** — Only visible when app lock is on and the device supports biometrics. Turn on to use fingerprint/Face ID to unlock.

### 9.3 General

- **Currency** — Display only; the app uses **Philippine Peso (₱)**.

### 9.4 Data

- **Google Drive backup** — Link a Google account and use **Back up now** to upload your data to Google Drive (app data folder). Use **Restore** to replace local data with the last backup.  
  - **Back up** is only available when there is data (e.g. at least one account, transaction, budget, or debt).  
  - If **App lock** is on, you must enter your PIN or use biometrics before each backup or restore.

---

## 10. Security and backup

### 10.1 App lock (PIN)

- **Turn on:** Settings → Security → **App lock** → follow the flow to set a 4-digit PIN.
- **Unlock:** Each time you open the app (or return from background), enter the PIN or use biometrics if enabled.
- **Turn off:** Settings → Security → App lock → Off, then confirm and enter your PIN when asked.
- **Change PIN:** Settings → Security → **Change PIN** (only when app lock is on). You’ll enter the current PIN, then the new one twice.

### 10.2 Biometrics

- **Requirement:** App lock must be **on** and the device must support fingerprint or Face ID.
- **Enable:** Settings → Security → **Unlock with biometrics** → On.
- **Behavior:** When you open the app or return from background, the app will prompt for fingerprint/Face ID (or PIN if you cancel or biometrics fail).
- **Note:** Biometrics use the same data as your device lock (e.g. phone unlock). The app does not store any biometric data.

### 10.3 Google Drive backup

- **Link account:** Settings → Data → **Google Drive backup** → **Link Google account** and sign in with Google.
- **Back up now:** Tap **Back up now** → confirm → (if app lock is on) unlock with PIN or biometrics → backup runs. Your data is uploaded to your Google Drive app data folder (not visible in the main Drive file list).
- **Restore:** Tap **Restore** → confirm the warning (local data will be overwritten) → (if app lock is on) unlock → restore runs. **Restart the app** after restore so all data reloads.
- **Last backup / restore:** The screen shows the last backup and last restore time when available.

---

## 11. Tips and troubleshooting

### General

- **Set pay period first** — For bi-weekly or custom periods, configure **Pay period** in Settings so Dashboard, Budgets, and Accounts show correct P1/P2 (or more) periods.
- **Categories before expenses** — Create **Categories** (Settings → Categories), then add **Expenses** and **Income** items (from Budgets/expense management) so everything can be categorized.
- **Pull to refresh** — If something looks out of date, pull down on the list or dashboard to refresh.

### Month navigation

- On **Dashboard**, **Transactions**, **Budgets**, and **Accounts**, use the **&lt;** **&gt;** arrows or **swipe left/right** to change month. The selected month is shared where applicable so you stay in sync.

### Backups

- **Back up** before major changes or before restoring, so you always have a recent copy.
- **Restore** replaces all local data; there is no “merge.” After restore, restart the app.

### Biometrics

- Use a **real device** with fingerprint or face enrolled; many emulators don’t support biometrics.
- If the biometric prompt doesn’t appear or keeps asking, ensure **Unlock with biometrics** is on in Settings → Security and that app lock is on.

### Data and storage

- All data is stored **on the device**. Backup to Google Drive is optional and uses your Google account; the backup file is in the app’s private Drive area.

---

## Summary

| Goal | Where to go |
|------|-------------|
| See monthly overview and charts | **Dashboard** |
| Record actual payments/income | **Transactions** → + |
| Plan expected amounts per period | **Budgets** |
| Track bank/cash accounts | **Accounts** |
| Track loans and payoff date | **Debts** |
| Set pay period and categories | **Settings** → Configuration |
| Lock the app with PIN/biometrics | **Settings** → Security |
| Back up or restore data | **Settings** → Data → Google Drive backup |

---

*Budget Companion · User Guide · © Budget Companion*
