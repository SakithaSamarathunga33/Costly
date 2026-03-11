import 'package:cloud_firestore/cloud_firestore.dart';

/// Transaction model for both expenses and income
class TransactionModel {
  final String id;
  final String userId;
  final String title;
  final double amount;
  final String type; // 'expense' or 'income'
  final String category;
  final DateTime date;
  final String notes;

  TransactionModel({
    required this.id,
    required this.userId,
    required this.title,
    required this.amount,
    required this.type,
    required this.category,
    required this.date,
    this.notes = '',
  });

  // Convert from Firestore document
  factory TransactionModel.fromMap(Map<String, dynamic> map, String id) {
    return TransactionModel(
      id: id,
      userId: map['userId'] ?? '',
      title: map['title'] ?? '',
      amount: (map['amount'] ?? 0).toDouble(),
      type: map['type'] ?? 'expense',
      category: map['category'] ?? 'Other',
      date: map['date'] is Timestamp
          ? (map['date'] as Timestamp).toDate()
          : DateTime.tryParse(map['date']?.toString() ?? '') ?? DateTime.now(),
      notes: map['notes'] ?? '',
    );
  }

  // Convert to Firestore document
  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'title': title,
      'amount': amount,
      'type': type,
      'category': category,
      'date': Timestamp.fromDate(date),
      'notes': notes,
    };
  }
}
