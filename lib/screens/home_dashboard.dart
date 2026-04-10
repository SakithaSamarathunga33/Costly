import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/auth_provider.dart';
import '../providers/transaction_provider.dart';
import '../providers/category_provider.dart';
import '../utils/constants.dart';
import '../widgets/floating_nav_bar.dart';
import '../widgets/app_animations.dart';
import '../widgets/root_back_handler.dart';
import '../utils/top_toast.dart';

class HomeDashboard extends StatefulWidget {
  const HomeDashboard({super.key});

  @override
  State<HomeDashboard> createState() => _HomeDashboardState();
}

class _HomeDashboardState extends State<HomeDashboard> {
  String? _deletePendingId;

  @override
  void initState() {
    super.initState();
    // Fetch transactions when dashboard loads
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      if (authProvider.isLoggedIn) {
        Provider.of<TransactionProvider>(context, listen: false)
            .fetchTransactions(authProvider.userId);
        Provider.of<CategoryProvider>(context, listen: false)
            .fetchCustomCategories(authProvider.userId);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    const Color primary = Color(0xFF5D3891);
    const Color bgLight = Color(0xFFF8F6FC);
    const Color cardWhite = Colors.white;
    const Color textMain = Color(0xFF2D2D2D);
    const Color greenAccent = Color(0xFF2ECC71);
    const Color redAccent = Color(0xFFE74C3C);

    // Listen to providers for live data
    final authProvider = Provider.of<AuthProvider>(context);
    final currencySymbol = authProvider.currencySymbol;
    final txProvider = Provider.of<TransactionProvider>(context);
    final catProvider = Provider.of<CategoryProvider>(context);
    final customCats = catProvider.customCategories;

    // Format currency values
    final currencyFormat =
        NumberFormat.currency(symbol: '$currencySymbol ', decimalDigits: 2);
    final balanceStr = currencyFormat.format(txProvider.currentBalance);
    final incomeStr = currencyFormat.format(txProvider.totalIncome);
    final expenseStr = currencyFormat.format(txProvider.totalExpenses);

    return RootBackHandler(
      child: Scaffold(
      backgroundColor: bgLight,
      body: Stack(
        children: [
          // ─── Main scrollable content ───
          SafeArea(
            child: ScreenEntrance(
              child: SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 120.0),
                  child: StaggeredColumn(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header
                    Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16.0, vertical: 12.0),
                      child: Row(
                        children: [
                          GestureDetector(
                            onTap: () {
                              Navigator.pushNamed(context, '/profile');
                            },
                            child: Container(
                              width: 40,
                              height: 40,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: primary.withOpacity(0.12),
                                border: Border.all(
                                  color: primary.withOpacity(0.25),
                                  width: 1.5,
                                ),
                              ),
                              child: authProvider.userProfilePicUrl != null
                                  ? ClipOval(
                                      child: Image.network(
                                        authProvider.userProfilePicUrl!,
                                        width: 40,
                                        height: 40,
                                        fit: BoxFit.cover,
                                        errorBuilder:
                                            (context, error, stackTrace) {
                                          return Center(
                                            child: Text(
                                              authProvider.userName.isNotEmpty
                                                  ? authProvider.userName[0]
                                                      .toUpperCase()
                                                  : 'U',
                                              style: const TextStyle(
                                                color: primary,
                                                fontWeight: FontWeight.bold,
                                                fontSize: 18,
                                              ),
                                            ),
                                          );
                                        },
                                      ),
                                    )
                                  : Center(
                                      child: Text(
                                        authProvider.userName.isNotEmpty
                                            ? authProvider.userName[0]
                                                .toUpperCase()
                                            : 'U',
                                        style: const TextStyle(
                                          color: primary,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 18,
                                        ),
                                      ),
                                    ),
                            ),
                          ),
                          const Spacer(),
                          const Text(
                            'Smart Tracker',
                            style: TextStyle(
                              color: textMain,
                              fontSize: 20,
                              fontWeight: FontWeight.w700,
                              letterSpacing: -0.3,
                            ),
                          ),
                          const Spacer(),
                          Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: primary.withOpacity(0.08),
                            ),
                            child: const Icon(
                              Icons.notifications_outlined,
                              color: primary,
                              size: 22,
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Month selector (syncs History + Analytics)
                    Padding(
                      padding: const EdgeInsets.fromLTRB(12, 4, 12, 12),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          IconButton(
                            onPressed: () {
                              txProvider.goToPreviousMonth();
                            },
                            icon: const Icon(Icons.chevron_left_rounded,
                                color: primary, size: 28),
                            style: IconButton.styleFrom(
                              backgroundColor: primary.withOpacity(0.08),
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                            child: Column(
                              children: [
                                Text(
                                  DateFormat('MMMM yyyy')
                                      .format(txProvider.selectedMonth),
                                  style: const TextStyle(
                                    color: textMain,
                                    fontSize: 17,
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: -0.2,
                                  ),
                                ),
                                if (!txProvider.isViewingCurrentMonth)
                                  Text(
                                    'Viewing past activity',
                                    style: TextStyle(
                                      color: textMain.withOpacity(0.45),
                                      fontSize: 11,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                              ],
                            ),
                          ),
                          IconButton(
                            onPressed: txProvider.canGoToNextMonth
                                ? () => txProvider.goToNextMonth()
                                : null,
                            icon: Icon(
                              Icons.chevron_right_rounded,
                              color: txProvider.canGoToNextMonth
                                  ? primary
                                  : Colors.grey.shade400,
                              size: 28,
                            ),
                            style: IconButton.styleFrom(
                              backgroundColor: primary.withOpacity(0.08),
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Balance Card
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0),
                      child: Container(
                        width: double.infinity,
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [
                              Color(0xFF5D3891),
                              Color(0xFF7B52AB),
                              Color(0xFF9B6FCF),
                            ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(24),
                          boxShadow: [
                            BoxShadow(
                              color: primary.withOpacity(0.35),
                              blurRadius: 20,
                              offset: const Offset(0, 10),
                            ),
                          ],
                        ),
                        padding: const EdgeInsets.fromLTRB(24, 28, 24, 24),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              txProvider.isViewingCurrentMonth
                                  ? 'Monthly net'
                                  : 'Net for ${DateFormat('MMM yyyy').format(txProvider.selectedMonth)}',
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.75),
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              balanceStr,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 36,
                                fontWeight: FontWeight.bold,
                                letterSpacing: -1,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Received / Expenses Row
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0),
                      child: Row(
                        children: [
                          Expanded(
                            child: GestureDetector(
                              onTap: () => Navigator.pushNamed(
                                context,
                                '/income_list',
                              ),
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 16, vertical: 14),
                                decoration: BoxDecoration(
                                  color: cardWhite,
                                  borderRadius: BorderRadius.circular(16),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.04),
                                      blurRadius: 10,
                                      offset: const Offset(0, 2),
                                    ),
                                  ],
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Icon(Icons.arrow_downward,
                                            color: greenAccent, size: 14),
                                        const SizedBox(width: 4),
                                        Text(
                                          'RECEIVED',
                                          style: TextStyle(
                                            color: greenAccent,
                                            fontSize: 11,
                                            fontWeight: FontWeight.w700,
                                            letterSpacing: 0.5,
                                          ),
                                        ),
                                        const Spacer(),
                                        Icon(Icons.chevron_right,
                                            color: greenAccent.withOpacity(0.5),
                                            size: 16),
                                      ],
                                    ),
                                    const SizedBox(height: 6),
                                    Text(
                                      incomeStr,
                                      style: const TextStyle(
                                        color: textMain,
                                        fontSize: 22,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: GestureDetector(
                              onTap: () => Navigator.pushNamed(
                                context,
                                '/expense_list',
                              ),
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 16, vertical: 14),
                                decoration: BoxDecoration(
                                  color: cardWhite,
                                  borderRadius: BorderRadius.circular(16),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.04),
                                      blurRadius: 10,
                                      offset: const Offset(0, 2),
                                    ),
                                  ],
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Icon(Icons.arrow_upward,
                                            color: redAccent, size: 14),
                                        const SizedBox(width: 4),
                                        Text(
                                          'EXPENSES',
                                          style: TextStyle(
                                            color: redAccent,
                                            fontSize: 11,
                                            fontWeight: FontWeight.w700,
                                            letterSpacing: 0.5,
                                          ),
                                        ),
                                        const Spacer(),
                                        Icon(Icons.chevron_right,
                                            color: redAccent.withOpacity(0.5),
                                            size: 16),
                                      ],
                                    ),
                                    const SizedBox(height: 6),
                                    Text(
                                      expenseStr,
                                      style: const TextStyle(
                                        color: textMain,
                                        fontSize: 22,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Quick Actions
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Quick Actions',
                            style: TextStyle(
                              color: textMain,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 14),
                          Row(
                            children: [
                              Expanded(
                                child: GestureDetector(
                                  onTap: () {
                                    Navigator.pushNamed(context, '/add_income');
                                  },
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                        vertical: 14),
                                    decoration: BoxDecoration(
                                      color: primary.withOpacity(0.08),
                                      borderRadius: BorderRadius.circular(30),
                                      border: Border.all(
                                        color: primary.withOpacity(0.15),
                                        width: 1,
                                      ),
                                    ),
                                    child: Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Container(
                                          width: 26,
                                          height: 26,
                                          decoration: BoxDecoration(
                                            color: greenAccent,
                                            shape: BoxShape.circle,
                                          ),
                                          child: const Icon(
                                            Icons.account_balance_wallet,
                                            color: Colors.white,
                                            size: 14,
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        const Text(
                                          'Add Income',
                                          style: TextStyle(
                                            color: textMain,
                                            fontSize: 13,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: GestureDetector(
                                  onTap: () {
                                    Navigator.pushNamed(
                                        context, '/add_expense');
                                  },
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                        vertical: 14),
                                    decoration: BoxDecoration(
                                      color: primary.withOpacity(0.08),
                                      borderRadius: BorderRadius.circular(30),
                                      border: Border.all(
                                        color: primary.withOpacity(0.15),
                                        width: 1,
                                      ),
                                    ),
                                    child: Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Container(
                                          width: 26,
                                          height: 26,
                                          decoration: BoxDecoration(
                                            color: primary,
                                            shape: BoxShape.circle,
                                          ),
                                          child: const Icon(
                                            Icons.add,
                                            color: Colors.white,
                                            size: 16,
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        const Text(
                                          'Add Expense',
                                          style: TextStyle(
                                            color: textMain,
                                            fontSize: 13,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 28),

                    // Categories Grid - dynamic from user's transactions
                    Builder(
                      builder: (context) {
                        // Get unique categories from all transactions
                        final usedCategories = <String>{};
                        for (final tx in txProvider.transactions) {
                          usedCategories.add(tx.category);
                        }

                        if (usedCategories.isEmpty) {
                          return const SizedBox.shrink();
                        }

                        final categoryList = usedCategories.toList();

                        return Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Categories',
                                style: TextStyle(
                                  color: textMain,
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 16),
                              LayoutBuilder(
                                builder: (context, constraints) {
                                  const int columns = 4;
                                  final itemWidth =
                                      constraints.maxWidth / columns;

                                  return Wrap(
                                    spacing: 0,
                                    runSpacing: 20,
                                    children: categoryList.map((cat) {
                                      final color =
                                          getCategoryColor(cat, customCats);
                                      final icon = getCategoryIconByName(
                                          cat, customCats);
                                      final bgColor = color.withOpacity(0.12);
                                      final count = txProvider.transactions
                                          .where((tx) => tx.category == cat)
                                          .length;

                                      return SizedBox(
                                        width: itemWidth,
                                        child: _buildCategoryCircle(
                                          icon: icon,
                                          label: cat,
                                          color: color,
                                          bgColor: bgColor,
                                          count: count,
                                          onTap: () {
                                            Navigator.pushNamed(
                                              context,
                                              '/transactions_history',
                                              arguments: cat,
                                            );
                                          },
                                        ),
                                      );
                                    }).toList(),
                                  );
                                },
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 28),

                    // Recent Transactions
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0),
                      child: Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                'Recent Transactions',
                                style: TextStyle(
                                  color: textMain,
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              GestureDetector(
                                onTap: () {
                                  Navigator.pushNamed(
                                      context, '/transactions_history');
                                },
                                child: const Text(
                                  'See All',
                                  style: TextStyle(
                                    color: primary,
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 14),
                          if (txProvider.recentTransactions.isEmpty)
                            Container(
                              padding: const EdgeInsets.all(28),
                              decoration: BoxDecoration(
                                color: cardWhite,
                                borderRadius: BorderRadius.circular(20),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.04),
                                    blurRadius: 10,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: Center(
                                child: Column(
                                  children: [
                                    Icon(
                                      Icons.receipt_long,
                                      color: primary.withOpacity(0.2),
                                      size: 40,
                                    ),
                                    const SizedBox(height: 12),
                                    Text(
                                      'No transactions yet.\nAdd your first income or expense!',
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
                                        color: Colors.black.withOpacity(0.4),
                                        fontSize: 14,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            )
                          else
                            ...txProvider.recentTransactions.map((tx) {
                              final isIncome = tx.type == 'income';
                              final catColor =
                                  getCategoryColor(tx.category, customCats);
                              final catIcon = getCategoryIconByName(
                                  tx.category, customCats);
                              final now = DateTime.now();
                              final today =
                                  DateTime(now.year, now.month, now.day);
                              final yesterday =
                                  today.subtract(const Duration(days: 1));
                              final txDay = DateTime(
                                  tx.date.year, tx.date.month, tx.date.day);

                              String dateStr;
                              if (txDay == today) {
                                dateStr =
                                    '${tx.category} • Today, ${DateFormat('h:mm a').format(tx.date)}';
                              } else if (txDay == yesterday) {
                                dateStr = '${tx.category} • Yesterday';
                              } else {
                                dateStr =
                                    '${tx.category} • ${DateFormat('MMM dd, yyyy').format(tx.date)}';
                              }

                              final isPending = _deletePendingId == tx.id;

                              return Padding(
                                padding: const EdgeInsets.only(bottom: 12),
                                child: GestureDetector(
                                  onLongPress: () => setState(
                                      () => _deletePendingId = tx.id),
                                  onTap: () {
                                    if (isPending) {
                                      setState(
                                          () => _deletePendingId = null);
                                    }
                                  },
                                  child: AnimatedContainer(
                                    duration:
                                        const Duration(milliseconds: 220),
                                    padding: const EdgeInsets.all(14),
                                    decoration: BoxDecoration(
                                      color: isPending
                                          ? const Color(0xFFFFF0F0)
                                          : Colors.white,
                                      borderRadius:
                                          BorderRadius.circular(18),
                                      border: Border.all(
                                        color: isPending
                                            ? Colors.red.shade200
                                            : Colors.transparent,
                                        width: 1.5,
                                      ),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.black
                                              .withOpacity(0.04),
                                          blurRadius: 10,
                                          offset: const Offset(0, 2),
                                        ),
                                      ],
                                    ),
                                    child: Row(
                                      children: [
                                        Container(
                                          width: 46,
                                          height: 46,
                                          decoration: BoxDecoration(
                                            color: (isIncome
                                                    ? primary
                                                    : catColor)
                                                .withOpacity(0.12),
                                            shape: BoxShape.circle,
                                          ),
                                          child: Icon(
                                            catIcon,
                                            color: isIncome
                                                ? primary
                                                : catColor,
                                            size: 22,
                                          ),
                                        ),
                                        const SizedBox(width: 14),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                tx.title,
                                                style: const TextStyle(
                                                  color: textMain,
                                                  fontSize: 15,
                                                  fontWeight:
                                                      FontWeight.w600,
                                                ),
                                                maxLines: 1,
                                                overflow:
                                                    TextOverflow.ellipsis,
                                              ),
                                              const SizedBox(height: 3),
                                              Text(
                                                dateStr,
                                                style: TextStyle(
                                                  color: Colors.black
                                                      .withOpacity(0.45),
                                                  fontSize: 12,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                        if (isPending)
                                          GestureDetector(
                                            onTap: () {
                                              txProvider.deleteTransaction(
                                                  tx.id);
                                              setState(() =>
                                                  _deletePendingId = null);
                                              showTopToast(context,
                                                  '${tx.title} deleted');
                                            },
                                            child: Container(
                                              width: 38,
                                              height: 38,
                                              decoration: const BoxDecoration(
                                                color: Colors.red,
                                                shape: BoxShape.circle,
                                              ),
                                              child: const Icon(
                                                Icons.delete_outline,
                                                color: Colors.white,
                                                size: 20,
                                              ),
                                            ),
                                          )
                                        else
                                          Text(
                                            '${isIncome ? '+' : '-'}${currencyFormat.format(tx.amount)}',
                                            style: TextStyle(
                                              color: isIncome
                                                  ? greenAccent
                                                  : redAccent,
                                              fontSize: 15,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                      ],
                                    ),
                                  ),
                                ),
                              );
                            }),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),

          // ─── Floating Nav Bar ───
          const FloatingNavBar(currentIndex: 0),
        ],
      ),
      ),
    );
  }

  // ──── Category circle items ────
  Widget _buildCategoryCircle({
    required IconData icon,
    required String label,
    required Color color,
    required Color bgColor,
    int count = 0,
    VoidCallback? onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Stack(
            clipBehavior: Clip.none,
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: bgColor,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: color.withOpacity(0.15),
                      blurRadius: 8,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: Icon(icon, color: color, size: 26),
              ),
              if (count > 0)
                Positioned(
                  top: -4,
                  right: -4,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: color,
                      shape: BoxShape.circle,
                      border:
                          Border.all(color: const Color(0xFFF8F6FC), width: 2),
                    ),
                    constraints: const BoxConstraints(
                      minWidth: 22,
                      minHeight: 22,
                    ),
                    child: Center(
                      child: Text(
                        '$count',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: TextStyle(
              color: Colors.black.withOpacity(0.6),
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

}
