import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/auth_provider.dart';
import '../providers/transaction_provider.dart';
import '../providers/category_provider.dart';
import '../utils/constants.dart';
import '../utils/keyboard_dialog_insets.dart';
import '../widgets/category_icon_picker_grid.dart';
import '../utils/top_toast.dart';
import '../widgets/app_animations.dart';
import '../widgets/tag_input_field.dart';

class AddExpenseScreen extends StatefulWidget {
  const AddExpenseScreen({super.key});

  @override
  State<AddExpenseScreen> createState() => _AddExpenseScreenState();
}

class _AddExpenseScreenState extends State<AddExpenseScreen> {
  final _titleController = TextEditingController();
  final _amountController = TextEditingController();
  final _notesController = TextEditingController();
  String _selectedCategory = 'Food';
  DateTime _selectedDate = DateTime.now();
  List<String> _tags = [];
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final catProvider = Provider.of<CategoryProvider>(context, listen: false);
      if (authProvider.userId.isNotEmpty) {
        catProvider.fetchCustomCategories(authProvider.userId);
      }
    });
  }

  @override
  void dispose() {
    _titleController.dispose();
    _amountController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Color(0xFF5D3891),
              onPrimary: Colors.white,
              surface: Colors.white,
              onSurface: Color(0xFF2D2D2D),
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() => _selectedDate = picked);
    }
  }

  Future<void> _saveExpense() async {
    if (_titleController.text.trim().isEmpty) {
      showTopToast(context, 'Please enter a title', isError: true);
      return;
    }
    final amount = double.tryParse(_amountController.text);
    if (amount == null || amount <= 0) {
      showTopToast(context, 'Please enter a valid amount', isError: true);
      return;
    }

    setState(() => _isSaving = true);

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final txProvider = Provider.of<TransactionProvider>(context, listen: false);

    final success = await txProvider.addExpense(
      userId: authProvider.userId,
      title: _titleController.text,
      amount: amount,
      category: _selectedCategory,
      date: _selectedDate,
      notes: _notesController.text,
      tags: _tags,
    );

    setState(() => _isSaving = false);

    if (mounted) {
      if (success) {
        showTopToast(context, 'Expense added successfully');
        Navigator.pop(context);
      } else {
        showTopToast(context, txProvider.error ?? 'Failed to add expense', isError: true);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    const Color primary = Color(0xFF5D3891);
    final authProvider = Provider.of<AuthProvider>(context);
    final currencySymbol = authProvider.currencySymbol;

    // Display amount
    final amountText = _amountController.text.isEmpty
        ? '0.00'
        : (double.tryParse(_amountController.text)?.toStringAsFixed(2) ??
            '0.00');

    return Scaffold(
      backgroundColor: cs.surface,
      appBar: AppBar(
        backgroundColor: cs.surface,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: cs.onSurface, size: 22),
          onPressed: () => Navigator.pop(context),
        ),
        centerTitle: true,
        title: Text(
          'Add Expense',
          style: TextStyle(
            color: cs.onSurface,
            fontSize: 18,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: ScreenEntrance(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: StaggeredColumn(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                  const SizedBox(height: 8),

                  // ─── Amount Card ───
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 24, vertical: 24),
                    decoration: BoxDecoration(
                      color: cs.surfaceContainerLow,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: primary.withOpacity(0.06),
                          blurRadius: 16,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Amount',
                          style: TextStyle(
                            color: primary.withOpacity(0.7),
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 8),
                        GestureDetector(
                          onTap: () {
                            // Focus amount field via dialog
                            _showAmountInput(context, primary, currencySymbol);
                          },
                          child: Text(
                            '$currencySymbol $amountText',
                            style: const TextStyle(
                              color: primary,
                              fontSize: 36,
                              fontWeight: FontWeight.w700,
                              letterSpacing: -0.5,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // ─── Title Field ───
                  _buildSectionLabel(Icons.edit, 'Title', primary, cs.onSurface),
                  const SizedBox(height: 10),
                  TextField(
                    controller: _titleController,
                    style: TextStyle(color: cs.onSurface, fontSize: 15),
                    decoration: InputDecoration(
                      hintText: 'e.g. Grocery Shopping',
                      hintStyle: TextStyle(
                        color: cs.onSurface.withOpacity(0.3),
                        fontSize: 15,
                      ),
                      filled: true,
                      fillColor: cs.surfaceContainerLow,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: BorderSide(
                            color: Colors.grey.withOpacity(0.15)),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: BorderSide(
                            color: Colors.grey.withOpacity(0.15)),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide:
                            const BorderSide(color: primary, width: 1.5),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 16),
                    ),
                  ),
                  const SizedBox(height: 22),

                  // ─── Date Field ───
                  _buildSectionLabel(
                      Icons.calendar_today, 'Date', primary, cs.onSurface),
                  const SizedBox(height: 10),
                  GestureDetector(
                    onTap: _pickDate,
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 16),
                      decoration: BoxDecoration(
                        color: cs.surfaceContainerLow,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                            color: Colors.grey.withOpacity(0.15)),
                      ),
                      child: Row(
                        children: [
                          Text(
                            DateFormat('MM/dd/yyyy').format(_selectedDate),
                            style: TextStyle(
                              color: cs.onSurface,
                              fontSize: 15,
                            ),
                          ),
                          const Spacer(),
                          Icon(Icons.calendar_today,
                              color: cs.onSurface.withOpacity(0.3), size: 20),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 22),

                  // ─── Category Chips ───
                  _buildSectionLabel(
                      Icons.category, 'Category', primary, cs.onSurface),
                  const SizedBox(height: 12),
                  Consumer<CategoryProvider>(
                    builder: (context, catProvider, _) {
                      final allCategories = [
                        ...kExpenseCategories,
                        ...catProvider.customExpenseCategories,
                      ];
                      return Wrap(
                        spacing: 10,
                        runSpacing: 10,
                        children: [
                          ...allCategories.map((cat) {
                            final name = cat['name'] as String;
                            final isSelected = name == _selectedCategory;
                            final icon =
                                getCategoryIcon(cat['icon'] as String);
                            final color = Color(cat['color'] as int);
                            final isCustom = cat.containsKey('id');

                            return AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              padding: const EdgeInsets.symmetric(vertical: 10),
                              decoration: BoxDecoration(
                                color: isSelected ? primary : Colors.white,
                                borderRadius: BorderRadius.circular(30),
                                border: Border.all(
                                  color: isSelected
                                      ? primary
                                      : Colors.grey.withOpacity(0.2),
                                  width: 1.5,
                                ),
                                boxShadow: isSelected
                                    ? [
                                        BoxShadow(
                                          color: primary.withOpacity(0.25),
                                          blurRadius: 8,
                                          offset: const Offset(0, 2),
                                        ),
                                      ]
                                    : [],
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  GestureDetector(
                                    onTap: () {
                                      setState(() => _selectedCategory = name);
                                    },
                                    behavior: HitTestBehavior.opaque,
                                    child: Padding(
                                      padding: EdgeInsets.only(
                                        left: 14,
                                        right: isCustom ? 2 : 14,
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(
                                            icon,
                                            size: 16,
                                            color: isSelected
                                                ? Colors.white
                                                : color,
                                          ),
                                          const SizedBox(width: 6),
                                          Text(
                                            name,
                                            style: TextStyle(
                                              color: isSelected
                                                  ? Colors.white
                                                  : cs.onSurface,
                                              fontSize: 13,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                  if (isCustom)
                                    Material(
                                      color: Colors.transparent,
                                      child: InkWell(
                                        onTap: () =>
                                            _showDeleteCategoryDialog(
                                          context,
                                          cat,
                                          primary,
                                        ),
                                        customBorder: const CircleBorder(),
                                        child: Padding(
                                          padding: const EdgeInsets.fromLTRB(
                                              4, 4, 10, 4),
                                          child: Icon(
                                            Icons.close_rounded,
                                            size: 18,
                                            color: isSelected
                                                ? Colors.white
                                                : Colors.red.shade400,
                                          ),
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                            );
                          }),
                          // ─── Add Custom Category (+) chip ───
                          GestureDetector(
                            onTap: () => _showAddCategoryDialog(
                                context, primary, cs.onSurface),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 14, vertical: 10),
                              decoration: BoxDecoration(
                                color: cs.surfaceContainerLow,
                                borderRadius: BorderRadius.circular(30),
                                border: Border.all(
                                  color: primary.withOpacity(0.3),
                                  width: 1.5,
                                  style: BorderStyle.solid,
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.add_circle_outline,
                                      size: 16, color: primary),
                                  const SizedBox(width: 6),
                                  Text(
                                    'Add',
                                    style: TextStyle(
                                      color: primary,
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                  const SizedBox(height: 22),

                  // ─── Tags ───
                  _buildSectionLabel(
                      Icons.label_outline, 'Tags', primary, cs.onSurface),
                  const SizedBox(height: 10),
                  TagInputField(
                    tags: _tags,
                    onChanged: (updated) => setState(() => _tags = updated),
                  ),
                  const SizedBox(height: 22),

                  // ─── Notes Field ───
                  _buildSectionLabel(
                      Icons.notes, 'Optional Notes', primary, cs.onSurface),
                  const SizedBox(height: 10),
                  TextField(
                    controller: _notesController,
                    maxLines: 4,
                    style: TextStyle(color: cs.onSurface, fontSize: 15),
                    decoration: InputDecoration(
                      hintText: 'Add additional details...',
                      hintStyle: TextStyle(
                        color: cs.onSurface.withOpacity(0.3),
                        fontSize: 15,
                      ),
                      filled: true,
                      fillColor: cs.surfaceContainerLow,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: BorderSide(
                            color: Colors.grey.withOpacity(0.15)),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: BorderSide(
                            color: Colors.grey.withOpacity(0.15)),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide:
                            const BorderSide(color: primary, width: 1.5),
                      ),
                      contentPadding: const EdgeInsets.all(16),
                    ),
                  ),
                  const SizedBox(height: 30),
                ],
              ),
            ),
            ),
          ),

          // ─── Save Button ───
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 0, 24, 32),
            child: SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: _isSaving ? null : _saveExpense,
                style: ElevatedButton.styleFrom(
                  backgroundColor: primary,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(28),
                  ),
                  shadowColor: primary.withOpacity(0.4),
                ),
                child: _isSaving
                    ? const SizedBox(
                        height: 24,
                        width: 24,
                        child: CircularProgressIndicator(
                            color: Colors.white, strokeWidth: 2.5))
                    : const Text(
                        'Save Expense',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.3,
                        ),
                      ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ─── Delete custom category confirmation ───
  void _showDeleteCategoryDialog(
      BuildContext context, Map<String, dynamic> cat, Color primary) {
    final cs = Theme.of(context).colorScheme;
    final name = cat['name'] as String;
    final categoryId = cat['id'] as String;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: cs.surfaceContainerLow,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          'Delete Category',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: cs.onSurface,
          ),
        ),
        content: Text(
          'Delete "$name" and all expenses/income related to this category?',
          style: TextStyle(
            fontSize: 14,
            color: cs.onSurface,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(
              'Cancel',
              style: TextStyle(
                color: cs.onSurfaceVariant,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () async {
              final authProvider =
                  Provider.of<AuthProvider>(context, listen: false);
              final catProvider =
                  Provider.of<CategoryProvider>(context, listen: false);
              final txProvider =
                  Provider.of<TransactionProvider>(context, listen: false);

              // Delete related transactions
              await txProvider.deleteTransactionsByCategory(
                  authProvider.userId, name);

              // Delete the category
              await catProvider.deleteCustomCategory(
                userId: authProvider.userId,
                categoryId: categoryId,
              );

              if (!ctx.mounted) return;
              Navigator.pop(ctx);

              // Reset selection if the deleted category was selected
              if (_selectedCategory == name) {
                setState(() => _selectedCategory = 'Food');
              }

              if (!context.mounted) return;
              showTopToast(context, '"$name" category deleted');
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text(
              'Delete',
              style: TextStyle(fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
  }

  // ─── Add custom category dialog ───
  void _showAddCategoryDialog(
      BuildContext context, Color primary, Color textMain) {
    final cs = Theme.of(context).colorScheme;
    String categoryName = '';
    String selectedIcon = 'restaurant';
    int selectedColor = kColorPool[0];

    showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setDialogState) {
            final imeOpen = MediaQuery.viewInsetsOf(ctx).bottom > 0;
            return Dialog(
              backgroundColor: cs.surfaceContainerLow,
              alignment: Alignment.bottomCenter,
              insetPadding: keyboardAwareDialogInsets(ctx),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20)),
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'New Category',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: cs.onSurface,
                      ),
                    ),
                    SizedBox(height: imeOpen ? 12 : 20),

                    // Category name field
                    TextField(
                      autofocus: true,
                      scrollPadding: categoryNameFieldScrollPadding(ctx),
                      onChanged: (v) =>
                          setDialogState(() => categoryName = v),
                      style:
                          TextStyle(fontSize: 15, color: cs.onSurface),
                      decoration: InputDecoration(
                        hintText: 'Category name',
                        hintStyle: TextStyle(
                            color: cs.onSurface.withOpacity(0.3), fontSize: 15),
                        filled: true,
                        fillColor: cs.surfaceContainerHighest,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: BorderSide(
                              color: Colors.grey.withOpacity(0.15)),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: BorderSide(
                              color: Colors.grey.withOpacity(0.15)),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide:
                              BorderSide(color: primary, width: 1.5),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 14),
                      ),
                    ),
                    SizedBox(height: imeOpen ? 10 : 18),

                    // Color picker
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        'Color',
                        style: TextStyle(
                          color: cs.onSurface.withOpacity(0.6),
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 10,
                      runSpacing: 10,
                      children: kColorPool.map((c) {
                        final isActive = c == selectedColor;
                        return GestureDetector(
                          onTap: () =>
                              setDialogState(() => selectedColor = c),
                          child: Container(
                            width: 32,
                            height: 32,
                            decoration: BoxDecoration(
                              color: Color(c),
                              shape: BoxShape.circle,
                              border: isActive
                                  ? Border.all(
                                      color: cs.onSurface, width: 2.5)
                                  : null,
                            ),
                            child: isActive
                                ? const Icon(Icons.check,
                                    color: Colors.white, size: 16)
                                : null,
                          ),
                        );
                      }).toList(),
                    ),
                    SizedBox(height: imeOpen ? 8 : 18),

                    // Icon picker
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        'Icon',
                        style: TextStyle(
                          color: cs.onSurface.withOpacity(0.6),
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    SizedBox(height: imeOpen ? 6 : 10),
                    CategoryIconPickerGrid(
                      selectedIcon: selectedIcon,
                      selectedColor: selectedColor,
                      primary: primary,
                      onIconSelected: (key) =>
                          setDialogState(() => selectedIcon = key),
                    ),
                    SizedBox(height: imeOpen ? 12 : 20),

                    // Save button
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: ElevatedButton(
                        onPressed: categoryName.trim().isEmpty
                            ? null
                            : () async {
                                final authProvider =
                                    Provider.of<AuthProvider>(context,
                                        listen: false);
                                final catProvider =
                                    Provider.of<CategoryProvider>(context,
                                        listen: false);

                                final success =
                                    await catProvider.addCustomCategory(
                                  userId: authProvider.userId,
                                  name: categoryName.trim(),
                                  icon: selectedIcon,
                                  color: selectedColor,
                                  type: 'expense',
                                );

                                if (!ctx.mounted) return;
                                Navigator.pop(ctx);

                                if (success) {
                                  setState(() {
                                    _selectedCategory =
                                        categoryName.trim();
                                  });
                                }
                              },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: primary,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(24),
                          ),
                        ),
                        child: const Text(
                          'Add Category',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  // ─── Section label with icon ───
  Widget _buildSectionLabel(
      IconData icon, String label, Color primary, Color textMain) {
    return Row(
      children: [
        Icon(icon, size: 18, color: primary),
        const SizedBox(width: 8),
        Text(
          label,
          style: TextStyle(
            color: textMain.withOpacity(0.8),
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  // ─── Amount input dialog ───
  void _showAmountInput(BuildContext context, Color primary, String currencySymbol) {
    final cs = Theme.of(context).colorScheme;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: cs.surfaceContainerLow,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(
          left: 24,
          right: 24,
          top: 24,
          bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Enter Amount',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: cs.onSurface,
              ),
            ),
            const SizedBox(height: 20),
            TextField(
              controller: _amountController,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              autofocus: true,
              style: const TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.w700,
                color: Color(0xFF5D3891),
              ),
              textAlign: TextAlign.center,
              decoration: InputDecoration(
                prefixText: '$currencySymbol ',
                prefixStyle: const TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF5D3891),
                ),
                hintText: '0.00',
                hintStyle: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF5D3891).withOpacity(0.3),
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide(
                      color: Colors.grey.withOpacity(0.2)),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide(
                      color: Colors.grey.withOpacity(0.2)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide:
                      const BorderSide(color: Color(0xFF5D3891), width: 2),
                ),
                contentPadding: const EdgeInsets.symmetric(
                    horizontal: 20, vertical: 16),
              ),
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(ctx),
                style: ElevatedButton.styleFrom(
                  backgroundColor: primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(25),
                  ),
                ),
                child: const Text(
                  'Done',
                  style: TextStyle(
                      fontSize: 16, fontWeight: FontWeight.w600),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
