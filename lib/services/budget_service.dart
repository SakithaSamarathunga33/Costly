import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/budget_model.dart';

class BudgetService {
  final _col = FirebaseFirestore.instance.collection('budgets');

  Future<BudgetModel?> getBudget(String userId, int year, int month) async {
    final id = BudgetModel.docId(userId, year, month);
    final doc = await _col.doc(id).get();
    if (!doc.exists) return null;
    return BudgetModel.fromMap(doc.data()!, doc.id);
  }

  Future<void> saveBudget(BudgetModel budget) async {
    await _col.doc(budget.id).set(budget.toMap());
  }
}
