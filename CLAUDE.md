# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

**Costly** is a cross-platform personal finance Flutter app (Android/iOS/Web/Desktop) backed by Firebase. It tracks income and expenses with a dashboard, transaction history, analytics, budgets, recurring transactions, savings goals, debt tracking, dark mode, transaction tags, bulk operations, and user profiles with Cloudinary photo uploads.

There is also a standalone Dart backend server in `server/` (Shelf + MongoDB) that is separate from the Flutter app and wired via `BackendService`.

## Commands

### Flutter App (root)

```bash
# Run on a connected device/emulator
flutter run

# Run with Cloudinary credentials (required for profile photo uploads)
flutter run --dart-define=CLOUDINARY_CLOUD_NAME=xxx --dart-define=CLOUDINARY_API_KEY=xxx --dart-define=CLOUDINARY_API_SECRET=xxx

# Run with a custom backend URL (optional, defaults to Android emulator localhost)
flutter run --dart-define=BACKEND_URL=https://your-backend.example.com

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
- `AuthProvider` — authentication state, current user, `changePassword()`, `deleteAccount()`
- `ThemeProvider` — light/dark/system theme mode, persisted in SharedPreferences (`theme_mode` key)
- `TransactionProvider` — income/expense CRUD, filtering, date-range filter, rolling analytics
- `CategoryProvider` — user-defined categories
- `BudgetProvider` — monthly budget limits (overall + per-category), Firestore `budgets` collection
- `RecurringTransactionProvider` — recurring income/expense templates, auto-generates transactions on app open
- `SavingsGoalProvider` — savings goals with contribution tracking, Firestore `savings_goals` collection
- `DebtProvider` — debt/loan tracking (owed by me / owed to me), Firestore `debts` collection

`ThemeProvider` is initialized before `runApp()` in `main()` and passed into `ExpenseTrackerApp` as a constructor argument to avoid a flash-of-wrong-theme.

### Data Layer

- **Firebase Auth** — email/password and Google Sign-In; `changePassword` / `deleteAccount` use `reauthenticateWithCredential`
- **Cloud Firestore** — all transaction and user data via `DatabaseService` (singleton, thin wrapper around `FirebaseFirestore`)
- **Services** — all Firestore logic lives here; providers call these services:
  - `TransactionService` / `CategoryService` / `AuthService`
  - `BudgetService` — CRUD for `budgets` collection (doc ID: `{userId}_{yyyy}_{mm}`)
  - `RecurringTransactionService` — CRUD for `recurring_transactions` collection
  - `SavingsGoalService` — CRUD for `savings_goals` collection
  - `DebtService` — CRUD for `debts` collection
  - `NotificationService` — singleton wrapping `flutter_local_notifications`; daily scheduled reminders + instant budget alerts
  - `BackendService` — singleton HTTP client for the optional Dart/Shelf backend; all calls are best-effort (fail silently)
- **Cloudinary** — profile photo uploads via `CloudinaryService`; credentials injected at build time via `--dart-define`

### Transaction Tags

`TransactionModel` has a `List<String> tags` field stored as a Firestore array. Tags are added via `TagInputField` widget (lib/widgets/tag_input_field.dart) in the add expense/income screens. In `transactions_history.dart`, tapping a `#tag` chip on a transaction tile sets `_tagFilter`; a purple filter indicator appears at the top.

### Dark Mode

`ThemeProvider` stores `ThemeMode` (light/dark/system) in SharedPreferences key `theme_mode`. `MaterialApp` is wrapped in `Consumer<ThemeProvider>` and sets both `theme` and `darkTheme`. The Appearance tile in Profile opens a bottom sheet picker.

### Bulk Operations

In `transactions_history.dart`, `income_list_screen.dart`, and `expense_list_screen.dart`: long-press a transaction tile to enter selection mode. AppBar switches to show count + Select All + Delete actions. `PopScope` intercepts back-press to exit selection mode instead of navigating away.

### Password Change / Account Deletion

`AuthService.changePassword()` and `AuthService.deleteAccount()` re-authenticate with `EmailAuthProvider.credential` before calling Firebase Auth methods. The profile screen shows these in an ACCOUNT section above the logout button. Account deletion also removes the Firestore `users` document.

### Navigation

Named route navigation defined in `main.dart`'s `generateRoute()`. Two transition styles: slide-up (most screens) and fade (auth screens).

### Key Screens

