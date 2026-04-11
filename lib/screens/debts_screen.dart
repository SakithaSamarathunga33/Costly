import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/auth_provider.dart';
import '../providers/debt_provider.dart';
import '../models/debt_model.dart';
import '../utils/top_toast.dart';

class DebtsScreen extends StatelessWidget {
  const DebtsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    const primary = Color(0xFF5D3891);
    const bg = Color(0xFFF8F6FC);
    const textMain = Color(0xFF2D2D2D);

    final provider = context.watch<DebtProvider>();
    final auth = context.watch<AuthProvider>();
    final fmt = NumberFormat.currency(
        symbol: '${auth.currencySymbol} ', decimalDigits: 2);

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
        title: const Text('Debts & Loans',
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
          ? const Center(child: CircularProgressIndicator(color: primary))
          : Column(
              children: [
                // Summary row
                if (provider.debts.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
                    child: Row(
                      children: [
                        _summaryChip('I Owe',
                            fmt.format(provider.totalOwedByMe),
                            const Color(0xFFE74C3C)),
                        const SizedBox(width: 12),
                        _summaryChip('Owed to Me',
                            fmt.format(provider.totalOwedToMe),
                            const Color(0xFF2ECC71)),
                      ],
                    ),
                  ),
                Expanded(
                  child: provider.debts.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.account_balance_outlined,
                                  size: 56,
                                  color: primary.withValues(alpha: 0.3)),
                              const SizedBox(height: 16),
                              const Text('No debts recorded',
                                  style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                      color: textMain)),
                              const SizedBox(height: 8),
                              Text('Tap + to add a debt or loan',
                                  style: TextStyle(
                                      fontSize: 13,
                                      color:
                                          textMain.withValues(alpha: 0.45))),
                            ],
                          ),
                        )
                      : ListView.separated(
                          padding: const EdgeInsets.all(20),
                          itemCount: provider.debts.length,
                          separatorBuilder: (_, __) =>
                              const SizedBox(height: 12),
                          itemBuilder: (context, i) {
                            final debt = provider.debts[i];
                            return _DebtCard(
                              debt: debt,
                              fmt: fmt,
                              onPayment: () =>
                                  _showPaymentSheet(context, debt),
                              onDelete: () async {
                                await provider.deleteDebt(debt.id);
                                if (context.mounted) {
                                  showTopToast(
                                      context, '${debt.name} deleted');
                                }
                              },
                            );
                          },
                        ),
                ),
              ],
            ),
    );
  }

  Widget _summaryChip(String label, String value, Color color) {
    return Expanded(
      child: Container(
        padding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label,
                style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: color)),
            const SizedBox(height: 4),
            Text(value,
                style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: color)),
          ],
        ),
      ),
    );
  }

  void _showAddSheet(BuildContext context, String userId) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _AddDebtSheet(userId: userId),
    );
  }

  void _showPaymentSheet(BuildContext context, DebtModel debt) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _PaymentSheet(debt: debt),
    );
  }
}

class _DebtCard extends StatelessWidget {
  final DebtModel debt;
  final NumberFormat fmt;
  final VoidCallback onPayment;
  final VoidCallback onDelete;

