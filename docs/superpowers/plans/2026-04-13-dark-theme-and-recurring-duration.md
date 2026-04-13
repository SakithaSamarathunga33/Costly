# Dark Theme Fix + Recurring Transaction Duration Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Fix dark theme by replacing hardcoded colors with `Theme.of(context).colorScheme` tokens across all screens and widgets, and add a duration dropdown to recurring transactions so they auto-stop after 3, 6, or 12 months (or never).

**Architecture:** Two independent changes. Dark theme: every screen resolves `final cs = Theme.of(context).colorScheme` at the top of `build()` and uses semantic tokens for all structural colors. Recurring duration: add `endDate` field to the model → service → provider chain, add a Duration dropdown to the add form, and check expiry in `_processDue()` to auto-deactivate.

**Tech Stack:** Flutter, Dart, Cloud Firestore, Provider

---

## File Map

| File | Change |
|---|---|
| `lib/models/recurring_transaction_model.dart` | Add `endDate` field, update fromMap/toMap/copyWith/constructor |
| `lib/services/recurring_transaction_service.dart` | Pass `endDate` through in `add()` |
| `lib/providers/recurring_transaction_provider.dart` | Accept `endDate` in `add()`, expiry check in `_processDue()` |
| `lib/screens/recurring_transactions_screen.dart` | Duration dropdown in form, endDate display on tile, dark theme |
| `lib/screens/home_dashboard.dart` | Dark theme colors |
| `lib/screens/transactions_history.dart` | Dark theme colors |
| `lib/screens/analytics.dart` | Dark theme colors |
| `lib/screens/profile.dart` | Dark theme colors |
| `lib/screens/add_expense.dart` | Dark theme colors |
| `lib/screens/add_income.dart` | Dark theme colors |
| `lib/screens/budget_settings.dart` | Dark theme colors |
| `lib/screens/savings_goals_screen.dart` | Dark theme colors |
| `lib/screens/debts_screen.dart` | Dark theme colors |
| `lib/screens/notification_settings_screen.dart` | Dark theme colors |
| `lib/screens/edit_profile.dart` | Dark theme colors |
| `lib/screens/edit_transaction.dart` | Dark theme colors |
| `lib/screens/income_list_screen.dart` | Dark theme colors |
| `lib/screens/expense_list_screen.dart` | Dark theme colors |
| `lib/screens/login_screen.dart` | Dark theme colors |
| `lib/screens/register_screen.dart` | Dark theme colors |
| `lib/widgets/tag_input_field.dart` | Dark theme colors |
| `lib/widgets/category_icon_picker_grid.dart` | Dark theme colors |

---

## Task 1: Update RecurringTransactionModel to add endDate

**Files:**
- Modify: `lib/models/recurring_transaction_model.dart`

- [ ] **Step 1: Replace the entire file with the updated model**

