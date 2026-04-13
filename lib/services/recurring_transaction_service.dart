import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/recurring_transaction_model.dart';

class RecurringTransactionService {
  final _col =
      FirebaseFirestore.instance.collection('recurring_transactions');

  Future<List<RecurringTransactionModel>> getAll(String userId) async {
    final snap =
        await _col.where('userId', isEqualTo: userId).get();
    return snap.docs
        .map((d) => RecurringTransactionModel.fromMap(d.data(), d.id))
        .toList();
  }

  Future<RecurringTransactionModel> add(
      RecurringTransactionModel model) async {
    final ref = _col.doc();
    final withId = RecurringTransactionModel(
      id: ref.id,
      userId: model.userId,
      title: model.title,
      amount: model.amount,
      type: model.type,
      category: model.category,
      notes: model.notes,
      frequency: model.frequency,
      nextDueDate: model.nextDueDate,
      isActive: model.isActive,
      endDate: model.endDate,
    );
    await ref.set(withId.toMap());
    return withId;
  }

  Future<void> update(RecurringTransactionModel model) async {
    await _col.doc(model.id).set(model.toMap());
  }

  Future<void> delete(String id) async {
    await _col.doc(id).delete();
  }
}
