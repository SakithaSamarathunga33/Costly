# Remaining Features Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Implement the 5 remaining features (Dark Mode, Transaction Tags, Bulk Operations, Password Change / Account Deletion, Backend Server integration) that were not completed in the first session.

**Architecture:** Each feature follows the established service/provider/screen pattern. Dark Mode requires a `ThemeProvider` and replacing all hardcoded colors with `Theme.of(context)` lookups. Tags extend `TransactionModel`. Bulk ops add selection state to list screens. Auth operations extend `AuthService`/`AuthProvider`. Backend integration wires the existing `server/` Dart server to the Flutter app via HTTP.

**Tech Stack:** Flutter, Cloud Firestore, provider, Firebase Auth, Shelf (backend)

---

## Completed Features (reference)

| Feature | Key files |
|---------|-----------|
| Budget Management | `lib/models/budget_model.dart`, `lib/services/budget_service.dart`, `lib/providers/budget_provider.dart`, `lib/screens/budget_settings.dart` |
| Recurring Transactions | `lib/models/recurring_transaction_model.dart`, `lib/services/recurring_transaction_service.dart`, `lib/providers/recurring_transaction_provider.dart`, `lib/screens/recurring_transactions_screen.dart` |
| Savings Goals | `lib/models/savings_goal_model.dart`, `lib/services/savings_goal_service.dart`, `lib/providers/savings_goal_provider.dart`, `lib/screens/savings_goals_screen.dart` |
| Debt Tracking | `lib/models/debt_model.dart`, `lib/services/debt_service.dart`, `lib/providers/debt_provider.dart`, `lib/screens/debts_screen.dart` |
| Income Analytics | `lib/screens/analytics.dart` (Income tab) |
| Date Range Filtering | `lib/providers/transaction_provider.dart` (`customDateRange`, `filteredTransactions`, etc.) |
| Category Spending Trends | `lib/screens/analytics.dart` (Trends tab) |
| Notifications | `lib/services/notification_service.dart`, `lib/screens/notification_settings_screen.dart` |

---

## Feature 9: Dark Mode

**Files:**
- Create: `lib/providers/theme_provider.dart`
- Modify: `lib/main.dart`
- Modify: `lib/utils/constants.dart` (add dark palette constants)
- Modify: `lib/screens/profile.dart` (add theme toggle tile)

**Approach:** Add a `ThemeProvider` that stores the user's preference in `SharedPreferences` (`theme_mode` key: `'light'` / `'dark'` / `'system'`). In `main.dart`, switch `MaterialApp.themeMode` based on the provider. Replace hardcoded `Color(0xFFF8F6FC)` backgrounds and `Color(0xFF2D2D2D)` text colors throughout the app with `Theme.of(context).colorScheme` lookups.

**Dark theme palette:**
- Background: `Color(0xFF121212)`
- Surface/card: `Color(0xFF1E1E1E)`
- Primary: `Color(0xFF7B52AB)` (lighter purple for dark bg contrast)
- Text main: `Color(0xFFE0E0E0)`

### Task 1: ThemeProvider

- [ ] Create `lib/providers/theme_provider.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeProvider extends ChangeNotifier {
  static const _key = 'theme_mode';
  ThemeMode _mode = ThemeMode.system;

  ThemeMode get mode => _mode;
  bool get isDark => _mode == ThemeMode.dark;

  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString(_key) ?? 'system';
    _mode = saved == 'dark'
        ? ThemeMode.dark
        : saved == 'light'
            ? ThemeMode.light
            : ThemeMode.system;
    notifyListeners();
  }

  Future<void> setMode(ThemeMode mode) async {
    _mode = mode;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    final key = mode == ThemeMode.dark
        ? 'dark'
        : mode == ThemeMode.light
            ? 'light'
            : 'system';
    await prefs.setString(_key, key);
  }
}
```

- [ ] Register in `lib/main.dart`:
  - Import `ThemeProvider`
  - Add `ChangeNotifierProvider(create: (_) => ThemeProvider())` to `MultiProvider`
  - In `main()`, after `NotificationService().init()`, call `await themeProvider.init()` (create provider before `runApp` or use `Consumer` in `ExpenseTrackerApp`)
  - Add `darkTheme` and `themeMode` to `MaterialApp`:

