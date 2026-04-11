# Budget Management Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add per-category and overall monthly budget limits with progress bars on dashboard and analytics.

**Architecture:** New `BudgetModel` / `BudgetService` / `BudgetProvider` following existing service-provider pattern. Firestore doc per user per month. BudgetProvider registered in MultiProvider at app root.

**Tech Stack:** Flutter, Cloud Firestore, provider

---

### Task 1: BudgetModel

**Files:**
- Create: `lib/models/budget_model.dart`

- [ ] Create the model:

```dart
import 'package:cloud_firestore/cloud_firestore.dart';

class BudgetModel {
  final String id; // "{userId}_{yyyy}_{mm}"
  final String userId;
  final int year;
  final int month;
  final double overall; // 0 = not set
  final Map<String, double> categories; // category → limit (0 = not set)

  BudgetModel({
    required this.id,
    required this.userId,
    required this.year,
    required this.month,
    this.overall = 0,
    this.categories = const {},
  });

  static String docId(String userId, int year, int month) =>
      '${userId}_${year}_${month.toString().padLeft(2, '0')}';

  factory BudgetModel.fromMap(Map<String, dynamic> map, String id) {
    return BudgetModel(
      id: id,
      userId: map['userId'] ?? '',
      year: map['year'] ?? DateTime.now().year,
      month: map['month'] ?? DateTime.now().month,
      overall: (map['overall'] ?? 0).toDouble(),
      categories: Map<String, double>.from(
        (map['categories'] as Map<String, dynamic>? ?? {})
            .map((k, v) => MapEntry(k, (v as num).toDouble())),
      ),
    );
  }

  Map<String, dynamic> toMap() => {
        'userId': userId,
        'year': year,
        'month': month,
        'overall': overall,
        'categories': categories,
      };

  BudgetModel copyWith({
    double? overall,
    Map<String, double>? categories,
  }) =>
      BudgetModel(
        id: id,
        userId: userId,
        year: year,
        month: month,
        overall: overall ?? this.overall,
        categories: categories ?? this.categories,
      );
}
```

- [ ] Commit:
```bash
git add lib/models/budget_model.dart
git commit -m "feat: add BudgetModel"
```

---

### Task 2: BudgetService

**Files:**
- Create: `lib/services/budget_service.dart`

- [ ] Create the service:

```dart
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/budget_model.dart';

class BudgetService {
  final _col = FirebaseFirestore.instance.collection('budgets');

  Future<BudgetModel?> getBudget(String userId, int year, int month) async {
    final id = BudgetModel.docId(userId, year, month);
    final doc = await _col.doc(id).get();
    if (!doc.exists) return null;
    return BudgetModel.fromMap(doc.data()!, doc.id);
  }

  Future<void> saveBudget(BudgetModel budget) async {
    await _col.doc(budget.id).set(budget.toMap());
  }
}
```

- [ ] Commit:
```bash
git add lib/services/budget_service.dart
git commit -m "feat: add BudgetService"
```

---

### Task 3: BudgetProvider

**Files:**
- Create: `lib/providers/budget_provider.dart`

- [ ] Create the provider:

```dart
import 'package:flutter/material.dart';
import '../models/budget_model.dart';
import '../services/budget_service.dart';

class BudgetProvider extends ChangeNotifier {
  final BudgetService _service = BudgetService();

  BudgetModel? _budget;
  bool _isLoading = false;

  BudgetModel? get budget => _budget;
  bool get isLoading => _isLoading;

  bool get hasOverallBudget => (_budget?.overall ?? 0) > 0;

  double overallUsedPercent(double totalExpenses) {
    if (_budget == null || _budget!.overall <= 0) return 0;
    return (totalExpenses / _budget!.overall * 100).clamp(0, 100);
  }

  double categoryUsedPercent(String category, double spent) {
    final limit = _budget?.categories[category] ?? 0;
    if (limit <= 0) return 0;
    return (spent / limit * 100).clamp(0, 100);
  }

  double categoryLimit(String category) =>
      _budget?.categories[category] ?? 0;

  Future<void> fetchBudget(String userId, DateTime month) async {
    _isLoading = true;
    notifyListeners();
    try {
      _budget = await _service.getBudget(userId, month.year, month.month);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> saveBudget({
    required String userId,
    required DateTime month,
    required double overall,
    required Map<String, double> categories,
  }) async {
    final id = BudgetModel.docId(userId, month.year, month.month);
    final model = BudgetModel(
      id: id,
      userId: userId,
      year: month.year,
      month: month.month,
      overall: overall,
      categories: categories,
    );
    await _service.saveBudget(model);
    _budget = model;
    notifyListeners();
  }
}
```