```dart
import 'package:cloud_firestore/cloud_firestore.dart';

class RecurringTransactionModel {
  final String id;
  final String userId;
  final String title;
  final double amount;
  final String type; // 'expense' or 'income'
  final String category;
  final String notes;
  final String frequency; // 'daily', 'weekly', 'monthly'
  final DateTime nextDueDate;
  final bool isActive;
  final DateTime? endDate; // null = no end

  RecurringTransactionModel({
    required this.id,
    required this.userId,
    required this.title,
    required this.amount,
    required this.type,
    required this.category,
    this.notes = '',
    required this.frequency,
    required this.nextDueDate,
    this.isActive = true,
    this.endDate,
  });

  factory RecurringTransactionModel.fromMap(
      Map<String, dynamic> map, String id) {
    return RecurringTransactionModel(
      id: id,
      userId: map['userId'] ?? '',
      title: map['title'] ?? '',
      amount: (map['amount'] ?? 0).toDouble(),
      type: map['type'] ?? 'expense',
      category: map['category'] ?? 'Other',
      notes: map['notes'] ?? '',
      frequency: map['frequency'] ?? 'monthly',
      nextDueDate: map['nextDueDate'] is Timestamp
          ? (map['nextDueDate'] as Timestamp).toDate()
          : DateTime.tryParse(map['nextDueDate']?.toString() ?? '') ??
              DateTime.now(),
      isActive: map['isActive'] ?? true,
      endDate: map['endDate'] is Timestamp
          ? (map['endDate'] as Timestamp).toDate()
          : map['endDate'] != null
              ? DateTime.tryParse(map['endDate'].toString())
              : null,
    );
  }

  Map<String, dynamic> toMap() {
    final m = <String, dynamic>{
      'userId': userId,
      'title': title,
      'amount': amount,
      'type': type,
      'category': category,
      'notes': notes,
      'frequency': frequency,
      'nextDueDate': Timestamp.fromDate(nextDueDate),
      'isActive': isActive,
    };
    if (endDate != null) m['endDate'] = Timestamp.fromDate(endDate!);
    return m;
  }

  RecurringTransactionModel copyWith({
    String? title,
    double? amount,
    String? type,
    String? category,
    String? notes,
    String? frequency,
    DateTime? nextDueDate,
    bool? isActive,
    Object? endDate = _sentinel,
  }) =>
      RecurringTransactionModel(
        id: id,
        userId: userId,
        title: title ?? this.title,
        amount: amount ?? this.amount,
        type: type ?? this.type,
        category: category ?? this.category,
        notes: notes ?? this.notes,
        frequency: frequency ?? this.frequency,
        nextDueDate: nextDueDate ?? this.nextDueDate,
        isActive: isActive ?? this.isActive,
        endDate: identical(endDate, _sentinel)
            ? this.endDate
            : endDate as DateTime?,
      );

  static const Object _sentinel = Object();

  DateTime nextAfter(DateTime from) {
    switch (frequency) {
      case 'daily':
        return from.add(const Duration(days: 1));
      case 'weekly':
        return from.add(const Duration(days: 7));
      case 'monthly':
      default:
        return DateTime(from.year, from.month + 1, from.day);
    }
  }
}
```

- [ ] **Step 2: Verify it compiles**

```bash
flutter analyze lib/models/recurring_transaction_model.dart
```
Expected: no errors.

- [ ] **Step 3: Commit**

```bash
git add lib/models/recurring_transaction_model.dart
git commit -m "feat: add endDate field to RecurringTransactionModel"
```

---

## Task 2: Update RecurringTransactionService to pass endDate through

**Files:**
- Modify: `lib/services/recurring_transaction_service.dart`

- [ ] **Step 1: Replace the `add()` method to use the model directly**

Replace the entire file with:

```dart
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/recurring_transaction_model.dart';

class RecurringTransactionService {
  final _col =
      FirebaseFirestore.instance.collection('recurring_transactions');

  Future<List<RecurringTransactionModel>> getAll(String userId) async {
    final snap = await _col.where('userId', isEqualTo: userId).get();
    return snap.docs
        .map((d) => RecurringTransactionModel.fromMap(d.data(), d.id))
        .toList();
  }

  Future<RecurringTransactionModel> add(
      RecurringTransactionModel model) async {
    final ref = _col.doc();
    final m = model.copyWith(); // clone with new id below
    final withId = RecurringTransactionModel(
      id: ref.id,
      userId: m.userId,
      title: m.title,
      amount: m.amount,
      type: m.type,
      category: m.category,
      notes: m.notes,
      frequency: m.frequency,
      nextDueDate: m.nextDueDate,
      isActive: m.isActive,
      endDate: m.endDate,
    );
    await ref.set(withId.toMap());
    return withId;
  }

  Future<void> update(RecurringTransactionModel model) async {
    await _col.doc(model.id).set(model.toMap());
  }

  Future<void> delete(String id) async {
    await _col.doc(id).delete();
  }
}
```

- [ ] **Step 2: Verify it compiles**

```bash
flutter analyze lib/services/recurring_transaction_service.dart
```
Expected: no errors.

- [ ] **Step 3: Commit**

```bash
git add lib/services/recurring_transaction_service.dart
git commit -m "feat: pass endDate through RecurringTransactionService"
```

---

## Task 3: Update provider — accept endDate and check expiry in _processDue

**Files:**
- Modify: `lib/providers/recurring_transaction_provider.dart`

- [ ] **Step 1: Replace the file with updated provider**