```dart
// In ExpenseTrackerApp.build():
final themeProvider = Provider.of<ThemeProvider>(context);
return MaterialApp(
  themeMode: themeProvider.mode,
  theme: ThemeData(
    colorScheme: ColorScheme.fromSeed(
      seedColor: const Color(0xFF5D3891),
      brightness: Brightness.light,
    ),
    useMaterial3: true,
    scaffoldBackgroundColor: const Color(0xFFF5F5F5),
  ),
  darkTheme: ThemeData(
    colorScheme: ColorScheme.fromSeed(
      seedColor: const Color(0xFF7B52AB),
      brightness: Brightness.dark,
    ),
    useMaterial3: true,
    scaffoldBackgroundColor: const Color(0xFF121212),
    cardColor: const Color(0xFF1E1E1E),
  ),
  // ...rest unchanged
);
```

- [ ] Add theme toggle tile to `lib/screens/profile.dart` in the PREFERENCES section:

```dart
_buildPreferenceItem(
  icon: Icons.dark_mode_outlined,
  iconBg: primary.withValues(alpha: 0.08),
  iconColor: primary,
  title: 'Appearance',
  subtitle: themeProvider.mode == ThemeMode.dark
      ? 'Dark mode'
      : themeProvider.mode == ThemeMode.light
          ? 'Light mode'
          : 'System default',
  onTap: () => _showThemePicker(context, themeProvider),
),
```

Add `_showThemePicker` method:

```dart
void _showThemePicker(BuildContext context, ThemeProvider themeProvider) {
  showModalBottomSheet(
    context: context,
    builder: (_) => SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            leading: const Icon(Icons.light_mode_outlined),
            title: const Text('Light'),
            trailing: themeProvider.mode == ThemeMode.light
                ? const Icon(Icons.check, color: Color(0xFF5D3891)) : null,
            onTap: () {
              themeProvider.setMode(ThemeMode.light);
              Navigator.pop(context);
            },
          ),
          ListTile(
            leading: const Icon(Icons.dark_mode_outlined),
            title: const Text('Dark'),
            trailing: themeProvider.mode == ThemeMode.dark
                ? const Icon(Icons.check, color: Color(0xFF5D3891)) : null,
            onTap: () {
              themeProvider.setMode(ThemeMode.dark);
              Navigator.pop(context);
            },
          ),
          ListTile(
            leading: const Icon(Icons.brightness_auto_outlined),
            title: const Text('System'),
            trailing: themeProvider.mode == ThemeMode.system
                ? const Icon(Icons.check, color: Color(0xFF5D3891)) : null,
            onTap: () {
              themeProvider.setMode(ThemeMode.system);
              Navigator.pop(context);
            },
          ),
        ],
      ),
    ),
  );
}
```

- [ ] Commit:
```bash
git add lib/providers/theme_provider.dart lib/main.dart lib/screens/profile.dart
git commit -m "feat: add dark mode with ThemeProvider (light/dark/system)"
```

---

## Feature 10: Transaction Tags

**Files:**
- Modify: `lib/models/transaction_model.dart` — add `List<String> tags` field
- Modify: `lib/services/transaction_service.dart` — include `tags` in toMap/fromMap
- Modify: `lib/screens/add_expense.dart` — add tag input chip row
- Modify: `lib/screens/add_income.dart` — add tag input chip row
- Modify: `lib/screens/edit_transaction.dart` — add tag editing
- Modify: `lib/screens/transactions_history.dart` — filter by tag

**Approach:** `tags` is a `List<String>` stored as a Firestore array. In the add/edit screens, show an input field that adds chips. In the history screen, tapping a tag on a transaction tile filters the list to matching tags.

### Task 2: Add tags to TransactionModel

- [ ] In `lib/models/transaction_model.dart`, add `tags` field:

```dart
// Add to constructor params:
this.tags = const [],

// Add field:
final List<String> tags;

// In fromMap:
tags: List<String>.from(map['tags'] ?? []),

// In toMap:
'tags': tags,

// In copyWith:
List<String>? tags,
// ...
tags: tags ?? this.tags,
```

- [ ] In `lib/services/transaction_service.dart`, update `addTransaction` signature:

