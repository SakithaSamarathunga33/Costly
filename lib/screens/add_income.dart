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

class AddIncomeScreen extends StatefulWidget {
  const AddIncomeScreen({super.key});

  @override
  State<AddIncomeScreen> createState() => _AddIncomeScreenState();
}

class _AddIncomeScreenState extends State<AddIncomeScreen> {
  final _titleController = TextEditingController();
  final _amountController = TextEditingController();
  final _notesController = TextEditingController();
  String _selectedCategory = 'Salary';
  DateTime _selectedDate = DateTime.now();
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

  Future<void> _saveIncome() async {
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

    final success = await txProvider.addIncome(
      userId: authProvider.userId,
      title: _titleController.text,
      amount: amount,
      category: _selectedCategory,
      date: _selectedDate,
      notes: _notesController.text,
    );

    setState(() => _isSaving = false);

    if (mounted) {
      if (success) {
        showTopToast(context, 'Income added successfully');
        Navigator.pop(context);
      } else {
        showTopToast(context, txProvider.error ?? 'Failed to add income', isError: true);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    const Color primary = Color(0xFF5D3891);
    const Color bg = Color(0xFFF8F6FC);
    const Color textMain = Color(0xFF2D2D2D);
    const Color fieldBg = Colors.white;

    final authProvider = Provider.of<AuthProvider>(context);
    final currencySymbol = authProvider.currencySymbol;

    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        backgroundColor: bg,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: textMain, size: 22),
          onPressed: () => Navigator.pop(context),
        ),
        centerTitle: true,
        title: const Text(
          'Add Income',
          style: TextStyle(
            color: textMain,
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
                  const SizedBox(height: 12),

                  // ─── Title Field ───
                  const Text(
                    'Title',
                    style: TextStyle(
                      color: textMain,
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: _titleController,
                    style: const TextStyle(color: textMain, fontSize: 15),
                    decoration: _fieldDecoration(
                      hint: 'e.g. Monthly Salary',
                      fieldBg: fieldBg,
                      textMain: textMain,
                      primary: primary,
                    ),
                  ),
                  const SizedBox(height: 22),

                  // ─── Amount Field ───
                  const Text(
                    'Amount',
                    style: TextStyle(
                      color: textMain,
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: _amountController,
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    style: const TextStyle(color: textMain, fontSize: 15),
                    decoration: InputDecoration(
                      hintText: '0.00',
                      hintStyle: TextStyle(
                        color: textMain.withOpacity(0.3),
                        fontSize: 15,
                      ),
                      prefixIcon: Container(
                        width: 20,
                        alignment: Alignment.center,
                        child: Text(
                          '$currencySymbol ',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: primary.withOpacity(0.5),
                          ),
                        ),
                      ),
                      suffixText: authProvider.userCurrency,
                      suffixStyle: TextStyle(
                        color: textMain.withOpacity(0.5),
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                      filled: true,
                      fillColor: fieldBg,
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
                  const Text(
                    'Date',
                    style: TextStyle(
                      color: textMain,
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 10),
                  GestureDetector(
                    onTap: _pickDate,
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 16),
                      decoration: BoxDecoration(
                        color: fieldBg,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                            color: Colors.grey.withOpacity(0.15)),
                      ),
                      child: Row(
                        children: [
                          Text(
                            DateFormat('MM/dd/yyyy').format(_selectedDate),
                            style: const TextStyle(
                              color: textMain,
                              fontSize: 15,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Icon(Icons.calendar_today,
                              color: textMain.withOpacity(0.3), size: 18),
                          const Spacer(),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 22),

                  // ─── Source Dropdown ───
                  const Text(
                    'Source',
                    style: TextStyle(
                      color: textMain,
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                    decoration: BoxDecoration(
                      color: fieldBg,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                          color: Colors.grey.withOpacity(0.15)),
                    ),
                    child: Consumer<CategoryProvider>(
                      builder: (context, catProvider, _) {
                        final allCategories = [
                          ...kIncomeCategories,
                          ...catProvider.customIncomeCategories,
                        ];
                        return DropdownButtonHideUnderline(
                          child: DropdownButton<String>(
                            value: allCategories
                                    .any((c) => c['name'] == _selectedCategory)
                                ? _selectedCategory
                                : null,
                            isExpanded: true,
                            icon: Icon(Icons.keyboard_arrow_down,
                                color: textMain.withOpacity(0.4)),
                            dropdownColor: Colors.white,
                            style: const TextStyle(
                                color: textMain, fontSize: 15),
                            items: allCategories.map((cat) {
                              return DropdownMenuItem<String>(
                                value: cat['name'] as String,
                                child: Text(cat['name'] as String),
                              );
                            }).toList(),
                            onChanged: (value) {
                              if (value != null) {
                                setState(() => _selectedCategory = value);
                              }
                            },
                            hint: Text(
                              'Select income source',
                              style: TextStyle(
                                color: textMain.withOpacity(0.3),
                                fontSize: 15,
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 14),

                  // ─── Source Chips ───
                  Consumer<CategoryProvider>(
                    builder: (context, catProvider, _) {
                      final allCategories = [
                        ...kIncomeCategories,
                        ...catProvider.customIncomeCategories,
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
                                                  : textMain,
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
                                context, primary, textMain),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 14, vertical: 10),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(30),
                                border: Border.all(
                                  color: primary.withOpacity(0.3),
                                  width: 1.5,
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

                  // ─── Notes Field ───
                  const Text(
                    'Notes (Optional)',
                    style: TextStyle(
                      color: textMain,
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: _notesController,
                    maxLines: 4,
                    style: const TextStyle(color: textMain, fontSize: 15),
                    decoration: _fieldDecoration(
                      hint: 'Add a description...',
                      fieldBg: fieldBg,
                      textMain: textMain,
                      primary: primary,
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
                onPressed: _isSaving ? null : _saveIncome,
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
                    : const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.check_circle, size: 20),
                          SizedBox(width: 8),
                          Text(
                            'Save Income',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.3,
                            ),
                          ),
                        ],
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
    final name = cat['name'] as String;
    final categoryId = cat['id'] as String;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text(
          'Delete Category',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: Color(0xFF2D2D2D),
          ),
        ),
        content: Text(
          'Delete "$name" and all expenses/income related to this category?',
          style: const TextStyle(
            fontSize: 14,
            color: Color(0xFF2D2D2D),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(
              'Cancel',
              style: TextStyle(
                color: const Color(0xFF2D2D2D).withOpacity(0.5),
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
                setState(() => _selectedCategory = 'Salary');
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
    String categoryName = '';
    String selectedIcon = 'payments';
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
                  borderRadius: BorderRadius.circular(20)),
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

                    // Category name field
                    TextField(
                      autofocus: true,
                      scrollPadding: categoryNameFieldScrollPadding(ctx),
                      onChanged: (v) =>
                          setDialogState(() => categoryName = v),
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
                                      color: textMain, width: 2.5)
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
                                  type: 'income',
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

  // ─── Reusable field decoration ───
  InputDecoration _fieldDecoration({
    required String hint,
    required Color fieldBg,
    required Color textMain,
    required Color primary,
  }) {
    return InputDecoration(
      hintText: hint,
      hintStyle: TextStyle(
        color: textMain.withOpacity(0.3),
        fontSize: 15,
      ),
      filled: true,
      fillColor: fieldBg,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: Colors.grey.withOpacity(0.15)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: Colors.grey.withOpacity(0.15)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: primary, width: 1.5),
      ),
      contentPadding:
          const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
    );
  }
}
