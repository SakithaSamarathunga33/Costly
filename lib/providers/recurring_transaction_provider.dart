import 'package:flutter/material.dart';
import '../models/recurring_transaction_model.dart';
import '../services/recurring_transaction_service.dart';
import '../services/transaction_service.dart';

class RecurringTransactionProvider extends ChangeNotifier {
  final RecurringTransactionService _service =
      RecurringTransactionService();
  final TransactionService _txService = TransactionService();

  List<RecurringTransactionModel> _items = [];
  bool _isLoading = false;

  List<RecurringTransactionModel> get items => List.unmodifiable(_items);
  List<RecurringTransactionModel> get activeItems =>
      _items.where((r) => r.isActive).toList();
  bool get isLoading => _isLoading;

  Future<void> fetchAndProcess(String userId) async {
    _isLoading = true;
    notifyListeners();
    try {
      _items = await _service.getAll(userId);
      await _processDue(userId);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Auto-generate transactions for any overdue recurring entries.
  Future<void> _processDue(String userId) async {
    final now = DateTime.now();
    for (int i = 0; i < _items.length; i++) {
      final item = _items[i];
      if (!item.isActive) continue;

      // Auto-deactivate if past endDate
      if (item.endDate != null && now.isAfter(item.endDate!)) {
        final deactivated = item.copyWith(isActive: false);
        await _service.update(deactivated);
        _items[i] = deactivated;
        continue;
      }

      if (item.nextDueDate.isBefore(now) || _isSameDay(item.nextDueDate, now)) {
        await _txService.addTransaction(
          userId: userId,
          title: item.title,
          amount: item.amount,
          type: item.type,
          category: item.category,
          date: item.nextDueDate,
          notes: item.notes,
        );
        // Advance nextDueDate
        final updated = item.copyWith(nextDueDate: item.nextAfter(item.nextDueDate));
        await _service.update(updated);
        _items[i] = updated;
      }
    }
  }

  bool _isSameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  Future<void> add({
    required String userId,
    required String title,
    required double amount,
    required String type,
    required String category,
    required String frequency,
    required DateTime startDate,
    String notes = '',
    DateTime? endDate,
  }) async {
    final model = RecurringTransactionModel(
      id: '',
      userId: userId,
      title: title,
      amount: amount,
      type: type,
      category: category,
      notes: notes,
      frequency: frequency,
      nextDueDate: startDate,
      endDate: endDate,
    );
    final saved = await _service.add(model);
    _items.add(saved);
    notifyListeners();
  }

  Future<void> toggleActive(RecurringTransactionModel item) async {
    final updated = item.copyWith(isActive: !item.isActive);
    await _service.update(updated);
    final idx = _items.indexWhere((r) => r.id == item.id);
    if (idx != -1) _items[idx] = updated;
    notifyListeners();
  }

  Future<void> delete(String id) async {
    await _service.delete(id);
    _items.removeWhere((r) => r.id == id);
    notifyListeners();
  }
}