- [ ] Register in `lib/main.dart` — add import and provider:

```dart
// Add import
import 'providers/budget_provider.dart';
import 'screens/budget_settings.dart';

// In MultiProvider providers list, add:
ChangeNotifierProvider(create: (_) => BudgetProvider()),

// In generateRoute switch, add:
case '/budget_settings':
  return _slideUpRoute(const BudgetSettingsScreen());
```

- [ ] Commit:
```bash
git add lib/providers/budget_provider.dart lib/main.dart
git commit -m "feat: add BudgetProvider and register in app"
```

---

### Task 4: Budget Settings Screen

**Files:**
- Create: `lib/screens/budget_settings.dart`

- [ ] Create the screen:

```dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../providers/budget_provider.dart';
import '../providers/transaction_provider.dart';
import '../utils/constants.dart';
import '../utils/top_toast.dart';

class BudgetSettingsScreen extends StatefulWidget {
  const BudgetSettingsScreen({super.key});

  @override
  State<BudgetSettingsScreen> createState() => _BudgetSettingsScreenState();
}

class _BudgetSettingsScreenState extends State<BudgetSettingsScreen> {
  final _overallCtrl = TextEditingController();
  final Map<String, TextEditingController> _catCtrls = {};
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    // Init controllers for all expense categories
    for (final cat in kExpenseCategories) {
      _catCtrls[cat['name'] as String] = TextEditingController();
    }
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadBudget());
  }

  void _loadBudget() {
    final budget = context.read<BudgetProvider>().budget;
    if (budget == null) return;
    if (budget.overall > 0) {
      _overallCtrl.text = budget.overall.toStringAsFixed(0);
    }
    for (final entry in budget.categories.entries) {
      _catCtrls[entry.key]?.text =
          entry.value > 0 ? entry.value.toStringAsFixed(0) : '';
    }
  }

  @override
  void dispose() {
    _overallCtrl.dispose();
    for (final c in _catCtrls.values) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    try {
      final auth = context.read<AuthProvider>();
      final txProvider = context.read<TransactionProvider>();
      final overall = double.tryParse(_overallCtrl.text.trim()) ?? 0;
      final cats = <String, double>{};
      for (final e in _catCtrls.entries) {
        final v = double.tryParse(e.value.text.trim()) ?? 0;
        if (v > 0) cats[e.key] = v;
      }
      await context.read<BudgetProvider>().saveBudget(
            userId: auth.userId,
            month: txProvider.selectedMonth,
            overall: overall,
            categories: cats,
          );
      if (!mounted) return;
      showTopToast(context, 'Budget saved!');
      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      showTopToast(context, 'Failed to save budget', isError: true);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    const primary = Color(0xFF5D3891);
    final month = context.watch<TransactionProvider>().selectedMonth;
    final monthLabel =
        '${_monthName(month.month)} ${month.year}';

    return Scaffold(
      backgroundColor: const Color(0xFFF8F6FC),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF8F6FC),
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Budget Settings',
                style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF2D2D2D))),
            Text(monthLabel,
                style: TextStyle(
                    fontSize: 12,
                    color: const Color(0xFF2D2D2D).withOpacity(0.5),
                    fontWeight: FontWeight.w600)),
          ],
        ),
        centerTitle: true,
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          _sectionLabel('Overall Monthly Limit'),
          const SizedBox(height: 8),
          _buildField(_overallCtrl, 'e.g. 2000 (leave blank for no limit)'),
          const SizedBox(height: 24),
          _sectionLabel('Per-Category Limits'),
          const SizedBox(height: 8),
          ...kExpenseCategories.map((cat) {
            final name = cat['name'] as String;
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Row(
                children: [
                  Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      color: Color(cat['color'] as int).withOpacity(0.15),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(getCategoryIcon(cat['icon'] as String),
                        color: Color(cat['color'] as int), size: 20),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildField(
                        _catCtrls[name]!, 'No limit', label: name),
                  ),
                ],
              ),
            );
          }),
          const SizedBox(height: 32),
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
                  : const Text('Save Budget',
                      style: TextStyle(
                          fontSize: 16, fontWeight: FontWeight.w700)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _sectionLabel(String text) => Text(text,
      style: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w700,
          color: Color(0xFF2D2D2D)));

  Widget _buildField(TextEditingController ctrl, String hint,
      {String? label}) {
    return TextField(
      controller: ctrl,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
    );
  }

  String _monthName(int m) => const [
        '',
        'Jan','Feb','Mar','Apr','May','Jun',
        'Jul','Aug','Sep','Oct','Nov','Dec'
      ][m];
}
```

