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
    const primary = Color(0xFF5D3891);
    const bg = Color(0xFFF8F6FC);
    const textMain = Color(0xFF2D2D2D);

    final provider = context.watch<RecurringTransactionProvider>();
    final auth = context.watch<AuthProvider>();
    final currencySymbol = auth.currencySymbol;

    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        backgroundColor: bg,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('Recurring',
            style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: textMain)),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.add_rounded, color: primary),
            onPressed: () => _showAddSheet(context, auth.userId),
          ),
        ],
      ),
      body: provider.isLoading
          ? const Center(
              child: CircularProgressIndicator(color: primary))
          : provider.items.isEmpty
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.repeat_rounded,
                          size: 56, color: primary.withValues(alpha: 0.3)),
                      const SizedBox(height: 16),
                      const Text('No recurring transactions',
                          style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: textMain)),
                      const SizedBox(height: 8),
                      Text('Tap + to add one',
                          style: TextStyle(
                              fontSize: 13,
                              color: textMain.withValues(alpha: 0.45))),
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
    const textMain = Color(0xFF2D2D2D);
    final isIncome = item.type == 'income';
    final color =
        isIncome ? const Color(0xFF2ECC71) : const Color(0xFFE74C3C);
    final catColor = getCategoryColor(item.category);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
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
                    style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: textMain)),
                const SizedBox(height: 3),
                Row(
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
                    const SizedBox(width: 6),
                    Text(
                      'Next: ${DateFormat('MMM d').format(item.nextDueDate)}',
                      style: TextStyle(
                          fontSize: 11,
                          color: textMain.withValues(alpha: 0.45)),
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
    return DraggableScrollableSheet(
      initialChildSize: 0.85,
      maxChildSize: 0.95,
      minChildSize: 0.5,
      expand: false,
      builder: (_, scrollCtrl) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
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
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2)),
              ),
            ),
            const SizedBox(height: 16),
            const Text('Add Recurring Transaction',
                style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF2D2D2D))),
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
            _field(_titleCtrl, 'Title'),
            const SizedBox(height: 12),
            _field(_amountCtrl, 'Amount',
                keyboardType: const TextInputType.numberWithOptions(decimal: true)),
            const SizedBox(height: 12),
            // Category
            DropdownButtonFormField<String>(
              value: _category,
              decoration: _inputDeco('Category'),
              items: _categories
                  .map((c) => DropdownMenuItem(
                      value: c['name'] as String,
                      child: Text(c['name'] as String)))
                  .toList(),
              onChanged: (v) => setState(() => _category = v!),
            ),
            const SizedBox(height: 12),
            // Frequency
            DropdownButtonFormField<String>(
              value: _frequency,
              decoration: _inputDeco('Frequency'),
              items: const [
                DropdownMenuItem(value: 'daily', child: Text('Daily')),
                DropdownMenuItem(value: 'weekly', child: Text('Weekly')),
                DropdownMenuItem(value: 'monthly', child: Text('Monthly')),
              ],
              onChanged: (v) => setState(() => _frequency = v!),
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
                  color: const Color(0xFFF8F6FC),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                        'Start: ${DateFormat('MMM d, yyyy').format(_startDate)}',
                        style: const TextStyle(
                            fontSize: 14, fontWeight: FontWeight.w500)),
                    const Icon(Icons.calendar_today_outlined,
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

  Widget _field(TextEditingController ctrl, String label,
      {TextInputType? keyboardType}) {
    return TextField(
      controller: ctrl,
      keyboardType: keyboardType,
      decoration: _inputDeco(label),
    );
  }

  InputDecoration _inputDeco(String label) => InputDecoration(
        labelText: label,
        filled: true,
        fillColor: const Color(0xFFF8F6FC),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      );
}
