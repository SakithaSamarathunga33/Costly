import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/debt_model.dart';

class DebtService {
  final _col = FirebaseFirestore.instance.collection('debts');

  Future<List<DebtModel>> getAll(String userId) async {
    final snap = await _col.where('userId', isEqualTo: userId).get();
    final list =
        snap.docs.map((d) => DebtModel.fromMap(d.data(), d.id)).toList();
    list.sort((a, b) => a.createdAt.compareTo(b.createdAt));
    return list;
  }

  Future<DebtModel> add(DebtModel debt) async {
    final ref = _col.doc();
    final d = DebtModel(
      id: ref.id,
      userId: debt.userId,
      name: debt.name,
      person: debt.person,
      totalAmount: debt.totalAmount,
      paidAmount: debt.paidAmount,
      debtType: debt.debtType,
      dueDate: debt.dueDate,
      notes: debt.notes,
      createdAt: debt.createdAt,
    );
    await ref.set(d.toMap());
    return d;
  }

  Future<void> update(DebtModel debt) async {
    await _col.doc(debt.id).update({'paidAmount': debt.paidAmount});
  }

  Future<void> delete(String id) async {
    await _col.doc(id).delete();
  }
}