- [ ] Commit:
```bash
git add lib/screens/budget_settings.dart
git commit -m "feat: add BudgetSettingsScreen"
```

---

### Task 5: Dashboard Budget Card

**Files:**
- Modify: `lib/screens/home_dashboard.dart`

- [ ] Add budget card to dashboard — in `home_dashboard.dart`, after the income/expense row, add a budget card that reads from `BudgetProvider`. Add the import and provider read at the top of the build method, then insert a card:

```dart
// Add import at top of file
import '../providers/budget_provider.dart';

// In build(), alongside other providers:
final budgetProvider = Provider.of<BudgetProvider>(context);
final authProvider = Provider.of<AuthProvider>(context);
// after fetching transactions in initState, also fetch budget:
// (in initState addPostFrameCallback):
Provider.of<BudgetProvider>(context, listen: false)
    .fetchBudget(authProvider.userId, DateTime.now());
```

Add this widget method to `_HomeDashboardState`:

```dart
Widget _buildBudgetCard(BuildContext context, BudgetProvider budgetProvider,
    TransactionProvider txProvider, String currencySymbol) {
  if (!budgetProvider.hasOverallBudget) return const SizedBox.shrink();
  final spent = txProvider.totalExpenses;
  final limit = budgetProvider.budget!.overall;
  final pct = budgetProvider.overallUsedPercent(spent);
  final color = pct >= 90
      ? const Color(0xFFE74C3C)
      : pct >= 70
          ? const Color(0xFFF39C12)
          : const Color(0xFF2ECC71);

  return GestureDetector(
    onTap: () => Navigator.pushNamed(context, '/budget_settings'),
    child: Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 4))
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Monthly Budget',
                  style: TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 14,
                      color: Color(0xFF2D2D2D))),
              Text('${pct.toStringAsFixed(0)}% used',
                  style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: color)),
            ],
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: pct / 100,
              backgroundColor: color.withOpacity(0.15),
              valueColor: AlwaysStoppedAnimation<Color>(color),
              minHeight: 8,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '$currencySymbol ${spent.toStringAsFixed(0)} / $currencySymbol ${limit.toStringAsFixed(0)}',
            style: const TextStyle(
                fontSize: 12,
                color: Color(0xFF888888),
                fontWeight: FontWeight.w500),
          ),
        ],
      ),
    ),
  );
}
```

- [ ] Commit:
```bash
git add lib/screens/home_dashboard.dart
git commit -m "feat: add budget card to home dashboard"
```

---

### Task 6: Analytics Budget Bars + Profile Budget Tile

**Files:**
- Modify: `lib/screens/analytics.dart`
- Modify: `lib/screens/profile.dart`

- [ ] In `analytics.dart`, add budget import and per-category budget bars under the category legend items.

- [ ] In `profile.dart`, add a "Budget Settings" `ListTile` that navigates to `/budget_settings`.

- [ ] Commit:
```bash
git add lib/screens/analytics.dart lib/screens/profile.dart
git commit -m "feat: budget bars on analytics + profile nav tile"
```