```dart
Future<TransactionModel> addTransaction({
  // ...existing params...
  List<String> tags = const [],
}) async {
  // ...
  final transaction = TransactionModel(
    // ...existing fields...
    tags: tags,
  );
```

- [ ] Add a `TagInputField` widget to `lib/widgets/tag_input_field.dart`:

```dart
import 'package:flutter/material.dart';

class TagInputField extends StatefulWidget {
  final List<String> tags;
  final ValueChanged<List<String>> onChanged;

  const TagInputField({super.key, required this.tags, required this.onChanged});

  @override
  State<TagInputField> createState() => _TagInputFieldState();
}

class _TagInputFieldState extends State<TagInputField> {
  final _ctrl = TextEditingController();

  void _add() {
    final tag = _ctrl.text.trim().toLowerCase();
    if (tag.isEmpty || widget.tags.contains(tag)) {
      _ctrl.clear();
      return;
    }
    widget.onChanged([...widget.tags, tag]);
    _ctrl.clear();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _ctrl,
                decoration: InputDecoration(
                  hintText: 'Add tag (e.g. groceries)',
                  filled: true,
                  fillColor: const Color(0xFFF8F6FC),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 12),
                ),
                onSubmitted: (_) => _add(),
              ),
            ),
            const SizedBox(width: 8),
            IconButton(
              icon: const Icon(Icons.add_circle_rounded,
                  color: Color(0xFF5D3891)),
              onPressed: _add,
            ),
          ],
        ),
        if (widget.tags.isNotEmpty) ...[
          const SizedBox(height: 8),
          Wrap(
            spacing: 6,
            children: widget.tags.map((tag) => Chip(
              label: Text(tag,
                  style: const TextStyle(fontSize: 12)),
              deleteIcon: const Icon(Icons.close, size: 14),
              onDeleted: () {
                widget.onChanged(
                    widget.tags.where((t) => t != tag).toList());
              },
              backgroundColor:
                  const Color(0xFF5D3891).withValues(alpha: 0.1),
              labelStyle: const TextStyle(color: Color(0xFF5D3891)),
              side: BorderSide.none,
            )).toList(),
          ),
        ],
      ],
    );
  }
}
```

- [ ] Integrate `TagInputField` into `add_expense.dart`, `add_income.dart`, and `edit_transaction.dart` — add a `List<String> _tags = []` state variable, pass to `TagInputField`, and pass to `addTransaction`/`updateTransaction`.

- [ ] In `transactions_history.dart`, add tag-filter chip row: tapping a tag on a transaction tile sets a `_filterTag` string; filter `txProvider.transactions` where `tx.tags.contains(_filterTag)`.

- [ ] Commit:
```bash
git add lib/models/transaction_model.dart lib/services/transaction_service.dart \
  lib/widgets/tag_input_field.dart lib/screens/add_expense.dart \
  lib/screens/add_income.dart lib/screens/edit_transaction.dart \
  lib/screens/transactions_history.dart
git commit -m "feat: add transaction tags with chip UI and tag filter"
```

---

## Feature 11: Bulk Operations

**Files:**
- Modify: `lib/screens/transactions_history.dart` — add selection mode
- Modify: `lib/screens/income_list_screen.dart` — add selection mode
- Modify: `lib/screens/expense_list_screen.dart` — add selection mode

**Approach:** Long-press a transaction tile to enter selection mode. A bottom action bar appears with "Delete selected" and "Select all". Uses local `Set<String> _selectedIds` state. Calls `TransactionProvider.deleteTransactions(ids)` which already exists.

### Task 3: Bulk operations in transaction lists

- [ ] In `transactions_history.dart`, add to state:

```dart
final Set<String> _selectedIds = {};
bool get _selectionMode => _selectedIds.isNotEmpty;
```

- [ ] Wrap each transaction tile in `GestureDetector`:

```dart
GestureDetector(
  onLongPress: () => setState(() => _selectedIds.add(tx.id)),
  onTap: _selectionMode
      ? () => setState(() {
          if (_selectedIds.contains(tx.id)) _selectedIds.remove(tx.id);
          else _selectedIds.add(tx.id);
        })
      : null, // existing tap behavior
  child: _buildTransactionTile(tx, isSelected: _selectedIds.contains(tx.id)),
)
```

