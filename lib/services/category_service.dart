import 'package:cloud_firestore/cloud_firestore.dart';

/// Service for managing custom user categories in Firestore.
class CategoryService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Get the custom categories collection for a user
  CollectionReference _userCategories(String userId) {
    return _firestore
        .collection('users')
        .doc(userId)
        .collection('custom_categories');
  }

  /// Fetch all custom categories for a user
  Future<List<Map<String, dynamic>>> getCustomCategories(String userId) async {
    final snapshot = await _userCategories(userId).get();
    return snapshot.docs.map((doc) {
      final data = doc.data() as Map<String, dynamic>;
      data['id'] = doc.id;
      return data;
    }).toList();
  }

  /// Add a new custom category
  Future<Map<String, dynamic>> addCustomCategory({
    required String userId,
    required String name,
    required String icon,
    required int color,
    required String type, // 'expense' or 'income'
  }) async {
    final docRef = await _userCategories(userId).add({
      'name': name,
      'icon': icon,
      'color': color,
      'type': type,
      'createdAt': FieldValue.serverTimestamp(),
    });

    return {
      'id': docRef.id,
      'name': name,
      'icon': icon,
      'color': color,
      'type': type,
    };
  }

  /// Delete a custom category
  Future<void> deleteCustomCategory(String userId, String categoryId) async {
    await _userCategories(userId).doc(categoryId).delete();
  }

  /// Update a custom category
  Future<void> updateCustomCategory({
    required String userId,
    required String categoryId,
    required String name,
    required String icon,
    required int color,
    required String type,
  }) async {
    await _userCategories(userId).doc(categoryId).update({
      'name': name,
      'icon': icon,
      'color': color,
      'type': type,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }
}
