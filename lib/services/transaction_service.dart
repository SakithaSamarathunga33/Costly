import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/transaction_model.dart';

/// Service handling transaction CRUD operations with Cloud Firestore.
class TransactionService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _transactions =>
      _firestore.collection('transactions');

  /// Add a new transaction (expense or income)
  Future<TransactionModel> addTransaction({
    required String userId,
    required String title,
    required double amount,
    required String type,
    required String category,
    required DateTime date,
    String notes = '',
  }) async {
    if (title.trim().isEmpty) throw Exception('Title is required');
    if (amount <= 0) throw Exception('Amount must be greater than zero');

    final docRef = _transactions.doc();

    final transaction = TransactionModel(
      id: docRef.id,
      userId: userId,
      title: title.trim(),
      amount: amount,
      type: type,
      category: category,
      date: date,
      notes: notes.trim(),
    );

    await docRef.set(transaction.toMap());
    return transaction;
  }

  /// Get all transactions for a user, sorted by newest first
  Future<List<TransactionModel>> getTransactions(String userId) async {
    final snapshot = await _transactions
        .where('userId', isEqualTo: userId)
        .orderBy('date', descending: true)
        .get();

    return snapshot.docs
        .map((doc) => TransactionModel.fromMap(doc.data(), doc.id))
        .toList();
  }

  /// Get recent transactions (last 5)
  Future<List<TransactionModel>> getRecentTransactions(String userId) async {
    final snapshot = await _transactions
        .where('userId', isEqualTo: userId)
        .orderBy('date', descending: true)
        .limit(5)
        .get();

    return snapshot.docs
        .map((doc) => TransactionModel.fromMap(doc.data(), doc.id))
        .toList();
  }

  /// Delete a transaction
  Future<void> deleteTransaction(String transactionId) async {
    await _transactions.doc(transactionId).delete();
  }

  /// Get total income for a user
  Future<double> getTotalIncome(String userId) async {
    final snapshot = await _transactions
        .where('userId', isEqualTo: userId)
        .where('type', isEqualTo: 'income')
        .get();

    double total = 0;
    for (var doc in snapshot.docs) {
      total += (doc.data()['amount'] as num).toDouble();
    }
    return total;
  }

  /// Get total expenses for a user
  Future<double> getTotalExpenses(String userId) async {
    final snapshot = await _transactions
        .where('userId', isEqualTo: userId)
        .where('type', isEqualTo: 'expense')
        .get();

    double total = 0;
    for (var doc in snapshot.docs) {
      total += (doc.data()['amount'] as num).toDouble();
    }
    return total;
  }
}
