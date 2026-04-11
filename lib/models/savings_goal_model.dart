import 'package:cloud_firestore/cloud_firestore.dart';

class SavingsGoalModel {
  final String id;
  final String userId;
  final String name;
  final double targetAmount;
  final double savedAmount;
  final String icon; // key from kIconPool
  final int color; // ARGB int
  final DateTime? deadline;
  final DateTime createdAt;

  SavingsGoalModel({
    required this.id,
    required this.userId,
    required this.name,
    required this.targetAmount,
    this.savedAmount = 0,
    this.icon = 'savings',
    this.color = 0xFF5D3891,
    this.deadline,
    required this.createdAt,
  });

  double get progressPercent =>
      targetAmount > 0 ? (savedAmount / targetAmount * 100).clamp(0, 100) : 0;

  bool get isCompleted => savedAmount >= targetAmount;

  factory SavingsGoalModel.fromMap(Map<String, dynamic> map, String id) {
    return SavingsGoalModel(
      id: id,
      userId: map['userId'] ?? '',
      name: map['name'] ?? '',
      targetAmount: (map['targetAmount'] ?? 0).toDouble(),
      savedAmount: (map['savedAmount'] ?? 0).toDouble(),
      icon: map['icon'] ?? 'savings',
      color: map['color'] ?? 0xFF5D3891,
      deadline: map['deadline'] != null
          ? (map['deadline'] as Timestamp).toDate()
          : null,
      createdAt: map['createdAt'] is Timestamp
          ? (map['createdAt'] as Timestamp).toDate()
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() => {
        'userId': userId,
        'name': name,
        'targetAmount': targetAmount,
        'savedAmount': savedAmount,
        'icon': icon,
        'color': color,
        'deadline': deadline != null ? Timestamp.fromDate(deadline!) : null,
        'createdAt': Timestamp.fromDate(createdAt),
      };

  SavingsGoalModel copyWith({
    String? name,
    double? targetAmount,
    double? savedAmount,
    String? icon,
    int? color,
    DateTime? deadline,
  }) =>
      SavingsGoalModel(
        id: id,
        userId: userId,
        name: name ?? this.name,
        targetAmount: targetAmount ?? this.targetAmount,
        savedAmount: savedAmount ?? this.savedAmount,
        icon: icon ?? this.icon,
        color: color ?? this.color,
        deadline: deadline ?? this.deadline,
        createdAt: createdAt,
      );
}
