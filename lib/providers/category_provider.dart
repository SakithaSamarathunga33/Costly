import 'package:flutter/material.dart';
import '../services/category_service.dart';
import '../utils/constants.dart';

/// Provider for managing custom user categories.
class CategoryProvider extends ChangeNotifier {
  final CategoryService _categoryService = CategoryService();

  List<Map<String, dynamic>> _customCategories = [];
  bool _isLoading = false;

  List<Map<String, dynamic>> get customCategories => _customCategories;
  bool get isLoading => _isLoading;

  /// Get custom expense categories
  List<Map<String, dynamic>> get customExpenseCategories =>
      _customCategories.where((c) => c['type'] == 'expense').toList();

  /// Get custom income categories
  List<Map<String, dynamic>> get customIncomeCategories =>
      _customCategories.where((c) => c['type'] == 'income').toList();

  /// Get all expense categories (built-in + custom)
  List<Map<String, dynamic>> get allExpenseCategories => [
        ...kExpenseCategories,
        ...customExpenseCategories,
      ];

  /// Get all income categories (built-in + custom)
  List<Map<String, dynamic>> get allIncomeCategories => [
        ...kIncomeCategories,
        ...customIncomeCategories,
      ];

  /// Fetch custom categories from Firestore
  Future<void> fetchCustomCategories(String userId) async {
    _isLoading = true;
    notifyListeners();

    try {
      _customCategories = await _categoryService.getCustomCategories(userId);
    } catch (e) {
      debugPrint('Error fetching custom categories: $e');
    }

    _isLoading = false;
    notifyListeners();
  }

  /// Add a new custom category
  Future<bool> addCustomCategory({
    required String userId,
    required String name,
    required String icon,
    required int color,
    required String type,
  }) async {
    try {
      final category = await _categoryService.addCustomCategory(
        userId: userId,
        name: name,
        icon: icon,
        color: color,
        type: type,
      );
      _customCategories.add(category);
      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('Error adding custom category: $e');
      return false;
    }
  }

  /// Delete a custom category
  Future<bool> deleteCustomCategory({
    required String userId,
    required String categoryId,
  }) async {
    try {
      await _categoryService.deleteCustomCategory(userId, categoryId);
      _customCategories.removeWhere((c) => c['id'] == categoryId);
      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('Error deleting custom category: $e');
      return false;
    }
  }

  /// Update a custom category
  Future<bool> updateCustomCategory({
    required String userId,
    required String categoryId,
    required String name,
    required String icon,
    required int color,
    required String type,
  }) async {
    try {
      await _categoryService.updateCustomCategory(
        userId: userId,
        categoryId: categoryId,
        name: name,
        icon: icon,
        color: color,
        type: type,
      );

      final index = _customCategories.indexWhere((c) => c['id'] == categoryId);
      if (index != -1) {
        _customCategories[index] = {
          ..._customCategories[index],
          'name': name,
          'icon': icon,
          'color': color,
          'type': type,
        };
      }

      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('Error updating custom category: $e');
      return false;
    }
  }

  /// Clear data (on logout)
  void clear() {
    _customCategories = [];
    notifyListeners();
  }
}