  const _DebtCard({
    required this.debt,
    required this.fmt,
    required this.onPayment,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    const textMain = Color(0xFF2D2D2D);
    final isOwedByMe = debt.debtType == 'owed_by_me';
    final color = isOwedByMe
        ? const Color(0xFFE74C3C)
        : const Color(0xFF2ECC71);

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, 4)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  isOwedByMe ? 'I Owe' : 'Owed to Me',
                  style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: color),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(debt.name,
                    style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: textMain),
                    overflow: TextOverflow.ellipsis),
              ),
              if (debt.isSettled)
                const Icon(Icons.check_circle_rounded,
                    color: Color(0xFF2ECC71), size: 20),
              IconButton(
                icon: const Icon(Icons.delete_outline_rounded,
                    color: Colors.red, size: 20),
                onPressed: onDelete,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text('${isOwedByMe ? 'To' : 'From'}: ${debt.person}',
              style: TextStyle(
                  fontSize: 12,
                  color: textMain.withValues(alpha: 0.5))),
          if (debt.dueDate != null)
            Text(
                'Due: ${DateFormat('MMM d, yyyy').format(debt.dueDate!)}',
                style: TextStyle(
                    fontSize: 12,
                    color: DateTime.now().isAfter(debt.dueDate!) &&
                            !debt.isSettled
                        ? Colors.red
                        : textMain.withValues(alpha: 0.45))),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(fmt.format(debt.remainingAmount),
                  style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: debt.isSettled
                          ? const Color(0xFF2ECC71)
                          : color)),
              Text('of ${fmt.format(debt.totalAmount)}',
                  style: TextStyle(
                      fontSize: 13,
                      color: textMain.withValues(alpha: 0.45))),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(5),
            child: LinearProgressIndicator(
              value: debt.progressPercent / 100,
              backgroundColor: color.withValues(alpha: 0.15),
              valueColor: AlwaysStoppedAnimation<Color>(
                  debt.isSettled ? const Color(0xFF2ECC71) : color),
              minHeight: 7,
            ),
          ),
          if (!debt.isSettled) ...[
            const SizedBox(height: 10),
            GestureDetector(
              onTap: onPayment,
              child: Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 14, vertical: 7),
                decoration: BoxDecoration(
                  color: const Color(0xFF5D3891),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Text('Record Payment',
                    style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: Colors.white)),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _AddDebtSheet extends StatefulWidget {
  final String userId;
  const _AddDebtSheet({required this.userId});

  @override
  State<_AddDebtSheet> createState() => _AddDebtSheetState();
}

class _AddDebtSheetState extends State<_AddDebtSheet> {
  final _nameCtrl = TextEditingController();
  final _personCtrl = TextEditingController();
  final _amountCtrl = TextEditingController();
  final _notesCtrl = TextEditingController();
  String _debtType = 'owed_by_me';
  DateTime? _dueDate;
  bool _saving = false;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _personCtrl.dispose();
    _amountCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final name = _nameCtrl.text.trim();
    final person = _personCtrl.text.trim();
    final amount = double.tryParse(_amountCtrl.text.trim()) ?? 0;
    if (name.isEmpty || person.isEmpty || amount <= 0) {
      showTopToast(context, 'Fill in all required fields', isError: true);
      return;
    }
    setState(() => _saving = true);
    try {
      await context.read<DebtProvider>().addDebt(
            userId: widget.userId,
            name: name,
            person: person,
            totalAmount: amount,
            debtType: _debtType,
            dueDate: _dueDate,
            notes: _notesCtrl.text.trim(),
          );
      if (!mounted) return;
      Navigator.pop(context);
      showTopToast(context, 'Debt recorded!');
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
      builder: (_, sc) => Container(
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
          controller: sc,
          children: [
            Center(
              child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                      color: Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(2))),
            ),
            const SizedBox(height: 16),
            const Text('Add Debt / Loan',
                style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF2D2D2D))),
            const SizedBox(height: 20),
            // Type toggle
            Row(
              children: [
                _typeBtn('owed_by_me', 'I Owe'),
                const SizedBox(width: 10),
                _typeBtn('owed_to_me', 'Owed to Me'),
              ],
            ),
            const SizedBox(height: 14),
            _field(_nameCtrl, 'Description'),
            const SizedBox(height: 12),
            _field(_personCtrl,
                _debtType == 'owed_by_me' ? 'Creditor name' : 'Debtor name'),
            const SizedBox(height: 12),
            _field(_amountCtrl, 'Total amount',
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true)),
            const SizedBox(height: 12),
            _field(_notesCtrl, 'Notes (optional)'),
            const SizedBox(height: 12),
            GestureDetector(
              onTap: () async {
                final picked = await showDatePicker(
                  context: context,
                  initialDate:
                      DateTime.now().add(const Duration(days: 30)),
                  firstDate: DateTime.now(),
                  lastDate:
                      DateTime.now().add(const Duration(days: 365 * 5)),
                );
                if (picked != null) setState(() => _dueDate = picked);
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
                      _dueDate == null
                          ? 'Due date (optional)'
                          : 'Due: ${DateFormat('MMM d, yyyy').format(_dueDate!)}',
                      style: TextStyle(
                          fontSize: 14,
                          color: _dueDate == null
                              ? const Color(0xFF2D2D2D).withValues(alpha: 0.4)
                              : const Color(0xFF2D2D2D),
                          fontWeight: FontWeight.w500),
                    ),
                    const Icon(Icons.calendar_today_outlined,
                        size: 18, color: primary),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
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
          ],
        ),
      ),
    );
  }

  Widget _typeBtn(String type, String label) {
    final selected = _debtType == type;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _debtType = type),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: selected
                ? const Color(0xFF5D3891)
                : const Color(0xFF5D3891).withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(label,
              textAlign: TextAlign.center,
              style: TextStyle(
                  fontWeight: FontWeight.w700,
                  color: selected ? Colors.white : const Color(0xFF5D3891))),
        ),
      ),
    );
  }

  Widget _field(TextEditingController ctrl, String label,
      {TextInputType? keyboardType}) =>
      TextField(
        controller: ctrl,
        keyboardType: keyboardType,
        decoration: InputDecoration(
          labelText: label,
          filled: true,
          fillColor: const Color(0xFFF8F6FC),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        ),
      );
}

class _PaymentSheet extends StatefulWidget {
  final DebtModel debt;
  const _PaymentSheet({required this.debt});

  @override
  State<_PaymentSheet> createState() => _PaymentSheetState();
}

class _PaymentSheetState extends State<_PaymentSheet> {
  final _amountCtrl = TextEditingController();
  bool _saving = false;

  @override
  void dispose() {
    _amountCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final amount = double.tryParse(_amountCtrl.text.trim()) ?? 0;
    if (amount <= 0) {
      showTopToast(context, 'Enter a valid amount', isError: true);
      return;
    }
    setState(() => _saving = true);
    try {
      await context
          .read<DebtProvider>()
          .recordPayment(widget.debt.id, amount);
      if (!mounted) return;
      Navigator.pop(context);
      showTopToast(context, 'Payment recorded!');
    } catch (e) {
      if (!mounted) return;
      showTopToast(context, 'Failed to record', isError: true);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    const primary = Color(0xFF5D3891);
    return Padding(
      padding:
          EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Record payment for "${widget.debt.name}"',
                style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF2D2D2D))),
            const SizedBox(height: 16),
            TextField(
              controller: _amountCtrl,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              autofocus: true,
              decoration: InputDecoration(
                labelText: 'Amount paid',
                filled: true,
                fillColor: const Color(0xFFF8F6FC),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16, vertical: 14),
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _saving ? null : _save,
                style: ElevatedButton.styleFrom(
                  backgroundColor: primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
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
}