- [ ] Add a selection overlay indicator to each tile (blue border or check icon when selected).

- [ ] Add bottom action bar that appears when `_selectionMode`:

```dart
if (_selectionMode)
  Positioned(
    bottom: 90, left: 20, right: 20,
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF5D3891),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 12)],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text('${_selectedIds.length} selected',
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
          Row(children: [
            TextButton(
              onPressed: () => setState(() {
                _selectedIds.addAll(txProvider.transactions.map((t) => t.id));
              }),
              child: const Text('All', style: TextStyle(color: Colors.white70)),
            ),
            TextButton(
              onPressed: () async {
                final ids = _selectedIds.toList();
                setState(() => _selectedIds.clear());
                await txProvider.deleteTransactions(ids);
                if (mounted) showTopToast(context, '${ids.length} deleted');
              },
              child: const Text('Delete', style: TextStyle(color: Color(0xFFFF6B6B))),
            ),
          ]),
        ],
      ),
    ),
  ),
```

- [ ] Add `WillPopScope` / `PopScope` — if in selection mode, back press clears selection instead of leaving screen.

- [ ] Apply same pattern to `income_list_screen.dart` and `expense_list_screen.dart`.

- [ ] Commit:
```bash
git add lib/screens/transactions_history.dart lib/screens/income_list_screen.dart \
  lib/screens/expense_list_screen.dart
git commit -m "feat: bulk select and delete transactions"
```

---

## Feature 12: Password Change / Account Deletion

**Files:**
- Modify: `lib/services/auth_service.dart` — add `changePassword()`, `deleteAccount()`
- Modify: `lib/providers/auth_provider.dart` — expose `changePassword()`, `deleteAccount()`
- Modify: `lib/screens/profile.dart` — add "Change Password" and "Delete Account" tiles

**Approach:** Firebase Auth supports `updatePassword()` (requires recent sign-in) and `delete()`. For password change, prompt current password + new password in a bottom sheet (re-authenticate first). For account deletion, show a confirmation dialog, re-authenticate, delete all user data from Firestore, then delete the Firebase Auth account.

### Task 4: Auth service methods

- [ ] In `lib/services/auth_service.dart`, add:

```dart
import 'package:firebase_auth/firebase_auth.dart';

// Add these methods to AuthService:

Future<void> changePassword({
  required String currentPassword,
  required String newPassword,
}) async {
  final user = FirebaseAuth.instance.currentUser;
  if (user == null || user.email == null) throw Exception('Not signed in');
  // Re-authenticate
  final cred = EmailAuthProvider.credential(
      email: user.email!, password: currentPassword);
  await user.reauthenticateWithCredential(cred);
  await user.updatePassword(newPassword);
}

Future<void> deleteAccount({required String password}) async {
  final user = FirebaseAuth.instance.currentUser;
  if (user == null || user.email == null) throw Exception('Not signed in');
  final cred = EmailAuthProvider.credential(
      email: user.email!, password: password);
  await user.reauthenticateWithCredential(cred);
  // Delete Firestore user document
  await FirebaseFirestore.instance.collection('users').doc(user.uid).delete();
  // Delete Firebase Auth account
  await user.delete();
}
```

- [ ] In `lib/providers/auth_provider.dart`, add wrapper methods that catch errors and set `_error`.

- [ ] In `lib/screens/profile.dart`, add two tiles in a new "ACCOUNT" section above the logout button:

```dart
// ─── ACCOUNT Section ───
_buildPreferenceItem(
  icon: Icons.lock_outline_rounded,
  iconBg: primary.withValues(alpha: 0.08),
  iconColor: primary,
  title: 'Change Password',
  subtitle: 'Update your account password',
  onTap: () => _showChangePasswordSheet(context, authProvider),
),
const SizedBox(height: 10),
_buildPreferenceItem(
  icon: Icons.delete_forever_outlined,
  iconBg: Colors.red.withValues(alpha: 0.08),
  iconColor: Colors.red,
  title: 'Delete Account',
  subtitle: 'Permanently remove your account and data',
  onTap: () => _showDeleteAccountDialog(context, authProvider),
),
```

