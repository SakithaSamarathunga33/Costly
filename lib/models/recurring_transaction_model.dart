import 'package:cloud_firestore/cloud_firestore.dart';

class RecurringTransactionModel {
  final String id;
  final String userId;
  final String title;
  final double amount;
  final String type; // 'expense' or 'income'
  final String category;
  final String notes;
  final String frequency; // 'daily', 'weekly', 'monthly'
  final DateTime nextDueDate;
  final bool isActive;
  final DateTime? endDate; // null = no end

  RecurringTransactionModel({
    required this.id,
    required this.userId,
    required this.title,
    required this.amount,
    required this.type,
    required this.category,
    this.notes = '',
    required this.frequency,
    required this.nextDueDate,
    this.isActive = true,
    this.endDate,
  });

  factory RecurringTransactionModel.fromMap(
      Map<String, dynamic> map, String id) {
    return RecurringTransactionModel(
      id: id,
      userId: map['userId'] ?? '',
      title: map['title'] ?? '',
      amount: (map['amount'] ?? 0).toDouble(),
      type: map['type'] ?? 'expense',
      category: map['category'] ?? 'Other',
      notes: map['notes'] ?? '',
      frequency: map['frequency'] ?? 'monthly',
      nextDueDate: map['nextDueDate'] is Timestamp
          ? (map['nextDueDate'] as Timestamp).toDate()
          : DateTime.tryParse(map['nextDueDate']?.toString() ?? '') ??
              DateTime.now(),
      isActive: map['isActive'] ?? true,
      endDate: map['endDate'] is Timestamp
          ? (map['endDate'] as Timestamp).toDate()
          : map['endDate'] != null
              ? DateTime.tryParse(map['endDate'].toString())
              : null,
    );
  }

  Map<String, dynamic> toMap() {
    final m = <String, dynamic>{
      'userId': userId,
      'title': title,
      'amount': amount,
      'type': type,
      'category': category,
      'notes': notes,
      'frequency': frequency,
      'nextDueDate': Timestamp.fromDate(nextDueDate),
      'isActive': isActive,
    };
    if (endDate != null) m['endDate'] = Timestamp.fromDate(endDate!);
    return m;
  }

  RecurringTransactionModel copyWith({
    String? title,
    double? amount,
    String? type,
    String? category,
    String? notes,
    String? frequency,
    DateTime? nextDueDate,
    bool? isActive,
    Object? endDate = _sentinel,
  }) =>
      RecurringTransactionModel(
        id: id,
        userId: userId,
        title: title ?? this.title,
        amount: amount ?? this.amount,
        type: type ?? this.type,
        category: category ?? this.category,
        notes: notes ?? this.notes,
        frequency: frequency ?? this.frequency,
        nextDueDate: nextDueDate ?? this.nextDueDate,
        isActive: isActive ?? this.isActive,
        endDate: identical(endDate, _sentinel)
            ? this.endDate
            : endDate as DateTime?,
      );

  static const Object _sentinel = Object();

  /// Calculate the next due date after [from] based on frequency.
  DateTime nextAfter(DateTime from) {
    switch (frequency) {
      case 'daily':
        return from.add(const Duration(days: 1));
      case 'weekly':
        return from.add(const Duration(days: 7));
      case 'monthly':
      default:
        return DateTime(from.year, from.month + 1, from.day);
    }
  }
}