```dart
import 'package:flutter/material.dart';
import '../models/recurring_transaction_model.dart';
import '../services/recurring_transaction_service.dart';
import '../services/transaction_service.dart';

class RecurringTransactionProvider extends ChangeNotifier {
  final RecurringTransactionService _service = RecurringTransactionService();
  final TransactionService _txService = TransactionService();

  List<RecurringTransactionModel> _items = [];
  bool _isLoading = false;

  List<RecurringTransactionModel> get items => List.unmodifiable(_items);
  List<RecurringTransactionModel> get activeItems =>
      _items.where((r) => r.isActive).toList();
  bool get isLoading => _isLoading;

  Future<void> fetchAndProcess(String userId) async {
    _isLoading = true;
    notifyListeners();
    try {
      _items = await _service.getAll(userId);
      await _processDue(userId);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> _processDue(String userId) async {
    final now = DateTime.now();
    for (int i = 0; i < _items.length; i++) {
      final item = _items[i];
      if (!item.isActive) continue;

      // Auto-deactivate if past endDate
      if (item.endDate != null && now.isAfter(item.endDate!)) {
        final deactivated = item.copyWith(isActive: false);
        await _service.update(deactivated);
        _items[i] = deactivated;
        continue;
      }

      if (item.nextDueDate.isBefore(now) || _isSameDay(item.nextDueDate, now)) {
        await _txService.addTransaction(
          userId: userId,
          title: item.title,
          amount: item.amount,
          type: item.type,
          category: item.category,
          date: item.nextDueDate,
          notes: item.notes,
        );
        final updated = item.copyWith(nextDueDate: item.nextAfter(item.nextDueDate));
        await _service.update(updated);
        _items[i] = updated;
      }
    }
  }

  bool _isSameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  Future<void> add({
    required String userId,
    required String title,
    required double amount,
    required String type,
    required String category,
    required String frequency,
    required DateTime startDate,
    String notes = '',
    DateTime? endDate,
  }) async {
    final model = RecurringTransactionModel(
      id: '',
      userId: userId,
      title: title,
      amount: amount,
      type: type,
      category: category,
      notes: notes,
      frequency: frequency,
      nextDueDate: startDate,
      endDate: endDate,
    );
    final saved = await _service.add(model);
    _items.add(saved);
    notifyListeners();
  }

  Future<void> toggleActive(RecurringTransactionModel item) async {
    final updated = item.copyWith(isActive: !item.isActive);
    await _service.update(updated);
    final idx = _items.indexWhere((r) => r.id == item.id);
    if (idx != -1) _items[idx] = updated;
    notifyListeners();
  }

  Future<void> delete(String id) async {
    await _service.delete(id);
    _items.removeWhere((r) => r.id == id);
    notifyListeners();
  }
}
```

- [ ] **Step 2: Verify it compiles**

```bash
flutter analyze lib/providers/recurring_transaction_provider.dart
```
Expected: no errors.

- [ ] **Step 3: Commit**

```bash
git add lib/providers/recurring_transaction_provider.dart
git commit -m "feat: add endDate support and expiry check to RecurringTransactionProvider"
```

---

## Task 4: Update recurring transactions screen — duration dropdown + tile end date + dark theme

**Files:**
- Modify: `lib/screens/recurring_transactions_screen.dart`

- [ ] **Step 1: Replace the file with the updated version**

```dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/auth_provider.dart';
import '../providers/recurring_transaction_provider.dart';
import '../models/recurring_transaction_model.dart';
import '../utils/constants.dart';
import '../utils/top_toast.dart';

class RecurringTransactionsScreen extends StatelessWidget {
  const RecurringTransactionsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    const primary = Color(0xFF5D3891);

    final provider = context.watch<RecurringTransactionProvider>();
    final auth = context.watch<AuthProvider>();
    final currencySymbol = auth.currencySymbol;

    return Scaffold(
      backgroundColor: cs.surface,
      appBar: AppBar(
        backgroundColor: cs.surface,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text('Recurring',
            style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: cs.onSurface)),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.add_rounded, color: primary),
            onPressed: () => _showAddSheet(context, auth.userId),
          ),
        ],
      ),
      body: provider.isLoading
          ? const Center(child: CircularProgressIndicator(color: primary))
          : provider.items.isEmpty
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.repeat_rounded,
                          size: 56, color: primary.withValues(alpha: 0.3)),
                      const SizedBox(height: 16),
                      Text('No recurring transactions',
                          style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: cs.onSurface)),
                      const SizedBox(height: 8),
                      Text('Tap + to add one',
                          style: TextStyle(
                              fontSize: 13,
                              color: cs.onSurfaceVariant)),
                    ],
                  ),
                )
              : ListView.separated(
                  padding: const EdgeInsets.all(20),
                  itemCount: provider.items.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 10),
                  itemBuilder: (context, index) {
                    final item = provider.items[index];
                    return _RecurringTile(
                        item: item,
                        currencySymbol: currencySymbol,
                        onToggle: () => provider.toggleActive(item),
                        onDelete: () async {
                          await provider.delete(item.id);
                          if (context.mounted) {
                            showTopToast(context, '${item.title} deleted');
                          }
                        });
                  },
                ),
    );
  }

  void _showAddSheet(BuildContext context, String userId) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _AddRecurringSheet(userId: userId),
    );
  }
}

class _RecurringTile extends StatelessWidget {
  final RecurringTransactionModel item;
  final String currencySymbol;
  final VoidCallback onToggle;
  final VoidCallback onDelete;

  const _RecurringTile({
    required this.item,
    required this.currencySymbol,
    required this.onToggle,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isIncome = item.type == 'income';
    final color =
        isIncome ? const Color(0xFF2ECC71) : const Color(0xFFE74C3C);
    final catColor = getCategoryColor(item.category);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cs.surfaceContainerLow,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 8,
              offset: const Offset(0, 2)),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: catColor.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(getCategoryIconByName(item.category),
                color: catColor, size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(item.title,
                    style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: cs.onSurface)),
                const SizedBox(height: 3),
                Wrap(
                  spacing: 6,
                  runSpacing: 4,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: const Color(0xFF5D3891).withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        _capitalize(item.frequency),
                        style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF5D3891)),
                      ),
                    ),
                    Text(
                      'Next: ${DateFormat('MMM d').format(item.nextDueDate)}',
                      style: TextStyle(
                          fontSize: 11,
                          color: cs.onSurfaceVariant),
                    ),
                    if (item.endDate != null)
                      Text(
                        'Ends: ${DateFormat('MMM yyyy').format(item.endDate!)}',
                        style: TextStyle(
                            fontSize: 11,
                            color: cs.onSurfaceVariant),
                      ),
                  ],
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '${isIncome ? '+' : '-'}$currencySymbol ${item.amount.toStringAsFixed(0)}',
                style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: color),
              ),
              const SizedBox(height: 6),
              Row(
                children: [
                  GestureDetector(
                    onTap: onToggle,
                    child: Icon(
                      item.isActive
                          ? Icons.pause_circle_outline_rounded
                          : Icons.play_circle_outline_rounded,
                      size: 22,
                      color: item.isActive
                          ? Colors.orange
                          : const Color(0xFF5D3891),
                    ),
                  ),
                  const SizedBox(width: 8),
                  GestureDetector(
                    onTap: onDelete,
                    child: const Icon(Icons.delete_outline_rounded,
                        size: 22, color: Colors.red),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _capitalize(String s) =>
      s.isEmpty ? s : s[0].toUpperCase() + s.substring(1);
}

class _AddRecurringSheet extends StatefulWidget {
  final String userId;
  const _AddRecurringSheet({required this.userId});

  @override
  State<_AddRecurringSheet> createState() => _AddRecurringSheetState();
}

class _AddRecurringSheetState extends State<_AddRecurringSheet> {
  final _titleCtrl = TextEditingController();
  final _amountCtrl = TextEditingController();
  String _type = 'expense';
  String _category = 'Food';
  String _frequency = 'monthly';
  String _duration = '3m'; // '3m', '6m', '12m', 'none'
  DateTime _startDate = DateTime.now();
  bool _saving = false;

  @override
  void dispose() {
    _titleCtrl.dispose();
    _amountCtrl.dispose();
    super.dispose();
  }

  List<Map<String, dynamic>> get _categories =>
      _type == 'expense' ? kExpenseCategories : kIncomeCategories;

  DateTime? get _computedEndDate {
    if (_duration == 'none') return null;
    final months = int.parse(_duration.replaceAll('m', ''));
    return DateTime(
        _startDate.year, _startDate.month + months, _startDate.day);
  }

  Future<void> _save() async {
    final title = _titleCtrl.text.trim();
    final amount = double.tryParse(_amountCtrl.text.trim()) ?? 0;
    if (title.isEmpty || amount <= 0) {
      showTopToast(context, 'Enter a valid title and amount', isError: true);
      return;
    }
    setState(() => _saving = true);
    try {
      await context.read<RecurringTransactionProvider>().add(
            userId: widget.userId,
            title: title,
            amount: amount,
            type: _type,
            category: _category,
            frequency: _frequency,
            startDate: _startDate,
            endDate: _computedEndDate,
          );
      if (!mounted) return;
      Navigator.pop(context);
      showTopToast(context, 'Recurring transaction added!');
    } catch (e) {
      if (!mounted) return;
      showTopToast(context, 'Failed to save', isError: true);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    const primary = Color(0xFF5D3891);
    final cs = Theme.of(context).colorScheme;

    return DraggableScrollableSheet(
      initialChildSize: 0.9,
      maxChildSize: 0.95,
      minChildSize: 0.5,
      expand: false,
      builder: (_, scrollCtrl) => Container(
        decoration: BoxDecoration(
          color: cs.surface,
          borderRadius:
              const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: EdgeInsets.only(
            left: 24,
            right: 24,
            top: 16,
            bottom: MediaQuery.of(context).viewInsets.bottom + 24),
        child: ListView(
          controller: scrollCtrl,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                    color: cs.onSurfaceVariant.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(2)),
              ),
            ),
            const SizedBox(height: 16),
            Text('Add Recurring Transaction',
                style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: cs.onSurface)),
            const SizedBox(height: 20),
            // Type toggle
            Row(
              children: ['expense', 'income'].map((t) {
                final selected = _type == t;
                return Expanded(
                  child: GestureDetector(
                    onTap: () => setState(() {
                      _type = t;
                      _category = _categories.first['name'] as String;
                    }),
                    child: Container(
                      margin: EdgeInsets.only(
                          right: t == 'expense' ? 6 : 0,
                          left: t == 'income' ? 6 : 0),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      decoration: BoxDecoration(
                        color: selected
                            ? primary
                            : primary.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        t == 'expense' ? 'Expense' : 'Income',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                            fontWeight: FontWeight.w700,
                            color: selected ? Colors.white : primary),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 16),
            _field(_titleCtrl, 'Title', cs),
            const SizedBox(height: 12),
            _field(_amountCtrl, 'Amount', cs,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true)),
            const SizedBox(height: 12),
            // Category
            DropdownButtonFormField<String>(
              value: _category,
              decoration: _inputDeco('Category', cs),
              dropdownColor: cs.surfaceContainerHighest,
              items: _categories
                  .map((c) => DropdownMenuItem(
                      value: c['name'] as String,
                      child: Text(c['name'] as String,
                          style: TextStyle(color: cs.onSurface))))
                  .toList(),
              onChanged: (v) => setState(() => _category = v!),
            ),
            const SizedBox(height: 12),
            // Frequency
            DropdownButtonFormField<String>(
              value: _frequency,
              decoration: _inputDeco('Frequency', cs),
              dropdownColor: cs.surfaceContainerHighest,
              items: [
                DropdownMenuItem(
                    value: 'daily',
                    child: Text('Daily',
                        style: TextStyle(color: cs.onSurface))),
                DropdownMenuItem(
                    value: 'weekly',
                    child: Text('Weekly',
                        style: TextStyle(color: cs.onSurface))),
                DropdownMenuItem(
                    value: 'monthly',
                    child: Text('Monthly',
                        style: TextStyle(color: cs.onSurface))),
              ],
              onChanged: (v) => setState(() => _frequency = v!),
            ),
            const SizedBox(height: 12),
            // Duration
            DropdownButtonFormField<String>(
              value: _duration,
              decoration: _inputDeco('Duration', cs),
              dropdownColor: cs.surfaceContainerHighest,
              items: [
                DropdownMenuItem(
                    value: '3m',
                    child: Text('3 months',
                        style: TextStyle(color: cs.onSurface))),
                DropdownMenuItem(
                    value: '6m',
                    child: Text('6 months',
                        style: TextStyle(color: cs.onSurface))),
                DropdownMenuItem(
                    value: '12m',
                    child: Text('12 months',
                        style: TextStyle(color: cs.onSurface))),
                DropdownMenuItem(
                    value: 'none',
                    child: Text('No end',
                        style: TextStyle(color: cs.onSurface))),
              ],
              onChanged: (v) => setState(() => _duration = v!),
            ),
            const SizedBox(height: 12),
            // Start date
            GestureDetector(
              onTap: () async {
                final picked = await showDatePicker(
                  context: context,
                  initialDate: _startDate,
                  firstDate: DateTime.now(),
                  lastDate: DateTime.now().add(const Duration(days: 365)),
                );
                if (picked != null) setState(() => _startDate = picked);
              },
              child: Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 16, vertical: 16),
                decoration: BoxDecoration(
                  color: cs.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                        'Start: ${DateFormat('MMM d, yyyy').format(_startDate)}',
                        style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: cs.onSurface)),
                    Icon(Icons.calendar_today_outlined,
                        size: 18, color: primary),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _saving ? null : _save,
                style: ElevatedButton.styleFrom(
                  backgroundColor: primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                ),
                child: _saving
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                            color: Colors.white, strokeWidth: 2))
                    : const Text('Save',
                        style: TextStyle(
                            fontSize: 16, fontWeight: FontWeight.w700)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _field(
      TextEditingController ctrl, String label, ColorScheme cs, {
      TextInputType? keyboardType}) {
    return TextField(
      controller: ctrl,
      keyboardType: keyboardType,
      style: TextStyle(color: cs.onSurface),
      decoration: _inputDeco(label, cs),
    );
  }

  InputDecoration _inputDeco(String label, ColorScheme cs) => InputDecoration(
        labelText: label,
        labelStyle: TextStyle(color: cs.onSurfaceVariant),
        filled: true,
        fillColor: cs.surfaceContainerHighest,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      );
}
```

