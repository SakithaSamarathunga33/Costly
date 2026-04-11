import 'package:flutter/material.dart';
import '../models/savings_goal_model.dart';
import '../services/savings_goal_service.dart';

class SavingsGoalProvider extends ChangeNotifier {
  final SavingsGoalService _service = SavingsGoalService();

  List<SavingsGoalModel> _goals = [];
  bool _isLoading = false;

  List<SavingsGoalModel> get goals => List.unmodifiable(_goals);
  bool get isLoading => _isLoading;

  Future<void> fetchGoals(String userId) async {
    _isLoading = true;
    notifyListeners();
    try {
      _goals = await _service.getAll(userId);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> addGoal({
    required String userId,
    required String name,
    required double targetAmount,
    required String icon,
    required int color,
    DateTime? deadline,
  }) async {
    final goal = SavingsGoalModel(
      id: '',
      userId: userId,
      name: name,
      targetAmount: targetAmount,
      icon: icon,
      color: color,
      deadline: deadline,
      createdAt: DateTime.now(),
    );
    final saved = await _service.add(goal);
    _goals.add(saved);
    notifyListeners();
  }

  Future<void> contribute(String goalId, double amount) async {
    final idx = _goals.indexWhere((g) => g.id == goalId);
    if (idx == -1) return;
    final updated = _goals[idx].copyWith(
      savedAmount: _goals[idx].savedAmount + amount,
    );
    await _service.update(updated);
    _goals[idx] = updated;
    notifyListeners();
  }

  Future<void> deleteGoal(String goalId) async {
    await _service.delete(goalId);
    _goals.removeWhere((g) => g.id == goalId);
    notifyListeners();
  }
}
