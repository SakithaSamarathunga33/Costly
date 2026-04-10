import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../models/transaction_model.dart';
import '../providers/auth_provider.dart';
import '../providers/category_provider.dart';
import '../providers/transaction_provider.dart';
import '../utils/constants.dart';
import '../utils/keyboard_dialog_insets.dart';
import '../utils/top_toast.dart';
import '../widgets/category_icon_picker_grid.dart';
import '../widgets/app_animations.dart';

class EditTransactionScreen extends StatefulWidget {
  final TransactionModel transaction;

  const EditTransactionScreen({
    super.key,
    required this.transaction,
  });

  @override
  State<EditTransactionScreen> createState() => _EditTransactionScreenState();
}

class _EditTransactionScreenState extends State<EditTransactionScreen> {
  final _titleController = TextEditingController();
  final _amountController = TextEditingController();
  final _notesController = TextEditingController();

  late String _selectedType;
  late String _selectedCategory;
  late DateTime _selectedDate;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();

    final tx = widget.transaction;
    _titleController.text = tx.title;
    _amountController.text = tx.amount.toStringAsFixed(2);
    _notesController.text = tx.notes;
    _selectedType = tx.type;
    _selectedCategory = tx.category;
    _selectedDate = tx.date;

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
      lastDate: DateTime.now().add(const Duration(days: 3650)),
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