| Route | Screen |
|-------|--------|
| `/splash_screen` | Animated splash, decides auth redirect |
| `/home_dashboard` | Balance summary, recent transactions, quick-add, budget progress card |
| `/transactions_history` | Full history with search/filter/tag-filter/bulk-delete |
| `/analytics` | 3-tab analytics: Expenses / Income / Trends; date-range picker; per-category budget bars |
| `/profile` | User info, currency, photo, appearance (dark mode), account management |
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

Standalone Dart HTTP server using Shelf + shelf_router with MongoDB (`mongo_dart`). Endpoints:
- `GET /health` — liveness check
- `POST /transactions` — store a transaction in MongoDB (mirrored from Firestore via `BackendService.syncTransaction`)
- `GET /analytics/summary?userId=X&month=YYYY-MM` — monthly totals by category from MongoDB
- `GET /transactions/:userId` — list all transactions for a user
- `POST /auth/register` / `POST /auth/login` — standalone auth (not used by the Flutter app which uses Firebase Auth)

`BackendService` (`lib/services/backend_service.dart`) is a singleton HTTP client. `kBackendBaseUrl` defaults to `http://10.0.2.2:8080` (Android emulator local). Override with `--dart-define=BACKEND_URL=...`. All calls have 3–5 second timeouts and fail silently.

## Firebase Setup

The app requires a configured Firebase project. `lib/firebase_options.dart` is auto-generated by FlutterFire CLI and must exist. Google Sign-In requires the debug keystore SHA-1 to be registered in Firebase console.

## Cloudinary Setup

Profile photo uploads use `--dart-define` at build time. See `cloudinary.defines.example` for the three required defines: `CLOUDINARY_CLOUD_NAME`, `CLOUDINARY_API_KEY`, `CLOUDINARY_API_SECRET`. Without them the app builds but uploads fail silently.

## CI Notes

- GitHub Actions workflow in `.github/workflows/github_release_on_tag.yml` — fires only on version tags
- Required GitHub secrets: `DEBUG_KEYSTORE_BASE64`, `CLOUDINARY_CLOUD_NAME`, `CLOUDINARY_API_KEY`, `CLOUDINARY_API_SECRET`
- `versionCode` is set from Unix time (not `run_number`) to guarantee strictly increasing codes across re-tags

## All Features Implemented

All originally planned features are complete:

| # | Feature | Key files |
|---|---------|-----------|
| 1 | Budget Management | `lib/models/budget_model.dart`, `lib/services/budget_service.dart`, `lib/providers/budget_provider.dart`, `lib/screens/budget_settings.dart` |
| 2 | Recurring Transactions | `lib/models/recurring_transaction_model.dart`, `lib/services/recurring_transaction_service.dart`, `lib/providers/recurring_transaction_provider.dart`, `lib/screens/recurring_transactions_screen.dart` |
| 3 | Savings Goals | `lib/models/savings_goal_model.dart`, `lib/services/savings_goal_service.dart`, `lib/providers/savings_goal_provider.dart`, `lib/screens/savings_goals_screen.dart` |
| 4 | Debt Tracking | `lib/models/debt_model.dart`, `lib/services/debt_service.dart`, `lib/providers/debt_provider.dart`, `lib/screens/debts_screen.dart` |
| 5 | Income Analytics | `lib/screens/analytics.dart` (Income tab) |
| 6 | Date Range Filtering | `lib/providers/transaction_provider.dart` |
| 7 | Category Spending Trends | `lib/screens/analytics.dart` (Trends tab) |
| 8 | Notifications | `lib/services/notification_service.dart`, `lib/screens/notification_settings_screen.dart` |
| 9 | Dark Mode | `lib/providers/theme_provider.dart`, `lib/main.dart`, `lib/screens/profile.dart` |
| 10 | Transaction Tags | `lib/models/transaction_model.dart`, `lib/widgets/tag_input_field.dart`, `lib/screens/add_expense.dart`, `lib/screens/add_income.dart`, `lib/screens/transactions_history.dart` |
| 11 | Bulk Operations | `lib/screens/transactions_history.dart`, `lib/screens/income_list_screen.dart`, `lib/screens/expense_list_screen.dart` |
| 12 | Password Change / Account Deletion | `lib/services/auth_service.dart`, `lib/providers/auth_provider.dart`, `lib/screens/profile.dart` |
| 13 | Backend Server Integration | `lib/services/backend_service.dart`, `lib/utils/constants.dart`, `server/bin/server.dart` |
