import 'package:flutter/material.dart';
import '../models/transaction_model.dart';
import '../services/transaction_service.dart';

/// TransactionProvider manages all transaction data and calculations
class TransactionProvider extends ChangeNotifier {
  final TransactionService _transactionService = TransactionService();

  List<TransactionModel> _transactions = [];
  bool _isLoading = false;
  String? _error;

  /// First day of the month being viewed (home, history, analytics).
  DateTime _selectedMonth =
      DateTime(DateTime.now().year, DateTime.now().month, 1);

  DateTime get selectedMonth => _selectedMonth;

  /// True when [selectedMonth] is the actual current calendar month.
  bool get isViewingCurrentMonth {
    final n = DateTime.now();
    return _selectedMonth.year == n.year && _selectedMonth.month == n.month;
  }

  bool get canGoToNextMonth {
    final n = DateTime.now();
    final cur = DateTime(n.year, n.month, 1);
    return _selectedMonth.isBefore(cur);
  }

  void setSelectedMonth(DateTime month) {
    final normalized = DateTime(month.year, month.month, 1);
    final n = DateTime.now();
    final latest = DateTime(n.year, n.month, 1);
    if (normalized.isAfter(latest)) return;
    _selectedMonth = normalized;
    notifyListeners();
  }

  void goToPreviousMonth() {
    setSelectedMonth(
        DateTime(_selectedMonth.year, _selectedMonth.month - 1, 1));
  }

  void goToNextMonth() {
    if (!canGoToNextMonth) return;
    setSelectedMonth(
        DateTime(_selectedMonth.year, _selectedMonth.month + 1, 1));
  }

  bool _inSelectedMonth(TransactionModel t) =>
      t.date.year == _selectedMonth.year &&
      t.date.month == _selectedMonth.month;

  /// Transactions in the globally selected month (used across dashboard, history, analytics).
  List<TransactionModel> get transactions =>
      _transactions.where(_inSelectedMonth).toList();

  bool get isLoading => _isLoading;
  String? get error => _error;

  // Calculated values from transactions in [selectedMonth]
  double get totalIncome => transactions
      .where((t) => t.type == 'income')
      .fold(0.0, (sum, t) => sum + t.amount);

  double get totalExpenses => transactions
      .where((t) => t.type == 'expense')
      .fold(0.0, (sum, t) => sum + t.amount);

  /// Income minus expenses for the selected month.
  double get currentBalance => totalIncome - totalExpenses;

  /// Get recent transactions (latest 5) within the selected month
  List<TransactionModel> get recentTransactions {
    final sorted = List<TransactionModel>.from(transactions)
      ..sort((a, b) => b.date.compareTo(a.date));
    return sorted.take(5).toList();
  }

  /// Get only expenses in selected month
  List<TransactionModel> get expenses =>
      transactions.where((t) => t.type == 'expense').toList();

  /// Get only income in selected month
  List<TransactionModel> get incomeList =>
      transactions.where((t) => t.type == 'income').toList();

  /// Get expenses grouped by category with totals (selected month)
  Map<String, double> get expensesByCategory {
    final map = <String, double>{};
    for (var t in expenses) {
      map[t.category] = (map[t.category] ?? 0) + t.amount;
    }
    return map;
  }

  /// Monthly expense totals for Jan–Dec of [selectedMonth]'s year (legacy / unused in UI).
  Map<int, double> get monthlyExpenses {
    final y = _selectedMonth.year;
    final map = <int, double>{};
    for (int i = 1; i <= 12; i++) {
      map[i] = 0;
    }
    for (var t in _transactions) {
      if (t.type == 'expense' && t.date.year == y) {
        map[t.date.month] = (map[t.date.month] ?? 0) + t.amount;
      }
    }
    return map;
  }

  /// Last 6 months ending at [selectedMonth]: expense totals (oldest → newest).
  List<double> get rollingSixMonthExpenseTotals {
    final out = <double>[];
    for (int i = 5; i >= 0; i--) {
      final m = DateTime(_selectedMonth.year, _selectedMonth.month - i, 1);
      double sum = 0;
      for (final t in _transactions) {
        if (t.type == 'expense' &&
            t.date.year == m.year &&
            t.date.month == m.month) {
          sum += t.amount;
        }
      }
      out.add(sum);
    }
    return out;
  }

  /// Short labels for [rollingSixMonthExpenseTotals] (same order).
  List<String> get rollingSixMonthLabels {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    final out = <String>[];
    for (int i = 5; i >= 0; i--) {
      final m = DateTime(_selectedMonth.year, _selectedMonth.month - i, 1);
      out.add(months[m.month - 1]);
    }
    return out;
  }

