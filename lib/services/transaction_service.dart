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
    final snapshot =
        await _transactions.where('userId', isEqualTo: userId).get();

    final list = snapshot.docs
        .map((doc) => TransactionModel.fromMap(doc.data(), doc.id))
        .toList();
    // Sort in Dart to avoid requiring a Firestore composite index
    list.sort((a, b) => b.date.compareTo(a.date));
    return list;
  }

  /// Get recent transactions (last 5)
  Future<List<TransactionModel>> getRecentTransactions(String userId) async {
    final snapshot =
        await _transactions.where('userId', isEqualTo: userId).get();

    final list = snapshot.docs
        .map((doc) => TransactionModel.fromMap(doc.data(), doc.id))
        .toList();
    // Sort in Dart and take latest 5
    list.sort((a, b) => b.date.compareTo(a.date));
    return list.take(5).toList();
  }

  /// Delete a transaction
  Future<void> deleteTransaction(String transactionId) async {
    await _transactions.doc(transactionId).delete();
  }

  /// Update an existing transaction
  Future<void> updateTransaction(TransactionModel transaction) async {
    await _transactions.doc(transaction.id).update({
      'title': transaction.title,
      'amount': transaction.amount,
      'type': transaction.type,
      'category': transaction.category,
      'date': Timestamp.fromDate(transaction.date),
      'notes': transaction.notes,
    });
  }

  /// Delete all transactions for a user in a given category
  Future<void> deleteTransactionsByCategory(
      String userId, String category) async {
    final snapshot = await _transactions
        .where('userId', isEqualTo: userId)
        .where('category', isEqualTo: category)
        .get();
    final batch = _firestore.batch();
    for (var doc in snapshot.docs) {
      batch.delete(doc.reference);
    }
    await batch.commit();
  }

  /// Rename category value in all matching transactions for a user
  Future<void> renameCategoryInTransactions({
    required String userId,
    required String oldCategory,
    required String newCategory,
    required String type,
  }) async {
    final snapshot = await _transactions
        .where('userId', isEqualTo: userId)
        .where('type', isEqualTo: type)
        .where('category', isEqualTo: oldCategory)
        .get();

    for (int i = 0; i < snapshot.docs.length; i += 450) {
      final batch = _firestore.batch();
      final chunk = snapshot.docs.skip(i).take(450);
      for (final doc in chunk) {
        batch.update(doc.reference, {'category': newCategory});
      }
      await batch.commit();
    }
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
