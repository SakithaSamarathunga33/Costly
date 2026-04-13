# Design: Dark Theme Fix + Recurring Transaction Duration

**Date:** 2026-04-13  
**Status:** Approved

---

## 1. Dark Theme Fix

### Problem
All screens and widgets hardcode colors (e.g., `Color(0xFFF8F6FC)`, `Colors.white`, `Color(0xFF2D2D2D)`). The `darkTheme` defined in `main.dart` is never applied because widgets never read from `Theme.of(context)`.

### Approach
Replace hardcoded structural colors with `Theme.of(context).colorScheme` tokens in every file under `lib/screens/` and `lib/widgets/`.

### Color Mapping

| Hardcoded value | Token replacement |
|---|---|
| `Color(0xFFF8F6FC)`, `Color(0xFFF5F5F5)` (page bg) | `colorScheme.surface` |
| `Colors.white` (cards, sheets) | `colorScheme.surfaceContainerLow` |
| `Color(0xFF2D2D2D)` (primary text) | `colorScheme.onSurface` |
| `Color(0xFF2D2D2D).withValues(alpha: 0.45)` (secondary text) | `colorScheme.onSurfaceVariant` |
| AppBar `backgroundColor` | `colorScheme.surface` |
| Input field `fillColor` | `colorScheme.surfaceContainerHighest` |
| Bottom sheet / modal background | `colorScheme.surface` |
| Box shadow `Colors.black.withValues(alpha: 0.04)` | keep but reduce opacity in dark (use `colorScheme.shadow`) |

### What stays hardcoded
- Brand purple `Color(0xFF5D3891)` — already seeded into both `theme` and `darkTheme` via `ColorScheme.fromSeed`; use `colorScheme.primary` where appropriate but the const is fine for icon/button accents.
- Income green `Color(0xFF2ECC71)` and expense red `Color(0xFFE74C3C)` — semantic status colors, not structural.

### Scope
All files in:
- `lib/screens/` (18 files)
- `lib/widgets/` (all widget files)

### Pattern per file
In each `build()` method, resolve colors at the top:
```dart
final cs = Theme.of(context).colorScheme;
// then use cs.surface, cs.onSurface, etc.
```

For `const` widgets that can't take context, convert to non-const or pass colors as parameters.

---

## 2. Recurring Transaction Duration

### Problem
Recurring transactions run indefinitely with no way to set an end. Users need a time-bounded option (e.g., "pay for 3 months then stop").

### Model Change: `RecurringTransactionModel`

Add field:
```dart
final DateTime? endDate; // null = no end
```

- `fromMap`: read `endDate` as Firestore `Timestamp?`, null if missing.
- `toMap`: write `endDate` as `Timestamp` if non-null, omit if null.
- `copyWith`: include `endDate` (use sentinel pattern for nullable override).

### Form Change: `_AddRecurringSheet`

Add a **Duration** `DropdownButtonFormField<String>` between Frequency and Start Date.

Options (value → label):
| Value | Label |
|---|---|
| `'3m'` | 3 months *(default)* |
| `'6m'` | 6 months |
| `'12m'` | 12 months |
| `'none'` | No end |

State variable: `String _duration = '3m'`

On save, compute `endDate`:
```dart
DateTime? endDate;
if (_duration != 'none') {
  final months = int.parse(_duration.replaceAll('m', ''));
  endDate = DateTime(_startDate.year, _startDate.month + months, _startDate.day);
}
```

Pass `endDate` to `provider.add(...)`.

### Provider / Service Change

`RecurringTransactionProvider.add()` — accept and pass through `DateTime? endDate`.

`RecurringTransactionService.add()` — no change needed beyond model serialization.

### Processing Change: `_processDue()`

Before generating a transaction for an active item, check expiry:
```dart
if (item.endDate != null && now.isAfter(item.endDate!)) {
  // Auto-deactivate, do not generate transaction
  final deactivated = item.copyWith(isActive: false);
  await _service.update(deactivated);
  _items[idx] = deactivated;
  continue;
}
```

This deactivates expired entries silently on next app open. No deletion — user can still see the stopped entry.

### Tile Display: `_RecurringTile`

When `item.endDate != null`, show an "Ends: MMM yyyy" label next to the frequency badge:
```dart
if (item.endDate != null)
  Text(
    'Ends: ${DateFormat('MMM yyyy').format(item.endDate!)}',
    style: TextStyle(fontSize: 11, color: ...onSurfaceVariant),
  ),
```

Expired (auto-deactivated) tiles look the same as manually paused tiles.

---

## Files Changed

| File | Change |
|---|---|
| `lib/models/recurring_transaction_model.dart` | Add `endDate` field |
| `lib/services/recurring_transaction_service.dart` | Pass `endDate` through |
| `lib/providers/recurring_transaction_provider.dart` | Accept `endDate` in `add()`, expiry check in `_processDue()` |
| `lib/screens/recurring_transactions_screen.dart` | Duration dropdown, tile end-date display, dark theme |
| `lib/screens/*.dart` (all other screens) | Dark theme color token replacement |
| `lib/widgets/*.dart` | Dark theme color token replacement |
