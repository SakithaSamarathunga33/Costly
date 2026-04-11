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
    final monthLabel = '${_monthName(month.month)} ${month.year}';

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
                    color: const Color(0xFF2D2D2D).withValues(alpha: 0.5),
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
                      color: Color(cat['color'] as int).withValues(alpha: 0.15),
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
        'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
        'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
      ][m];
}
