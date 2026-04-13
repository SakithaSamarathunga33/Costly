import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/auth_provider.dart';
import '../providers/savings_goal_provider.dart';
import '../models/savings_goal_model.dart';
import '../utils/constants.dart';
import '../utils/top_toast.dart';

class SavingsGoalsScreen extends StatelessWidget {
  const SavingsGoalsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    const primary = Color(0xFF5D3891);

    final provider = context.watch<SavingsGoalProvider>();
    final auth = context.watch<AuthProvider>();
    final fmt = NumberFormat.currency(
        symbol: '${auth.currencySymbol} ', decimalDigits: 2);

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
        title: Text('Savings Goals',
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
          ? const Center(
              child: CircularProgressIndicator(color: primary))
          : provider.goals.isEmpty
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.savings_outlined,
                          size: 56,
                          color: primary.withValues(alpha: 0.3)),
                      const SizedBox(height: 16),
                      Text('No savings goals yet',
                          style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: cs.onSurface)),
                      const SizedBox(height: 8),
                      Text('Tap + to create a goal',
                          style: TextStyle(
                              fontSize: 13,
                              color: cs.onSurfaceVariant)),
                    ],
                  ),
                )
              : ListView.separated(
                  padding: const EdgeInsets.all(20),
                  itemCount: provider.goals.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 14),
                  itemBuilder: (context, i) {
                    final goal = provider.goals[i];
                    return _GoalCard(
                      goal: goal,
                      fmt: fmt,
                      currencySymbol: auth.currencySymbol,
                      onContribute: () =>
                          _showContributeSheet(context, goal),
                      onDelete: () async {
                        await provider.deleteGoal(goal.id);
                        if (context.mounted) {
                          showTopToast(context, '${goal.name} deleted');
                        }
                      },
                    );
                  },
                ),
    );
  }

  void _showAddSheet(BuildContext context, String userId) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _AddGoalSheet(userId: userId),
    );
  }

  void _showContributeSheet(BuildContext context, SavingsGoalModel goal) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _ContributeSheet(goal: goal),
    );
  }
}

class _GoalCard extends StatelessWidget {
  final SavingsGoalModel goal;
  final NumberFormat fmt;
  final String currencySymbol;
  final VoidCallback onContribute;
  final VoidCallback onDelete;

  const _GoalCard({
    required this.goal,
    required this.fmt,
    required this.currencySymbol,
    required this.onContribute,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final goalColor = Color(goal.color);
    final pct = goal.progressPercent;
    final barColor = goal.isCompleted
        ? const Color(0xFF2ECC71)
        : pct >= 75
            ? const Color(0xFF5D3891)
            : goalColor;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: cs.surfaceContainerLow,
        borderRadius: BorderRadius.circular(20),
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
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: goalColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(getCategoryIcon(goal.icon),
                    color: goalColor, size: 22),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(goal.name,
                        style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: cs.onSurface)),
                    if (goal.deadline != null)
                      Text(
                        'By ${DateFormat('MMM d, yyyy').format(goal.deadline!)}',
                        style: TextStyle(
                            fontSize: 12,
                            color: cs.onSurfaceVariant),
                      ),
                  ],
                ),
              ),
              if (goal.isCompleted)
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFF2ECC71).withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Text('Done!',
                      style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF2ECC71))),
                ),
              IconButton(
                icon: const Icon(Icons.delete_outline_rounded,
                    color: Colors.red, size: 20),
                onPressed: onDelete,
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(fmt.format(goal.savedAmount),
                  style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: barColor)),
              Text(fmt.format(goal.targetAmount),
                  style: TextStyle(
                      fontSize: 14,
                      color: cs.onSurfaceVariant,
                      fontWeight: FontWeight.w500)),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: pct / 100,
              backgroundColor: barColor.withValues(alpha: 0.15),
              valueColor: AlwaysStoppedAnimation<Color>(barColor),
              minHeight: 10,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('${pct.toStringAsFixed(1)}% saved',
                  style: TextStyle(
                      fontSize: 12,
                      color: barColor,
                      fontWeight: FontWeight.w600)),
              if (!goal.isCompleted)
                GestureDetector(
                  onTap: onContribute,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 6),
                    decoration: BoxDecoration(
                      color: const Color(0xFF5D3891),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Text('+ Add',
                        style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: Colors.white)),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _AddGoalSheet extends StatefulWidget {
  final String userId;
  const _AddGoalSheet({required this.userId});

  @override
  State<_AddGoalSheet> createState() => _AddGoalSheetState();
}

