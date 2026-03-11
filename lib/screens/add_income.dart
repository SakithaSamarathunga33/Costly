import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/auth_provider.dart';
import '../providers/transaction_provider.dart';
import '../utils/constants.dart';

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
    );
    if (picked != null) {
      setState(() => _selectedDate = picked);
    }
  }

  /// Save the income to MongoDB via provider
  Future<void> _saveIncome() async {
    if (_titleController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Please enter a title'),
            backgroundColor: Colors.red),
      );
      return;
    }
    final amount = double.tryParse(_amountController.text);
    if (amount == null || amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Please enter a valid amount'),
            backgroundColor: Colors.red),
      );
      return;
    }

    setState(() => _isSaving = true);

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final txProvider =
        Provider.of<TransactionProvider>(context, listen: false);

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
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Income added successfully'),
              backgroundColor: Colors.green),
        );
        Navigator.pop(context);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(txProvider.error ?? 'Failed to add income'),
              backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    const Color primary = Color(0xFF00ADB5);
    const Color bgDark = Color(0xFF222831);
    const Color cardDark = Color(0xFF393E46);
    const Color textMain = Color(0xFFEEEEEE);

    return Scaffold(
      backgroundColor: bgDark,
      appBar: AppBar(
        backgroundColor: bgDark,
        elevation: 0,
        title: const Text(
          'Add Income',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: cardDark,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.white.withOpacity(0.05)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title field
                  Text('Title',
                      style: TextStyle(
                          color: textMain.withOpacity(0.9),
                          fontSize: 14,
                          fontWeight: FontWeight.w500)),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _titleController,
                    style: const TextStyle(color: textMain),
                    decoration: _inputDecoration(
                        'e.g. Salary, Freelance...',
                        Icons.description_outlined,
                        bgDark,
                        textMain,
                        primary),
                  ),
                  const SizedBox(height: 20),

                  // Amount field
                  Text('Amount',
                      style: TextStyle(
                          color: textMain.withOpacity(0.9),
                          fontSize: 14,
                          fontWeight: FontWeight.w500)),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _amountController,
                    keyboardType: TextInputType.number,
                    style: const TextStyle(color: textMain),
                    decoration: _inputDecoration(
                        '0.00', Icons.attach_money, bgDark, textMain, primary),
                  ),
                  const SizedBox(height: 20),

                  // Category dropdown
                  Text('Category',
                      style: TextStyle(
                          color: textMain.withOpacity(0.9),
                          fontSize: 14,
                          fontWeight: FontWeight.w500)),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      color: bgDark,
                      borderRadius: BorderRadius.circular(12),
                      border:
                          Border.all(color: Colors.white.withOpacity(0.1)),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: _selectedCategory,
                        isExpanded: true,
                        dropdownColor: cardDark,
                        style: const TextStyle(color: textMain),
                        items: kIncomeCategories.map((cat) {
                          return DropdownMenuItem<String>(
                            value: cat['name'] as String,
                            child: Row(
                              children: [
                                Icon(
                                    getCategoryIcon(cat['icon'] as String),
                                    color: Color(cat['color'] as int),
                                    size: 20),
                                const SizedBox(width: 12),
                                Text(cat['name'] as String),
                              ],
                            ),
                          );
                        }).toList(),
                        onChanged: (value) {
                          if (value != null) {
                            setState(() => _selectedCategory = value);
                          }
                        },
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Date picker
                  Text('Date',
                      style: TextStyle(
                          color: textMain.withOpacity(0.9),
                          fontSize: 14,
                          fontWeight: FontWeight.w500)),
                  const SizedBox(height: 8),
                  InkWell(
                    onTap: _pickDate,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 16),
                      decoration: BoxDecoration(
                        color: bgDark,
                        borderRadius: BorderRadius.circular(12),
                        border:
                            Border.all(color: Colors.white.withOpacity(0.1)),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.calendar_today,
                              color: textMain.withOpacity(0.4), size: 20),
                          const SizedBox(width: 12),
                          Text(
                            DateFormat('MMMM dd, yyyy')
                                .format(_selectedDate),
                            style: const TextStyle(
                                color: textMain, fontSize: 16),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Notes field
                  Text('Notes (optional)',
                      style: TextStyle(
                          color: textMain.withOpacity(0.9),
                          fontSize: 14,
                          fontWeight: FontWeight.w500)),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _notesController,
                    maxLines: 3,
                    style: const TextStyle(color: textMain),
                    decoration: _inputDecoration('Add notes...',
                        Icons.note_outlined, bgDark, textMain, primary),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            // Save button
            ElevatedButton(
              onPressed: _isSaving ? null : _saveIncome,
              style: ElevatedButton.styleFrom(
                backgroundColor: primary,
                foregroundColor: Colors.white,
                minimumSize: const Size(double.infinity, 56),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
                elevation: 4,
                shadowColor: primary.withOpacity(0.5),
              ),
              child: _isSaving
                  ? const SizedBox(
                      height: 24,
                      width: 24,
                      child: CircularProgressIndicator(
                          color: Colors.white, strokeWidth: 2))
                  : const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.save_outlined, size: 20),
                        SizedBox(width: 8),
                        Text('Save Income',
                            style: TextStyle(
                                fontSize: 16, fontWeight: FontWeight.bold)),
                      ],
                    ),
            ),
          ],
        ),
      ),
    );
  }

  InputDecoration _inputDecoration(
      String hint, IconData icon, Color bgDark, Color textMain, Color primary) {
    return InputDecoration(
      hintText: hint,
      hintStyle: TextStyle(color: textMain.withOpacity(0.3)),
      filled: true,
      fillColor: bgDark,
      prefixIcon: Icon(icon, color: textMain.withOpacity(0.4)),
      border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.white.withOpacity(0.1))),
      enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.white.withOpacity(0.1))),
      focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: primary, width: 2)),
      contentPadding: const EdgeInsets.symmetric(vertical: 16),
    );
  }
}
