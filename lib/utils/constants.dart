import 'package:flutter/material.dart';

// App color palette
const Color kPrimary = Color(0xFF5D3891);
const Color kBgDark = Color(0xFFF5F5F5);
const Color kCardDark = Color(0xFFE8E2E2);
const Color kTextMain = Color(0xFF2D2D2D);
const Color kAccentOrange = Color(0xFFF99417);

// Transaction categories with icons and colors
const List<Map<String, dynamic>> kExpenseCategories = [
  {'name': 'Food', 'icon': 'restaurant', 'color': 0xFFFF9800},
  {'name': 'Transport', 'icon': 'directions_car', 'color': 0xFF2196F3},
  {'name': 'Shopping', 'icon': 'shopping_bag', 'color': 0xFF9C27B0},
  {'name': 'Bills', 'icon': 'receipt_long', 'color': 0xFF4CAF50},
  {'name': 'Entertainment', 'icon': 'movie', 'color': 0xFFE91E63},
  {'name': 'Health', 'icon': 'local_hospital', 'color': 0xFFFF5722},
  {'name': 'Education', 'icon': 'school', 'color': 0xFF3F51B5},
  {'name': 'Travel', 'icon': 'flight', 'color': 0xFF00BCD4},
  {'name': 'Other', 'icon': 'more_horiz', 'color': 0xFF607D8B},
];

const List<Map<String, dynamic>> kIncomeCategories = [
  {'name': 'Salary', 'icon': 'payments', 'color': 0xFF4CAF50},
  {'name': 'Freelance', 'icon': 'work', 'color': 0xFF5D3891},
  {'name': 'Investment', 'icon': 'trending_up', 'color': 0xFF2196F3},
  {'name': 'Gift', 'icon': 'card_giftcard', 'color': 0xFFE91E63},
  {'name': 'Other', 'icon': 'more_horiz', 'color': 0xFF607D8B},
];

// Helper to get icon data from string name
IconData getCategoryIcon(String iconName) {
  switch (iconName) {
    case 'restaurant':
      return Icons.restaurant;
    case 'directions_car':
      return Icons.directions_car;
    case 'shopping_bag':
      return Icons.shopping_bag;
    case 'receipt_long':
      return Icons.receipt_long;
    case 'movie':
      return Icons.movie;
    case 'local_hospital':
      return Icons.local_hospital;
    case 'school':
      return Icons.school;
    case 'flight':
      return Icons.flight;
    case 'payments':
      return Icons.payments;
    case 'work':
      return Icons.work;
    case 'trending_up':
      return Icons.trending_up;
    case 'card_giftcard':
      return Icons.card_giftcard;
    case 'bolt':
      return Icons.bolt;
    case 'home':
      return Icons.home;
    default:
      return Icons.more_horiz;
  }
}

// Helper to get category color
Color getCategoryColor(String category) {
  for (var cat in [...kExpenseCategories, ...kIncomeCategories]) {
    if (cat['name'] == category) {
      return Color(cat['color'] as int);
    }
  }
  return const Color(0xFF607D8B);
}

// Helper to get category icon by category name
IconData getCategoryIconByName(String category) {
  for (var cat in [...kExpenseCategories, ...kIncomeCategories]) {
    if (cat['name'] == category) {
      return getCategoryIcon(cat['icon'] as String);
    }
  }
  return Icons.more_horiz;
}
