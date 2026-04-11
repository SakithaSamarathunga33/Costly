import 'package:flutter/material.dart';
import '../models/debt_model.dart';
import '../services/debt_service.dart';

class DebtProvider extends ChangeNotifier {
  final DebtService _service = DebtService();
  List<DebtModel> _debts = [];
  bool _isLoading = false;

  List<DebtModel> get debts => List.unmodifiable(_debts);
  List<DebtModel> get active => _debts.where((d) => !d.isSettled).toList();
  List<DebtModel> get settled => _debts.where((d) => d.isSettled).toList();
  bool get isLoading => _isLoading;

  double get totalOwedByMe => _debts
      .where((d) => d.debtType == 'owed_by_me' && !d.isSettled)
      .fold(0.0, (s, d) => s + d.remainingAmount);

  double get totalOwedToMe => _debts
      .where((d) => d.debtType == 'owed_to_me' && !d.isSettled)
      .fold(0.0, (s, d) => s + d.remainingAmount);

  Future<void> fetchDebts(String userId) async {
    _isLoading = true;
    notifyListeners();
    try {
      _debts = await _service.getAll(userId);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> addDebt({
    required String userId,
    required String name,
    required String person,
    required double totalAmount,
    required String debtType,
    DateTime? dueDate,
    String notes = '',
  }) async {
    final debt = DebtModel(
      id: '',
      userId: userId,
      name: name,
      person: person,
      totalAmount: totalAmount,
      debtType: debtType,
      dueDate: dueDate,
      notes: notes,
      createdAt: DateTime.now(),
    );
    final saved = await _service.add(debt);
    _debts.add(saved);
    notifyListeners();
  }

  Future<void> recordPayment(String debtId, double amount) async {
    final idx = _debts.indexWhere((d) => d.id == debtId);
    if (idx == -1) return;
    final updated = _debts[idx].copyWith(
      paidAmount: (_debts[idx].paidAmount + amount)
          .clamp(0, _debts[idx].totalAmount),
    );
    await _service.update(updated);
    _debts[idx] = updated;
    notifyListeners();
  }

  Future<void> deleteDebt(String id) async {
    await _service.delete(id);
    _debts.removeWhere((d) => d.id == id);
    notifyListeners();
  }
}