- [ ] **Step 2: Verify it compiles**

```bash
flutter analyze lib/screens/recurring_transactions_screen.dart
```
Expected: no errors.

- [ ] **Step 3: Commit**

```bash
git add lib/screens/recurring_transactions_screen.dart
git commit -m "feat: add duration dropdown and dark theme to recurring transactions screen"
```

---

## Task 5: Dark theme — home_dashboard.dart

**Files:**
- Modify: `lib/screens/home_dashboard.dart`

- [ ] **Step 1: In `build()`, replace the hardcoded color constants with theme tokens**

Find the block starting at line 52:
```dart
const Color primary = Color(0xFF5D3891);
const Color bgLight = Color(0xFFF8F6FC);
const Color cardWhite = Colors.white;
const Color textMain = Color(0xFF2D2D2D);
const Color greenAccent = Color(0xFF2ECC71);
const Color redAccent = Color(0xFFE74C3C);
```

Replace with:
```dart
const Color primary = Color(0xFF5D3891);
const Color greenAccent = Color(0xFF2ECC71);
const Color redAccent = Color(0xFFE74C3C);
final cs = Theme.of(context).colorScheme;
final Color bgLight = cs.surface;
final Color cardWhite = cs.surfaceContainerLow;
final Color textMain = cs.onSurface;
```

