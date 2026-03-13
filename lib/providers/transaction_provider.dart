import 'package:flutter/material.dart';
import '../models/transaction_model.dart';
import '../services/transaction_service.dart';

/// TransactionProvider manages all transaction data and calculations
class TransactionProvider extends ChangeNotifier {
  final TransactionService _transactionService = TransactionService();

  List<TransactionModel> _transactions = [];
  bool _isLoading = false;
  String? _error;

  List<TransactionModel> get transactions => _transactions;
  bool get isLoading => _isLoading;
  String? get error => _error;

  // Calculated values from transactions
  double get totalIncome => _transactions
      .where((t) => t.type == 'income')
      .fold(0.0, (sum, t) => sum + t.amount);

  double get totalExpenses => _transactions
      .where((t) => t.type == 'expense')
      .fold(0.0, (sum, t) => sum + t.amount);

  double get currentBalance => totalIncome - totalExpenses;

  /// Get recent transactions (latest 5)
  List<TransactionModel> get recentTransactions {
    final sorted = List<TransactionModel>.from(_transactions)
      ..sort((a, b) => b.date.compareTo(a.date));
    return sorted.take(5).toList();
  }

  /// Get only expenses
  List<TransactionModel> get expenses =>
      _transactions.where((t) => t.type == 'expense').toList();

  /// Get only income
  List<TransactionModel> get incomeList =>
      _transactions.where((t) => t.type == 'income').toList();

  /// Get expenses grouped by category with totals
  Map<String, double> get expensesByCategory {
    final map = <String, double>{};
    for (var t in expenses) {
      map[t.category] = (map[t.category] ?? 0) + t.amount;
    }
    return map;
  }

  /// Get monthly expense totals for the current year
  Map<int, double> get monthlyExpenses {
    final now = DateTime.now();
    final map = <int, double>{};
    for (int i = 1; i <= 12; i++) {
      map[i] = 0;
    }
    for (var t in expenses) {
      if (t.date.year == now.year) {
        map[t.date.month] = (map[t.date.month] ?? 0) + t.amount;
      }
    }
    return map;
  }

  /// Get monthly income totals for the current year
  Map<int, double> get monthlyIncome {
    final now = DateTime.now();
    final map = <int, double>{};
    for (int i = 1; i <= 12; i++) {
      map[i] = 0;
    }
    for (var t in incomeList) {
      if (t.date.year == now.year) {
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

  /// Clear all data (used on logout)
  void clear() {
    _transactions = [];
    _error = null;
    notifyListeners();
  }
}
