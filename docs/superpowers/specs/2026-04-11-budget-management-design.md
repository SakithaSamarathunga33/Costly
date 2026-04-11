# Budget Management — Design Spec
_Date: 2026-04-11_

## Overview
Add per-category and overall monthly budget tracking to Costly. Users set spending limits; the app shows progress bars and warns when approaching or exceeding limits.

## Data Layer

**Firestore collection:** `budgets`
**Document ID:** `{userId}_{YYYY}_{MM}` (e.g. `abc123_2026_04`)

```
{
  userId: string,
  year: int,
  month: int,
  overall: double,           // 0 = no overall limit set
  categories: {
    "Food": 200.0,
    "Transport": 100.0,
    ...
  }
}
```

- One document per user per month.
- Missing category key = no limit set for that category.
- `overall: 0` means no overall limit.

## New Files

| File | Purpose |
|------|---------|
| `lib/models/budget_model.dart` | BudgetModel with fromMap/toMap |
| `lib/services/budget_service.dart` | Firestore CRUD for budgets |
| `lib/providers/budget_provider.dart` | ChangeNotifier; exposes current month budget, computed % used per category |
| `lib/screens/budget_settings.dart` | Screen to set overall + per-category limits |

## Provider API (BudgetProvider)

```dart
BudgetModel? currentBudget         // budget for selected month
double overallUsedPercent          // totalExpenses / overall * 100
Map<String, double> categoryUsed   // category → spent amount (from TransactionProvider)
Map<String, double> categoryPercent // category → % of budget used
Future<void> fetchBudget(String userId, DateTime month)
Future<void> saveBudget(BudgetModel budget)
```

BudgetProvider reads spending totals from TransactionProvider (injected via MultiProvider at app root).

## UI Changes

### Budget Settings Screen (`/budget_settings`)
- Overall monthly limit field (text input, numeric)
- List of expense categories with a limit field each (empty = no limit)
- Save button → calls `BudgetProvider.saveBudget()`
- Accessible from Profile screen via "Budget Settings" tile

### Dashboard
- New "Budget" card below the income/expense summary row
- Shows: overall budget bar (spent / limit), color: green → orange (>70%) → red (>90%)
- Tapping card navigates to `/budget_settings`
- Hidden if no overall budget set

### Analytics Screen
- Under each category in the pie legend: small linear progress bar showing category spend vs limit
- Hidden for categories with no limit set

## Navigation
Add route `/budget_settings` in `main.dart` `generateRoute()`.

## Provider Registration
Register `BudgetProvider` in `main.dart` alongside existing providers.

## Error Handling
- Save failures show a top toast (existing `TopToast` utility)
- If budget doc missing for month, treat as all-zero (no limits)

## Out of Scope
- Budget carry-over between months
- Push notifications for budget alerts (covered in Feature 8: Notifications)
- Income budgets