- [ ] **Step 2: Find all remaining hardcoded `Color(0xFF2D2D2D)` and `Color(0xFFF8F6FC)` and `Colors.white` used for backgrounds/text in this file and replace them with `cs.onSurface`, `cs.surface`, and `cs.surfaceContainerLow` respectively**

Run:
```bash
flutter analyze lib/screens/home_dashboard.dart
```
Expected: no errors.

- [ ] **Step 3: Commit**

```bash
git add lib/screens/home_dashboard.dart
git commit -m "fix: apply dark theme tokens to home_dashboard"
```

---

## Task 6: Dark theme — remaining screens (batch)

**Files:**
- Modify: all files listed below

For each screen below, apply the same pattern as Task 5:

1. At the top of each `build()` method, add:
   ```dart
   final cs = Theme.of(context).colorScheme;
   ```
2. Replace structural color constants:
   - `Color(0xFFF8F6FC)` / `Color(0xFFF5F5F5)` / `Color(0xFFFFFFFF)` used for **page backgrounds** → `cs.surface`
   - `Colors.white` used for **cards/containers** → `cs.surfaceContainerLow`
   - `Color(0xFF2D2D2D)` used for **primary text** → `cs.onSurface`
   - `Color(0xFF2D2D2D).withValues(alpha: 0.45)` or `.withOpacity(0.45)` for **secondary text** → `cs.onSurfaceVariant`
   - `Color(0xFFF8F6FC)` used for **input fill** → `cs.surfaceContainerHighest`
   - AppBar `backgroundColor` using bg color → `cs.surface`
   - `Scaffold(backgroundColor: ...)` using bg color → `cs.surface`
   - Bottom sheet `backgroundColor: Colors.white` → `cs.surface`
   - Modal/sheet container `color: Colors.white` → `cs.surface`
