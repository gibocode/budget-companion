# BudgetCompanion

Bi-weekly paycheck budgeting app built with Flutter. Track monthly and per-paycheck bills, set a monthly budget, and record actual payments.

## What it does

- **Expense list** – Fixed list of bills with amount and frequency (monthly vs per paycheck).
- **Monthly budget** – Set a budget per month; app shows planned vs budget.
- **Payment record** – Per month, record actual amounts and mark bills as paid; totals recompute automatically.

No daily expense tracking—only bill payments aligned to your pay periods.

## Project structure

```
budget_companion/        # Project root
├── lib/                 # App source code
│   └── main.dart        # Entry point
├── docs/                # Documentation
│   ├── PLANNING.md      # Feature plan and data model
│   ├── USER_GUIDE.md    # End-user guide (screens, flows)
│   └── PUBLISHING_ANDROID.md  # Play Store publishing guide
├── android/             # Android platform
├── ios/                 # iOS platform
├── macos/               # macOS platform
└── web/                 # Web platform
```

## Documentation

- **[docs/PLANNING.md](docs/PLANNING.md)** – Full feature plan, data model, screens, and implementation notes.
- **[docs/USER_GUIDE.md](docs/USER_GUIDE.md)** – End-user guide: getting started, all screens (Dashboard, Transactions, Budgets, Accounts, Debts), configuration, security, backup, and tips.
- **[docs/PUBLISHING_ANDROID.md](docs/PUBLISHING_ANDROID.md)** – Step‑by‑step guide for building and publishing the Android app to Google Play.

## Run the app (local development)

```bash
cd ~/flutter/budget_companion
flutter run
```

Pick a device (e.g. Chrome, iOS Simulator, Android Emulator) when prompted.

## Biometrics (app lock)

To use fingerprint or Face ID to unlock the app:

1. **Enable app lock:** Settings → Security → turn on **App lock** and set a 4-digit PIN.
2. **Enable biometrics:** In the same Security section, turn on **Unlock with biometrics** (this option only appears when app lock is on and the device supports biometrics).

**If biometrics don’t work:**

- **Android:** Use a **real device** with at least one fingerprint (or face) enrolled in system Settings. Many emulators don’t support biometrics. The app is configured to use `FlutterFragmentActivity` and an AppCompat theme so the system biometric prompt can run.
- **iOS:** Enroll Face ID (or Touch ID) in **Settings → Face ID & Passcode**. In the iOS Simulator you can use **Features → Face ID → Enrolled** to simulate Face ID.
- Ensure the **"Unlock with biometrics"** toggle is on in Settings → Security (it only shows when app lock is enabled and the device reports biometrics available).

## Status

Active Flutter project following the plan in `docs/PLANNING.md`. See `docs/USER_GUIDE.md` for current behavior and `docs/PUBLISHING_ANDROID.md` for Google Play release steps.
