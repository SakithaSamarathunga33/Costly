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
    final cs = Theme.of(context).colorScheme;

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
            onPressed: () => _showSheet(context, auth.userId),
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
                        onEdit: () => _showSheet(context, auth.userId,
                            existing: item),
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

  void _showSheet(BuildContext context, String userId,
      {RecurringTransactionModel? existing}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _RecurringSheet(userId: userId, existing: existing),
    );
  }
}

class _RecurringTile extends StatelessWidget {
  final RecurringTransactionModel item;
  final String currencySymbol;
  final VoidCallback onEdit;
  final VoidCallback onToggle;
  final VoidCallback onDelete;

  const _RecurringTile({
    required this.item,
    required this.currencySymbol,
    required this.onEdit,
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
                            fontSize: 11, color: cs.onSurfaceVariant),
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
                    onTap: onEdit,
                    child: const Icon(Icons.edit_outlined,
                        size: 22, color: Color(0xFF5D3891)),
                  ),
                  const SizedBox(width: 8),
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

class _RecurringSheet extends StatefulWidget {
  final String userId;
  final RecurringTransactionModel? existing;
  const _RecurringSheet({required this.userId, this.existing});

  @override
  State<_RecurringSheet> createState() => _RecurringSheetState();
}

class _RecurringSheetState extends State<_RecurringSheet> {
  late final TextEditingController _titleCtrl;
  late final TextEditingController _amountCtrl;
  final TextEditingController _customMonthsCtrl = TextEditingController();
  late String _type;
  late String _category;
  late String _frequency;
  late String _duration; // '3m','6m','12m','custom','none'
  late DateTime _startDate;
  bool _saving = false;

  bool get _isEdit => widget.existing != null;

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    _type = e?.type ?? 'expense';
    _category = e?.category ?? 'Food';
    _frequency = e?.frequency ?? 'monthly';
    _startDate = e?.nextDueDate ?? DateTime.now();
    _titleCtrl = TextEditingController(text: e?.title ?? '');
    _amountCtrl = TextEditingController(
        text: e != null ? e.amount.toStringAsFixed(2) : '');

    // Determine initial duration from existing endDate
    if (e == null || e.endDate == null) {
      _duration = e == null ? '3m' : 'none';
    } else {
      final months = (e.endDate!.year - e.nextDueDate.year) * 12 +
          (e.endDate!.month - e.nextDueDate.month);
      if (months == 3) {
        _duration = '3m';
      } else if (months == 6) {
        _duration = '6m';
      } else if (months == 12) {
        _duration = '12m';
      } else {
        _duration = 'custom';
        _customMonthsCtrl.text = months.toString();
      }
    }
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _amountCtrl.dispose();
    _customMonthsCtrl.dispose();
    super.dispose();
  }

  List<Map<String, dynamic>> get _categories =>
      _type == 'expense' ? kExpenseCategories : kIncomeCategories;

  DateTime? get _computedEndDate {
    if (_duration == 'none') return null;
    int months;
    if (_duration == 'custom') {
      months = int.tryParse(_customMonthsCtrl.text.trim()) ?? 0;
      if (months <= 0) return null;
    } else {
      months = int.parse(_duration.replaceAll('m', ''));
    }
    return DateTime(_startDate.year, _startDate.month + months, _startDate.day);
  }

  Future<void> _save() async {
    final title = _titleCtrl.text.trim();
    final amount = double.tryParse(_amountCtrl.text.trim()) ?? 0;
    if (title.isEmpty || amount <= 0) {
      showTopToast(context, 'Enter a valid title and amount', isError: true);
      return;
    }
    if (_duration == 'custom') {
      final m = int.tryParse(_customMonthsCtrl.text.trim()) ?? 0;
      if (m <= 0) {
        showTopToast(context, 'Enter a valid number of months', isError: true);
        return;
      }
    }
    setState(() => _saving = true);
    try {
      final provider = context.read<RecurringTransactionProvider>();
      if (_isEdit) {
        final updated = widget.existing!.copyWith(
          title: title,
          amount: amount,
          type: _type,
          category: _category,
          frequency: _frequency,
          nextDueDate: _startDate,
          endDate: _computedEndDate,
        );
        await provider.updateItem(updated);
        if (!mounted) return;
        Navigator.pop(context);
        showTopToast(context, 'Recurring transaction updated!');
      } else {
        await provider.add(
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
      }
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
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
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
            Text(
                _isEdit
                    ? 'Edit Recurring Transaction'
                    : 'Add Recurring Transaction',
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
                    value: 'custom',
                    child: Text('Custom months',
                        style: TextStyle(color: cs.onSurface))),
                DropdownMenuItem(
                    value: 'none',
                    child: Text('No end',
                        style: TextStyle(color: cs.onSurface))),
              ],
              onChanged: (v) => setState(() => _duration = v!),
            ),
            if (_duration == 'custom') ...[
              const SizedBox(height: 12),
              _field(_customMonthsCtrl, 'Number of months', cs,
                  keyboardType: TextInputType.number),
            ],
            const SizedBox(height: 12),
            // Start date
            GestureDetector(
              onTap: () async {
                final picked = await showDatePicker(
                  context: context,
                  initialDate: _startDate,
                  firstDate: DateTime.now()
                      .subtract(const Duration(days: 365)),
                  lastDate: DateTime.now().add(const Duration(days: 365 * 5)),
                );
                if (picked != null) setState(() => _startDate = picked);
              },
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                decoration: BoxDecoration(
                  color: cs.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                        'Next due: ${DateFormat('MMM d, yyyy').format(_startDate)}',
                        style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: cs.onSurface)),
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
                    : Text(_isEdit ? 'Update' : 'Save',
                        style: const TextStyle(
                            fontSize: 16, fontWeight: FontWeight.w700)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _field(TextEditingController ctrl, String label, ColorScheme cs,
      {TextInputType? keyboardType}) {
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