3. Keep brand purple `Color(0xFF5D3891)`, green `Color(0xFF2ECC71)`, red `Color(0xFFE74C3C)` as-is.
4. For `DropdownButtonFormField`, add `dropdownColor: cs.surfaceContainerHighest` and `style: TextStyle(color: cs.onSurface)` on dropdown items.

**Screens to update (apply pattern above to each):**
- [ ] `lib/screens/transactions_history.dart`
- [ ] `lib/screens/analytics.dart`
- [ ] `lib/screens/profile.dart`
- [ ] `lib/screens/add_expense.dart`
- [ ] `lib/screens/add_income.dart`
- [ ] `lib/screens/budget_settings.dart`
- [ ] `lib/screens/savings_goals_screen.dart`
- [ ] `lib/screens/debts_screen.dart`
- [ ] `lib/screens/notification_settings_screen.dart`
- [ ] `lib/screens/edit_profile.dart`
- [ ] `lib/screens/edit_transaction.dart`
- [ ] `lib/screens/income_list_screen.dart`
- [ ] `lib/screens/expense_list_screen.dart`
- [ ] `lib/screens/login_screen.dart`
- [ ] `lib/screens/register_screen.dart`

- [ ] **After all screens: run analyze**

```bash
flutter analyze lib/screens/
```
Expected: no errors.

- [ ] **Commit**

```bash
git add lib/screens/
git commit -m "fix: apply dark theme tokens to all screens"
```

---

## Task 7: Dark theme — widgets

**Files:**
- Modify: `lib/widgets/tag_input_field.dart`, `lib/widgets/category_icon_picker_grid.dart`

- [ ] **Step 1: Apply same color-token pattern to `tag_input_field.dart`**

Add `final cs = Theme.of(context).colorScheme;` in `build()` and replace structural colors.

- [ ] **Step 2: Apply same color-token pattern to `category_icon_picker_grid.dart`**

Add `final cs = Theme.of(context).colorScheme;` in `build()` and replace structural colors.

- [ ] **Step 3: Note on floating_nav_bar.dart**

`FloatingNavBar` uses `Color(0xFF5D3891)` as its background intentionally (brand-colored bar). White icon colors on it are intentional contrast. **No changes needed here.**

- [ ] **Step 4: Verify**

```bash
flutter analyze lib/widgets/
```
Expected: no errors.

- [ ] **Step 5: Commit**

```bash
git add lib/widgets/tag_input_field.dart lib/widgets/category_icon_picker_grid.dart
git commit -m "fix: apply dark theme tokens to widgets"
```

---

## Task 8: Full app analysis and manual smoke test

- [ ] **Step 1: Run full analysis**

```bash
flutter analyze
```
Expected: no errors (warnings about deprecated APIs are acceptable, errors are not).

- [ ] **Step 2: Run widget tests**

```bash
flutter test
```
Expected: all pass.

- [ ] **Step 3: Manual smoke test checklist**

Run the app (`flutter run`) and toggle dark mode from Profile → Appearance:

- [ ] Home dashboard background turns dark, cards turn dark-surface
- [ ] Transactions history background turns dark
- [ ] Analytics background turns dark
- [ ] Add expense/income sheet turns dark
- [ ] Profile screen turns dark
- [ ] Recurring transactions screen turns dark; add sheet turns dark
- [ ] Recurring tile shows "Ends: MMM yyyy" when endDate is set
- [ ] A new recurring transaction with "3 months" duration shows correct end date on tile
- [ ] A recurring transaction with "No end" shows no "Ends:" label

- [ ] **Step 4: Final commit**

```bash
git add -A
git commit -m "chore: verify dark theme and recurring duration complete"
```
