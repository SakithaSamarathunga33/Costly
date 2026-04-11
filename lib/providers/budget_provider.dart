import 'package:flutter/material.dart';
import '../models/budget_model.dart';
import '../services/budget_service.dart';

class BudgetProvider extends ChangeNotifier {
  final BudgetService _service = BudgetService();

  BudgetModel? _budget;
  bool _isLoading = false;

  BudgetModel? get budget => _budget;
  bool get isLoading => _isLoading;

  bool get hasOverallBudget => (_budget?.overall ?? 0) > 0;

  double overallUsedPercent(double totalExpenses) {
    if (_budget == null || _budget!.overall <= 0) return 0;
    return (totalExpenses / _budget!.overall * 100).clamp(0, 100);
  }

  double categoryUsedPercent(String category, double spent) {
    final limit = _budget?.categories[category] ?? 0;
    if (limit <= 0) return 0;
    return (spent / limit * 100).clamp(0, 100);
  }

  double categoryLimit(String category) =>
      _budget?.categories[category] ?? 0;

  Future<void> fetchBudget(String userId, DateTime month) async {
    _isLoading = true;
    notifyListeners();
    try {
      _budget = await _service.getBudget(userId, month.year, month.month);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> saveBudget({
    required String userId,
    required DateTime month,
    required double overall,
    required Map<String, double> categories,
  }) async {
    final id = BudgetModel.docId(userId, month.year, month.month);
    final model = BudgetModel(
      id: id,
      userId: userId,
      year: month.year,
      month: month.month,
      overall: overall,
      categories: categories,
    );
    await _service.saveBudget(model);
    _budget = model;
    notifyListeners();
  }
}
