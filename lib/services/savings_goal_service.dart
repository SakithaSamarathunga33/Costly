import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/savings_goal_model.dart';

class SavingsGoalService {
  final _col = FirebaseFirestore.instance.collection('savings_goals');

  Future<List<SavingsGoalModel>> getAll(String userId) async {
    final snap = await _col.where('userId', isEqualTo: userId).get();
    final list = snap.docs
        .map((d) => SavingsGoalModel.fromMap(d.data(), d.id))
        .toList();
    list.sort((a, b) => a.createdAt.compareTo(b.createdAt));
    return list;
  }

  Future<SavingsGoalModel> add(SavingsGoalModel goal) async {
    final ref = _col.doc();
    final g = SavingsGoalModel(
      id: ref.id,
      userId: goal.userId,
      name: goal.name,
      targetAmount: goal.targetAmount,
      savedAmount: goal.savedAmount,
      icon: goal.icon,
      color: goal.color,
      deadline: goal.deadline,
      createdAt: goal.createdAt,
    );
    await ref.set(g.toMap());
    return g;
  }

  Future<void> update(SavingsGoalModel goal) async {
    await _col.doc(goal.id).update({
      'savedAmount': goal.savedAmount,
      'name': goal.name,
      'targetAmount': goal.targetAmount,
      'icon': goal.icon,
      'color': goal.color,
      'deadline': goal.deadline != null
          ? Timestamp.fromDate(goal.deadline!)
          : null,
    });
  }

  Future<void> delete(String id) async {
    await _col.doc(id).delete();
  }
}