  /// Get monthly income totals for the current year
  Map<int, double> get monthlyIncome {
    final now = DateTime.now();
    final map = <int, double>{};
    for (int i = 1; i <= 12; i++) {
      map[i] = 0;
    }
    for (var t in _transactions) {
      if (t.type == 'income' && t.date.year == now.year) {
        map[t.date.month] = (map[t.date.month] ?? 0) + t.amount;
      }
    }
    return map;
  }

  /// Fetch all transactions for the logged-in user
  Future<void> fetchTransactions(String userId) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _transactions = await _transactionService.getTransactions(userId);
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = 'Failed to load transactions: ${e.toString()}';
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Add a new expense
  Future<bool> addExpense({
    required String userId,
    required String title,
    required double amount,
    required String category,
    required DateTime date,
    String notes = '',
  }) async {
    _error = null;
    try {
      final transaction = await _transactionService.addTransaction(
        userId: userId,
        title: title,
        amount: amount,
        type: 'expense',
        category: category,
        date: date,
        notes: notes,
      );
      _transactions.insert(0, transaction);
      // Re-sort by date
      _transactions.sort((a, b) => b.date.compareTo(a.date));
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString().replaceFirst('Exception: ', '');
      notifyListeners();
      return false;
    }
  }

  /// Add a new income
  Future<bool> addIncome({
    required String userId,
    required String title,
    required double amount,
    required String category,
    required DateTime date,
    String notes = '',
  }) async {
    _error = null;
    try {
      final transaction = await _transactionService.addTransaction(
        userId: userId,
        title: title,
        amount: amount,
        type: 'income',
        category: category,
        date: date,
        notes: notes,
      );
      _transactions.insert(0, transaction);
      _transactions.sort((a, b) => b.date.compareTo(a.date));
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString().replaceFirst('Exception: ', '');
      notifyListeners();
      return false;
    }
  }

  /// Delete all transactions in a category
  Future<bool> deleteTransactionsByCategory(
      String userId, String category) async {
    try {
      await _transactionService.deleteTransactionsByCategory(userId, category);
      _transactions.removeWhere((t) => t.category == category);
      notifyListeners();
      return true;
    } catch (e) {
      _error = 'Failed to delete transactions';
      notifyListeners();
      return false;
    }
  }

  /// Delete a transaction
  Future<bool> deleteTransaction(String transactionId) async {
    try {
      await _transactionService.deleteTransaction(transactionId);
      _transactions.removeWhere((t) => t.id == transactionId);
      notifyListeners();
      return true;
    } catch (e) {
      _error = 'Failed to delete transaction';
      notifyListeners();
      return false;
    }
  }

  /// Update a transaction
  Future<bool> updateTransaction(TransactionModel transaction) async {
    _error = null;
    try {
      await _transactionService.updateTransaction(transaction);
      final index = _transactions.indexWhere((t) => t.id == transaction.id);
      if (index != -1) {
        _transactions[index] = transaction;
      }
      _transactions.sort((a, b) => b.date.compareTo(a.date));
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString().replaceFirst('Exception: ', '');
      notifyListeners();
      return false;
    }
  }

  /// Rename a category in all local and remote transactions for a user
  Future<bool> renameCategoryInTransactions({
    required String userId,
    required String oldCategory,
    required String newCategory,
    required String type,
  }) async {
    _error = null;
    try {
      await _transactionService.renameCategoryInTransactions(
        userId: userId,
        oldCategory: oldCategory,
        newCategory: newCategory,
        type: type,
      );

      _transactions = _transactions.map((t) {
        if (t.type == type && t.category == oldCategory) {
          return t.copyWith(category: newCategory);
        }
        return t;
      }).toList();

      notifyListeners();
      return true;
    } catch (e) {
      _error = 'Failed to update category in transactions';
      notifyListeners();
      return false;
    }
  }

  /// Net cash flow for a calendar month (income adds, expenses subtract).
  double netCashFlowForMonth(DateTime monthStart) {
    final y = monthStart.year;
    final m = monthStart.month;
    return _transactions
        .where((t) => t.date.year == y && t.date.month == m)
        .fold<double>(0, (sum, tx) {
      if (tx.type == 'income') return sum + tx.amount;
      return sum - tx.amount;
    });
  }

  /// Clear all data (used on logout)
  void clear() {
    _transactions = [];
    _error = null;
    _selectedMonth = DateTime(DateTime.now().year, DateTime.now().month, 1);
    notifyListeners();
  }
}