  Future<void> _saveChanges() async {
    if (_titleController.text.trim().isEmpty) {
      showTopToast(context, 'Please enter a title', isError: true);
      return;
    }

    final amount = double.tryParse(_amountController.text.trim());
    if (amount == null || amount <= 0) {
      showTopToast(context, 'Please enter a valid amount', isError: true);
      return;
    }

    setState(() => _isSaving = true);

    final txProvider = Provider.of<TransactionProvider>(context, listen: false);

    final updatedTx = widget.transaction.copyWith(
      title: _titleController.text.trim(),
      amount: amount,
      type: _selectedType,
      category: _selectedCategory,
      date: _selectedDate,
      notes: _notesController.text.trim(),
    );

    final success = await txProvider.updateTransaction(updatedTx);

    if (!mounted) return;
    setState(() => _isSaving = false);

    if (success) {
      showTopToast(context, 'Transaction updated successfully');
      Navigator.pop(context);
    } else {
      showTopToast(
        context,
        txProvider.error ?? 'Failed to update transaction',
        isError: true,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    const Color primary = Color(0xFF5D3891);
    const Color bg = Color(0xFFF8F6FC);
    const Color textMain = Color(0xFF2D2D2D);

    final catProvider = Provider.of<CategoryProvider>(context);
    final categories = _selectedType == 'expense'
        ? [
            ...kExpenseCategories,
            ...catProvider.customExpenseCategories,
          ]
        : [
            ...kIncomeCategories,
            ...catProvider.customIncomeCategories,
          ];

    final hasSelectedCategory =
        categories.any((c) => c['name'] == _selectedCategory);
    if (!hasSelectedCategory && categories.isNotEmpty) {
      _selectedCategory = categories.first['name'] as String;
    }

    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        backgroundColor: bg,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: textMain),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Edit Transaction',
          style: TextStyle(
            color: textMain,
            fontSize: 18,
            fontWeight: FontWeight.w700,
          ),
        ),
        centerTitle: true,
      ),
      body: ScreenEntrance(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 10, 20, 24),
          child: StaggeredColumn(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
            _sectionLabel('Type'),
            const SizedBox(height: 10),
            SegmentedButton<String>(
              segments: const [
                ButtonSegment<String>(
                  value: 'expense',
                  label: Text('Expense'),
                  icon: Icon(Icons.arrow_circle_up_outlined),
                ),
                ButtonSegment<String>(
                  value: 'income',
                  label: Text('Income'),
                  icon: Icon(Icons.arrow_circle_down_outlined),
                ),
              ],
              selected: {_selectedType},
              onSelectionChanged: (selection) {
                setState(() {
                  _selectedType = selection.first;
                  final defaults = _selectedType == 'expense'
                      ? kExpenseCategories
                      : kIncomeCategories;
                  _selectedCategory = defaults.first['name'] as String;
                });
              },
              style: ButtonStyle(
                foregroundColor: MaterialStateProperty.resolveWith((states) {
                  if (states.contains(MaterialState.selected)) {
                    return primary;
                  }
                  return const Color(0xFF2D2D2D);
                }),
                backgroundColor: MaterialStateProperty.resolveWith((states) {
                  if (states.contains(MaterialState.selected)) {
                    return primary.withOpacity(0.15);
                  }
                  return Colors.white;
                }),
              ),
            ),
            const SizedBox(height: 18),
            _sectionLabel('Title'),
            const SizedBox(height: 10),
            TextField(
              controller: _titleController,
              decoration: _fieldDecoration('Transaction title'),
            ),
            const SizedBox(height: 18),
            _sectionLabel('Amount'),
            const SizedBox(height: 10),
            TextField(
              controller: _amountController,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              decoration: _fieldDecoration('0.00'),
            ),
            const SizedBox(height: 18),
            _sectionLabel('Category'),
            const SizedBox(height: 10),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                ...categories.map((cat) {
                  final name = cat['name'] as String;
                  final icon = getCategoryIcon(cat['icon'] as String);
                  final color = Color(cat['color'] as int);
                  final isSelected = _selectedCategory == name;
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
                        width: 1.4,
                      ),
                      boxShadow: isSelected
                          ? [
                              BoxShadow(
                                color: primary.withOpacity(0.22),
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
                          onTap: () =>
                              setState(() => _selectedCategory = name),
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
                                  color: isSelected ? Colors.white : color,
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  name,
                                  style: TextStyle(
                                    color:
                                        isSelected ? Colors.white : textMain,
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
                              onTap: () => _showEditCategoryDialog(
                                context: context,
                                primary: primary,
                                textMain: textMain,
                                category: cat,
                              ),
                              customBorder: const CircleBorder(),
                              child: Padding(
                                padding:
                                    const EdgeInsets.fromLTRB(4, 4, 10, 4),
                                child: Icon(
                                  Icons.edit_outlined,
                                  size: 18,
                                  color: isSelected
                                      ? Colors.white
                                      : primary,
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  );
                }),
                GestureDetector(
                  onTap: () =>
                      _showAddCategoryDialog(context, primary, textMain),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(30),
                      border: Border.all(
                        color: primary.withOpacity(0.3),
                        width: 1.4,
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
            ),
            const SizedBox(height: 18),
            _sectionLabel('Date'),
            const SizedBox(height: 10),
            InkWell(
              borderRadius: BorderRadius.circular(12),
              onTap: _pickDate,
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 14,
                ),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey.withOpacity(0.22)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.calendar_month_outlined,
                        color: Color(0xFF5D3891)),
                    const SizedBox(width: 10),
                    Text(
                      DateFormat('MMM d, yyyy').format(_selectedDate),
                      style: const TextStyle(
                        color: textMain,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 18),
            _sectionLabel('Notes'),
            const SizedBox(height: 10),
            TextField(
              controller: _notesController,
              minLines: 3,
              maxLines: 5,
              decoration: _fieldDecoration('Optional notes'),
            ),
            const SizedBox(height: 28),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isSaving ? null : _saveChanges,
                style: ElevatedButton.styleFrom(
                  backgroundColor: primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: _isSaving
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Text(
                        'Save Changes',
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
      ),
    );
  }

  Widget _sectionLabel(String label) {
    return Text(
      label,
      style: const TextStyle(
        color: Color(0xFF2D2D2D),
        fontSize: 14,
        fontWeight: FontWeight.w600,
      ),
    );
  }

  void _showAddCategoryDialog(
      BuildContext context, Color primary, Color textMain) {
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
              backgroundColor: Colors.white,
              alignment: Alignment.bottomCenter,
              insetPadding: keyboardAwareDialogInsets(ctx),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      'New Category',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF2D2D2D),
                      ),
                    ),
                    SizedBox(height: imeOpen ? 12 : 20),
                    TextField(
                      autofocus: true,
                      scrollPadding: categoryNameFieldScrollPadding(ctx),
                      onChanged: (v) => setDialogState(() => categoryName = v),
                      style: const TextStyle(
                          fontSize: 15, color: Color(0xFF2D2D2D)),
                      decoration: InputDecoration(
                        hintText: 'Category name',
                        hintStyle: TextStyle(
                            color: textMain.withOpacity(0.3), fontSize: 15),
                        filled: true,
                        fillColor: const Color(0xFFF8F6FC),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide:
                              BorderSide(color: Colors.grey.withOpacity(0.15)),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide:
                              BorderSide(color: Colors.grey.withOpacity(0.15)),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: BorderSide(color: primary, width: 1.5),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 14),
                      ),
                    ),
                    SizedBox(height: imeOpen ? 10 : 18),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        'Color',
                        style: TextStyle(
                          color: textMain.withOpacity(0.6),
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
                          onTap: () => setDialogState(() => selectedColor = c),
                          child: Container(
                            width: 32,
                            height: 32,
                            decoration: BoxDecoration(
                              color: Color(c),
                              shape: BoxShape.circle,
                              border: isActive
                                  ? Border.all(color: textMain, width: 2.5)
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
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        'Icon',
                        style: TextStyle(
                          color: textMain.withOpacity(0.6),
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
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: ElevatedButton(
                        onPressed: categoryName.trim().isEmpty
                            ? null
                            : () async {
                                final authProvider = Provider.of<AuthProvider>(
                                    context,
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
                                  type: _selectedType,
                                );

                                if (!ctx.mounted) return;
                                Navigator.pop(ctx);

                                if (!mounted) return;
                                if (success) {
                                  setState(() {
                                    _selectedCategory = categoryName.trim();
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

  void _showEditCategoryDialog({
    required BuildContext context,
    required Color primary,
    required Color textMain,
    required Map<String, dynamic> category,
  }) {
    final String oldName = category['name'] as String;
    final String categoryId = category['id'] as String;
    final TextEditingController nameController =
        TextEditingController(text: oldName);
    String selectedIcon = category['icon'] as String;
    int selectedColor = category['color'] as int;

    showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setDialogState) {
            final imeOpen = MediaQuery.viewInsetsOf(ctx).bottom > 0;
            return Dialog(
              backgroundColor: Colors.white,
              alignment: Alignment.bottomCenter,
              insetPadding: keyboardAwareDialogInsets(ctx),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      'Edit Category',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF2D2D2D),
                      ),
                    ),
                    SizedBox(height: imeOpen ? 12 : 20),
                    TextField(
                      controller: nameController,
                      autofocus: true,
                      scrollPadding: categoryNameFieldScrollPadding(ctx),
                      onChanged: (_) => setDialogState(() {}),
                      style: const TextStyle(
                          fontSize: 15, color: Color(0xFF2D2D2D)),
                      decoration: InputDecoration(
                        hintText: 'Category name',
                        hintStyle: TextStyle(
                            color: textMain.withOpacity(0.3), fontSize: 15),
                        filled: true,
                        fillColor: const Color(0xFFF8F6FC),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide:
                              BorderSide(color: Colors.grey.withOpacity(0.15)),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide:
                              BorderSide(color: Colors.grey.withOpacity(0.15)),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: BorderSide(color: primary, width: 1.5),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 14),
                      ),
                    ),
                    SizedBox(height: imeOpen ? 10 : 18),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        'Color',
                        style: TextStyle(
                          color: textMain.withOpacity(0.6),
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
                          onTap: () => setDialogState(() => selectedColor = c),
                          child: Container(
                            width: 32,
                            height: 32,
                            decoration: BoxDecoration(
                              color: Color(c),
                              shape: BoxShape.circle,
                              border: isActive
                                  ? Border.all(color: textMain, width: 2.5)
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
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        'Icon',
                        style: TextStyle(
                          color: textMain.withOpacity(0.6),
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
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: ElevatedButton(
                        onPressed: nameController.text.trim().isEmpty
                            ? null
                            : () async {
                                final newName = nameController.text.trim();
                                final authProvider = Provider.of<AuthProvider>(
                                    context,
                                    listen: false);
                                final catProvider =
                                    Provider.of<CategoryProvider>(context,
                                        listen: false);
                                final txProvider =
                                    Provider.of<TransactionProvider>(context,
                                        listen: false);

                                final success =
                                    await catProvider.updateCustomCategory(
                                  userId: authProvider.userId,
                                  categoryId: categoryId,
                                  name: newName,
                                  icon: selectedIcon,
                                  color: selectedColor,
                                  type: _selectedType,
                                );

                                if (!success) {
                                  if (!ctx.mounted) return;
                                  showTopToast(
                                      context, 'Failed to update category',
                                      isError: true);
                                  return;
                                }

                                if (oldName != newName) {
                                  await txProvider.renameCategoryInTransactions(
                                    userId: authProvider.userId,
                                    oldCategory: oldName,
                                    newCategory: newName,
                                    type: _selectedType,
                                  );
                                }

                                if (!ctx.mounted) return;
                                Navigator.pop(ctx);
                                if (!mounted) return;
                                setState(() {
                                  if (_selectedCategory == oldName) {
                                    _selectedCategory = newName;
                                  }
                                });
                                showTopToast(context, 'Category updated');
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
                          'Save Category',
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
    ).then((_) {
      nameController.dispose();
    });
  }

  InputDecoration _fieldDecoration(String hint) {
    return InputDecoration(
      hintText: hint,
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.grey.withOpacity(0.2)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.grey.withOpacity(0.2)),
      ),
      focusedBorder: const OutlineInputBorder(
        borderRadius: BorderRadius.all(Radius.circular(12)),
        borderSide: BorderSide(color: Color(0xFF5D3891)),
      ),
    );
  }
}
