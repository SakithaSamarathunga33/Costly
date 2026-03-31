import 'package:flutter/material.dart';

/// Shown in launcher (Android/iOS) via native config; keep in sync with UI copy.
const String kAppDisplayName = 'Costly';
const String kAppVersionLabel = '1.0.0';

/// Public GitHub repo used by **Check for updates** (GitHub REST API, no token).
/// Set `kGitHubRepoOwner` to your username or org (same repo you push this app to).
/// Leave empty to hide/disable update checks.
const String kGitHubRepoOwner = 'SakithaSamarathunga33';
const String kGitHubRepoName = 'Costly';

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

// Icon pool for custom categories — users pick from these
const Map<String, IconData> kIconPool = {
  'restaurant': Icons.restaurant,
  'directions_car': Icons.directions_car,
  'shopping_bag': Icons.shopping_bag,
  'receipt_long': Icons.receipt_long,
  'movie': Icons.movie,
  'local_hospital': Icons.local_hospital,
  'school': Icons.school,
  'flight': Icons.flight,
  'payments': Icons.payments,
  'work': Icons.work,
  'trending_up': Icons.trending_up,
  'card_giftcard': Icons.card_giftcard,
  'bolt': Icons.bolt,
  'home': Icons.home,
  'more_horiz': Icons.more_horiz,
  'pets': Icons.pets,
  'fitness_center': Icons.fitness_center,
  'coffee': Icons.coffee,
  'wifi': Icons.wifi,
  'phone_android': Icons.phone_android,
  'laptop': Icons.laptop,
  'brush': Icons.brush,
  'music_note': Icons.music_note,
  'sports_esports': Icons.sports_esports,
  'child_care': Icons.child_care,
  'checkroom': Icons.checkroom,
  'local_grocery_store': Icons.local_grocery_store,
  'local_gas_station': Icons.local_gas_station,
  'local_parking': Icons.local_parking,
  'build': Icons.build,
  'savings': Icons.savings,
  'attach_money': Icons.attach_money,
  'account_balance': Icons.account_balance,
  'store': Icons.store,
  'favorite': Icons.favorite,
  'sports_soccer': Icons.sports_soccer,
  'cake': Icons.cake,
  'local_laundry_service': Icons.local_laundry_service,
  'book': Icons.book,
  'handyman': Icons.handyman,
};

// Color pool for custom categories
const List<int> kColorPool = [
  0xFFFF9800, // Orange
  0xFF2196F3, // Blue
  0xFF9C27B0, // Purple
  0xFF4CAF50, // Green
  0xFFE91E63, // Pink
  0xFFFF5722, // Deep Orange
  0xFF3F51B5, // Indigo
  0xFF00BCD4, // Cyan
  0xFF607D8B, // Blue Grey
  0xFF795548, // Brown
  0xFF009688, // Teal
  0xFFFFC107, // Amber
];

// Currency options
const List<Map<String, String>> kCurrencyOptions = [
  {'code': 'USD', 'symbol': '\$', 'name': 'US Dollar'},
  {'code': 'LKR', 'symbol': 'Rs', 'name': 'Sri Lankan Rupee'},
  {'code': 'INR', 'symbol': '₹', 'name': 'Indian Rupee'},
  {'code': 'EUR', 'symbol': '€', 'name': 'Euro'},
  {'code': 'GBP', 'symbol': '£', 'name': 'British Pound'},
  {'code': 'JPY', 'symbol': '¥', 'name': 'Japanese Yen'},
  {'code': 'AUD', 'symbol': 'A\$', 'name': 'Australian Dollar'},
  {'code': 'CAD', 'symbol': 'C\$', 'name': 'Canadian Dollar'},
  {'code': 'SGD', 'symbol': 'S\$', 'name': 'Singapore Dollar'},
  {'code': 'MYR', 'symbol': 'RM', 'name': 'Malaysian Ringgit'},
];

String getCurrencySymbol(String code) {
  for (var currency in kCurrencyOptions) {
    if (currency['code'] == code) {
      return currency['symbol'] ?? '\$';
    }
  }
  return '\$';
}

// Helper to get icon data from string name
IconData getCategoryIcon(String iconName) {
  return kIconPool[iconName] ?? Icons.more_horiz;
}

// Helper to get category color (checks built-in + optional custom list)
Color getCategoryColor(String category,
    [List<Map<String, dynamic>> customCategories = const []]) {
  for (var cat in [
    ...kExpenseCategories,
    ...kIncomeCategories,
    ...customCategories
  ]) {
    if (cat['name'] == category) {
      return Color(cat['color'] as int);
    }
  }
  return const Color(0xFF607D8B);
}

// Helper to get category icon by category name (checks built-in + optional custom list)
IconData getCategoryIconByName(String category,
    [List<Map<String, dynamic>> customCategories = const []]) {
  for (var cat in [
    ...kExpenseCategories,
    ...kIncomeCategories,
    ...customCategories
  ]) {
    if (cat['name'] == category) {
      return getCategoryIcon(cat['icon'] as String);
    }
  }
  return Icons.more_horiz;
}
