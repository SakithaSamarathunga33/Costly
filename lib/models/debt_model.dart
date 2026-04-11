import 'package:cloud_firestore/cloud_firestore.dart';

class DebtModel {
  final String id;
  final String userId;
  final String name; // description of the debt
  final String person; // creditor or debtor name
  final double totalAmount;
  final double paidAmount;
  final String debtType; // 'owed_by_me' | 'owed_to_me'
  final DateTime? dueDate;
  final String notes;
  final DateTime createdAt;

  DebtModel({
    required this.id,
    required this.userId,
    required this.name,
    required this.person,
    required this.totalAmount,
    this.paidAmount = 0,
    required this.debtType,
    this.dueDate,
    this.notes = '',
    required this.createdAt,
  });

  double get remainingAmount => (totalAmount - paidAmount).clamp(0, double.infinity);
  double get progressPercent =>
      totalAmount > 0 ? (paidAmount / totalAmount * 100).clamp(0, 100) : 0;
  bool get isSettled => paidAmount >= totalAmount;

  factory DebtModel.fromMap(Map<String, dynamic> map, String id) {
    return DebtModel(
      id: id,
      userId: map['userId'] ?? '',
      name: map['name'] ?? '',
      person: map['person'] ?? '',
      totalAmount: (map['totalAmount'] ?? 0).toDouble(),
      paidAmount: (map['paidAmount'] ?? 0).toDouble(),
      debtType: map['debtType'] ?? 'owed_by_me',
      dueDate: map['dueDate'] != null
          ? (map['dueDate'] as Timestamp).toDate()
          : null,
      notes: map['notes'] ?? '',
      createdAt: map['createdAt'] is Timestamp
          ? (map['createdAt'] as Timestamp).toDate()
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() => {
        'userId': userId,
        'name': name,
        'person': person,
        'totalAmount': totalAmount,
        'paidAmount': paidAmount,
        'debtType': debtType,
        'dueDate': dueDate != null ? Timestamp.fromDate(dueDate!) : null,
        'notes': notes,
        'createdAt': Timestamp.fromDate(createdAt),
      };

  DebtModel copyWith({double? paidAmount}) => DebtModel(
        id: id,
        userId: userId,
        name: name,
        person: person,
        totalAmount: totalAmount,
        paidAmount: paidAmount ?? this.paidAmount,
        debtType: debtType,
        dueDate: dueDate,
        notes: notes,
        createdAt: createdAt,
      );
}
