# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

**Costly** is a cross-platform personal finance Flutter app (Android/iOS/Web/Desktop) backed by Firebase. It tracks income and expenses with a dashboard, transaction history, analytics, budgets, recurring transactions, savings goals, debt tracking, and user profiles with Cloudinary photo uploads.

There is also a standalone Dart backend server in `server/` (Shelf + MongoDB) that is separate from the Flutter app.

## Commands

### Flutter App (root)

```bash
# Run on a connected device/emulator
flutter run

# Run with Cloudinary credentials (required for profile photo uploads)
flutter run --dart-define=CLOUDINARY_CLOUD_NAME=xxx --dart-define=CLOUDINARY_API_KEY=xxx --dart-define=CLOUDINARY_API_SECRET=xxx

# Build release APK (same dart-defines apply)
flutter build apk --release

# Run tests
flutter test

# Run a single test file
flutter test test/widget_test.dart

# Lint
flutter analyze
```

### Dart Backend Server (`server/`)

```bash
cd server
dart run bin/server.dart
```

### Release (CI)

Releases are triggered by pushing a version tag — CI builds a signed APK and publishes a GitHub Release automatically:

```bash
git tag v1.3.0
git push origin v1.3.0
```

## Architecture

### State Management

Uses `provider` with `ChangeNotifier` providers registered at app root (`main.dart`):
- `AuthProvider` — authentication state, current user
- `TransactionProvider` — income/expense CRUD, filtering, date-range filter, rolling analytics
- `CategoryProvider` — user-defined categories
- `BudgetProvider` — monthly budget limits (overall + per-category), Firestore `budgets` collection
- `RecurringTransactionProvider` — recurring income/expense templates, auto-generates transactions on app open
- `SavingsGoalProvider` — savings goals with contribution tracking, Firestore `savings_goals` collection
- `DebtProvider` — debt/loan tracking (owed by me / owed to me), Firestore `debts` collection

### Data Layer

- **Firebase Auth** — email/password and Google Sign-In
- **Cloud Firestore** — all transaction and user data via `DatabaseService` (singleton, thin wrapper around `FirebaseFirestore`)
- **Services** — all Firestore logic lives here; providers call these services:
  - `TransactionService` / `CategoryService` / `AuthService`
  - `BudgetService` — CRUD for `budgets` collection (doc ID: `{userId}_{yyyy}_{mm}`)
  - `RecurringTransactionService` — CRUD for `recurring_transactions` collection
  - `SavingsGoalService` — CRUD for `savings_goals` collection
  - `DebtService` — CRUD for `debts` collection
  - `NotificationService` — singleton wrapping `flutter_local_notifications`; daily scheduled reminders + instant budget alerts
- **Cloudinary** — profile photo uploads via `CloudinaryService`; credentials injected at build time via `--dart-define`

### Navigation

Named route navigation defined in `main.dart`'s `generateRoute()`. Two transition styles: slide-up (most screens) and fade (auth screens).

### Key Screens

| Route | Screen |
|-------|--------|
| `/splash_screen` | Animated splash, decides auth redirect |
| `/home_dashboard` | Balance summary, recent transactions, quick-add, budget progress card |
| `/transactions_history` | Full history with search/filter |
| `/analytics` | 3-tab analytics: Expenses / Income / Trends; date-range picker; per-category budget bars |
| `/profile` | User info, currency, photo; links to all feature screens |
| `/budget_settings` | Set overall + per-category monthly spending limits |
| `/recurring_transactions` | Manage repeating income/expense templates (daily/weekly/monthly) |
| `/savings_goals` | Create and contribute to savings goals with progress bars |
| `/debts` | Track money owed by you or to you; record payments |
| `/notification_settings` | Toggle daily reminder, pick time, test notifications |

### Analytics Screen (3 tabs)

- **Expenses tab** — 6-month bar chart, category donut + legend, top-categories list with budget bars
- **Income tab** — 6-month income bar chart, income vs expenses comparison bars, income-by-source donut
- **Trends tab** — per-category 6-month bar charts
- **Date range filter** — tap subtitle in AppBar to pick custom range; `TransactionProvider.setCustomDateRange()` / `clearCustomDateRange()`; filtered getters: `filteredTransactions`, `filteredTotalExpenses`, `filteredTotalIncome`, `filteredExpensesByCategory`, `filteredIncomeByCategory`

### Notifications

`NotificationService` is a singleton initialized in `main()` before `runApp()`. Uses `flutter_local_notifications` + `timezone`. Channels:
- `costly_general` — instant alerts (budget exceeded)
- `costly_daily` — daily scheduled reminder (ID 1, `matchDateTimeComponents: time`)

Settings persisted in `SharedPreferences` keys: `notif_daily_enabled`, `notif_daily_hour`, `notif_daily_minute`.

Android manifest has the required `ScheduledNotificationReceiver` and `ScheduledNotificationBootReceiver`.

### Recurring Transactions

`RecurringTransactionProvider.fetchAndProcess(userId)` is called from `HomeDashboard.initState()`. It checks each active recurring template: if `nextDueDate` ≤ today, a real transaction is created and `nextDueDate` is advanced by the frequency interval.

### Backend Server (`server/`)

Standalone Dart HTTP server using Shelf + shelf_router with MongoDB (`mongo_dart`). Runs independently of the Flutter app; not required for the app's core features (which use Firestore directly).

## Firebase Setup

The app requires a configured Firebase project. `lib/firebase_options.dart` is auto-generated by FlutterFire CLI and must exist. Google Sign-In requires the debug keystore SHA-1 to be registered in Firebase console.

## Cloudinary Setup

Profile photo uploads use `--dart-define` at build time. See `cloudinary.defines.example` for the three required defines: `CLOUDINARY_CLOUD_NAME`, `CLOUDINARY_API_KEY`, `CLOUDINARY_API_SECRET`. Without them the app builds but uploads fail silently.

## CI Notes

- GitHub Actions workflow in `.github/workflows/github_release_on_tag.yml` — fires only on version tags
- Required GitHub secrets: `DEBUG_KEYSTORE_BASE64`, `CLOUDINARY_CLOUD_NAME`, `CLOUDINARY_API_KEY`, `CLOUDINARY_API_SECRET`
- `versionCode` is set from Unix time (not `run_number`) to guarantee strictly increasing codes across re-tags

## Remaining Features (not yet implemented)

See `docs/superpowers/plans/2026-04-11-remaining-features.md` for the implementation plan.

| # | Feature | Status |
|---|---------|--------|
| 9 | Dark Mode | Pending |
| 10 | Transaction Tags | Pending |
| 11 | Bulk Operations | Pending |
| 12 | Password Change / Account Deletion | Pending |
| 13 | Wire up Backend Server | Pending |