- [ ] Add `_showChangePasswordSheet` — bottom sheet with current/new/confirm password fields.
- [ ] Add `_showDeleteAccountDialog` — confirmation dialog with password field.

- [ ] Commit:
```bash
git add lib/services/auth_service.dart lib/providers/auth_provider.dart lib/screens/profile.dart
git commit -m "feat: password change and account deletion"
```

---

## Feature 13: Wire up Backend Server

**Context:** The `server/` directory contains a standalone Dart/Shelf HTTP server backed by MongoDB. It is currently completely disconnected from the Flutter app (which uses Firestore directly). The plan is to make the backend optionally usable for analytics aggregation — the app continues working with Firestore but can also call the backend for richer server-side queries.

**Files:**
- Create: `lib/services/backend_service.dart` — thin HTTP client for the Dart backend
- Modify: `lib/utils/constants.dart` — add `kBackendBaseUrl` constant
- Modify: `server/bin/server.dart` — ensure endpoints match what the Flutter app needs
- Modify: `server/pubspec.yaml` — ensure dependencies are current

**Approach:** Create a `BackendService` that wraps `http` to call the Shelf server. Initial endpoints:
- `GET /health` — ping to check if backend is reachable
- `GET /analytics/summary?userId=X&month=YYYY-MM` — monthly totals (income, expenses, by category)
- `POST /transactions` — sync a transaction to MongoDB (mirror of Firestore write)

The Flutter app calls `BackendService` in parallel to Firestore writes — if the backend is unreachable, it fails silently (Firestore is always the source of truth).

### Task 5: BackendService

- [ ] Add `kBackendBaseUrl` to `lib/utils/constants.dart`:

```dart
// Set to your deployed backend URL, or 'http://10.0.2.2:8080' for Android emulator local dev
const String kBackendBaseUrl = String.fromEnvironment(
  'BACKEND_URL',
  defaultValue: 'http://10.0.2.2:8080',
);
```

- [ ] Create `lib/services/backend_service.dart`:

```dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../utils/constants.dart';

class BackendService {
  static final BackendService _instance = BackendService._();
  factory BackendService() => _instance;
  BackendService._();

  final _base = kBackendBaseUrl;
  final _client = http.Client();

  Future<bool> isReachable() async {
    try {
      final res = await _client
          .get(Uri.parse('$_base/health'))
          .timeout(const Duration(seconds: 3));
      return res.statusCode == 200;
    } catch (_) {
      return false;
    }
  }

  Future<Map<String, dynamic>?> getAnalyticsSummary({
    required String userId,
    required int year,
    required int month,
  }) async {
    try {
      final uri = Uri.parse('$_base/analytics/summary')
          .replace(queryParameters: {
        'userId': userId,
        'month': '$year-${month.toString().padLeft(2, '0')}',
      });
      final res = await _client
          .get(uri, headers: {'Content-Type': 'application/json'})
          .timeout(const Duration(seconds: 5));
      if (res.statusCode == 200) {
        return json.decode(res.body) as Map<String, dynamic>;
      }
    } catch (_) {}
    return null;
  }

  Future<void> syncTransaction(Map<String, dynamic> txData) async {
    try {
      await _client
          .post(
            Uri.parse('$_base/transactions'),
            headers: {'Content-Type': 'application/json'},
            body: json.encode(txData),
          )
          .timeout(const Duration(seconds: 5));
    } catch (_) {
      // Backend sync is best-effort; Firestore is source of truth
    }
  }
}
```

- [ ] Update `server/bin/server.dart` to add `/health`, `/analytics/summary`, and `/transactions` endpoints that connect to MongoDB.

- [ ] (Optional) In `TransactionService.addTransaction()`, after the Firestore write, call `BackendService().syncTransaction(transaction.toMap())` fire-and-forget.

- [ ] Commit:
```bash
git add lib/services/backend_service.dart lib/utils/constants.dart server/
git commit -m "feat: wire up backend server with BackendService HTTP client"
```

---

## Execution Notes

- All features are independent — they can be implemented in any order
- Features 9 (Dark Mode) touches the most files due to color propagation — do last if batching
- Feature 13 (Backend) requires the `server/` process to be running locally for testing
- After all features are done, run `flutter analyze` and fix any warnings before tagging a release