class _AddGoalSheetState extends State<_AddGoalSheet> {
  final _nameCtrl = TextEditingController();
  final _targetCtrl = TextEditingController();
  String _icon = 'savings';
  int _color = 0xFF5D3891;
  DateTime? _deadline;
  bool _saving = false;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _targetCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final name = _nameCtrl.text.trim();
    final target = double.tryParse(_targetCtrl.text.trim()) ?? 0;
    if (name.isEmpty || target <= 0) {
      showTopToast(context, 'Enter a valid name and target', isError: true);
      return;
    }
    setState(() => _saving = true);
    try {
      await context.read<SavingsGoalProvider>().addGoal(
            userId: widget.userId,
            name: name,
            targetAmount: target,
            icon: _icon,
            color: _color,
            deadline: _deadline,
          );
      if (!mounted) return;
      Navigator.pop(context);
      showTopToast(context, 'Goal created!');
    } catch (e) {
      if (!mounted) return;
      showTopToast(context, 'Failed to save goal', isError: true);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    const primary = Color(0xFF5D3891);
    final selectedIcons = [
      'savings', 'flight', 'home', 'laptop', 'directions_car',
      'fitness_center', 'school', 'card_giftcard', 'favorite',
    ];

    return DraggableScrollableSheet(
      initialChildSize: 0.8,
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
                      color: Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(2))),
            ),
            const SizedBox(height: 16),
            Text('New Savings Goal',
                style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: cs.onSurface)),
            const SizedBox(height: 20),
            _field(_nameCtrl, 'Goal name (e.g. Vacation)', cs),
            const SizedBox(height: 12),
            _field(_targetCtrl, 'Target amount', cs,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true)),
            const SizedBox(height: 16),
            Text('Icon',
                style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: cs.onSurface)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 10,
              children: selectedIcons.map((ic) {
                final isSelected = _icon == ic;
                return GestureDetector(
                  onTap: () => setState(() => _icon = ic),
                  child: Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: isSelected
                          ? primary
                          : primary.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(getCategoryIcon(ic),
                        color: isSelected ? Colors.white : primary,
                        size: 22),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 16),
            Text('Color',
                style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: cs.onSurface)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 10,
              children: kColorPool.map((c) {
                final isSelected = _color == c;
                return GestureDetector(
                  onTap: () => setState(() => _color = c),
                  child: Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: Color(c),
                      shape: BoxShape.circle,
                      border: isSelected
                          ? Border.all(
                              color: cs.onSurface, width: 2.5)
                          : null,
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 16),
            GestureDetector(
              onTap: () async {
                final picked = await showDatePicker(
                  context: context,
                  initialDate:
                      DateTime.now().add(const Duration(days: 30)),
                  firstDate: DateTime.now(),
                  lastDate: DateTime.now()
                      .add(const Duration(days: 365 * 5)),
                );
                if (picked != null) setState(() => _deadline = picked);
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
                        _deadline == null
                            ? 'Deadline (optional)'
                            : 'By ${DateFormat('MMM d, yyyy').format(_deadline!)}',
                        style: TextStyle(
                            fontSize: 14,
                            color: _deadline == null
                                ? cs.onSurfaceVariant
                                : cs.onSurface,
                            fontWeight: FontWeight.w500)),
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
                  : const Text('Create Goal',
                      style: TextStyle(
                          fontSize: 16, fontWeight: FontWeight.w700)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _field(TextEditingController ctrl, String label, ColorScheme cs,
      {TextInputType? keyboardType}) =>
      TextField(
        controller: ctrl,
        keyboardType: keyboardType,
        decoration: InputDecoration(
          labelText: label,
          filled: true,
          fillColor: cs.surfaceContainerHighest,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        ),
      );
}

class _ContributeSheet extends StatefulWidget {
  final SavingsGoalModel goal;
  const _ContributeSheet({required this.goal});

  @override
  State<_ContributeSheet> createState() => _ContributeSheetState();
}

class _ContributeSheetState extends State<_ContributeSheet> {
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
          .read<SavingsGoalProvider>()
          .contribute(widget.goal.id, amount);
      if (!mounted) return;
      Navigator.pop(context);
      showTopToast(context, 'Added to ${widget.goal.name}!');
    } catch (e) {
      if (!mounted) return;
      showTopToast(context, 'Failed to update', isError: true);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    const primary = Color(0xFF5D3891);
    return Padding(
      padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Container(
        decoration: BoxDecoration(
          color: cs.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Add to "${widget.goal.name}"',
                style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: cs.onSurface)),
            const SizedBox(height: 16),
            TextField(
              controller: _amountCtrl,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              autofocus: true,
              decoration: InputDecoration(
                labelText: 'Amount',
                filled: true,
                fillColor: cs.surfaceContainerHighest,
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
