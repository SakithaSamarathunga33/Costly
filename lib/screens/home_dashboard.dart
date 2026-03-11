import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/auth_provider.dart';
import '../providers/transaction_provider.dart';
import '../utils/constants.dart';

class HomeDashboard extends StatefulWidget {
  const HomeDashboard({super.key});

  @override
  State<HomeDashboard> createState() => _HomeDashboardState();
}

class _HomeDashboardState extends State<HomeDashboard> {
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    // Fetch transactions when dashboard loads
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      if (authProvider.isLoggedIn) {
        Provider.of<TransactionProvider>(context, listen: false)
            .fetchTransactions(authProvider.userId);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    const Color primary = Color(0xFF00ADB5);
    const Color bgDark = Color(0xFF222831);
    const Color secondary = Color(0xFF393E46);
    const Color textMain = Colors.white;

    // Listen to providers for live data
    final authProvider = Provider.of<AuthProvider>(context);
    final txProvider = Provider.of<TransactionProvider>(context);

    // Format currency values
    final currencyFormat = NumberFormat.currency(symbol: '\$', decimalDigits: 2);
    final balanceStr = currencyFormat.format(txProvider.currentBalance);
    final incomeStr = currencyFormat.format(txProvider.totalIncome);
    final expenseStr = currencyFormat.format(txProvider.totalExpenses);

    // Get category totals for the grid
    final categoryTotals = txProvider.expensesByCategory;

    return Scaffold(
      backgroundColor: bgDark,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding:
                const EdgeInsets.only(bottom: 100.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header - uses actual user name from auth
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 20,
                        backgroundColor: primary,
                        child: Text(
                          authProvider.userName.isNotEmpty
                              ? authProvider.userName[0].toUpperCase()
                              : 'U',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Welcome back,',
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.6),
                                fontSize: 12,
                              ),
                            ),
                            Text(
                              authProvider.userName,
                              style: const TextStyle(
                                color: textMain,
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        decoration: BoxDecoration(
                          color: secondary,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: IconButton(
                          icon: const Icon(Icons.notifications_outlined,
                              color: primary),
                          onPressed: () {},
                        ),
                      ),
                    ],
                  ),
                ),

                // Main Balance Card - uses live calculated balance
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [primary, primary.withOpacity(0.7)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [
                        BoxShadow(
                          color: primary.withOpacity(0.3),
                          blurRadius: 16,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Total Balance',
                                  style: TextStyle(
                                    color: Colors.white.withOpacity(0.8),
                                    fontSize: 14,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                const SizedBox(height: 4),
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
                            ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: Image.asset(
                                'assets/images/logo.png',
                                width: 36,
                                height: 36,
                                fit: BoxFit.contain,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 32),
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                                color: Colors.white.withOpacity(0.1)),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Card Number',
                                style: TextStyle(
                                  color: Colors.white70,
                                  fontSize: 12,
                                ),
                              ),
                              const SizedBox(height: 4),
                              const Text(
                                '**** **** **** 4290',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontFamily: 'monospace',
                                  fontSize: 14,
                                  letterSpacing: 2,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Stats Row - uses live income/expense totals
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: Row(
                    children: [
                      _buildStatCard(
                        title: 'INCOME',
                        amount: incomeStr,
                        change: '${txProvider.incomeList.length} transactions',
                        icon: Icons.arrow_downward,
                        iconColor: Colors.green,
                        secondary: secondary,
                      ),
                      const SizedBox(width: 16),
                      _buildStatCard(
                        title: 'EXPENSES',
                        amount: expenseStr,
                        change: '${txProvider.expenses.length} transactions',
                        icon: Icons.arrow_upward,
                        iconColor: Colors.red,
                        secondary: secondary,
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
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: () {
                                Navigator.pushNamed(context, '/add_income');
                              },
                              icon: const Icon(Icons.add_circle_outline,
                                  size: 20),
                              label: const Text('Add Income',
                                  style:
                                      TextStyle(fontWeight: FontWeight.bold)),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: primary,
                                foregroundColor: Colors.white,
                                padding:
                                    const EdgeInsets.symmetric(vertical: 16),
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12)),
                                elevation: 8,
                                shadowColor: primary.withOpacity(0.4),
                              ),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: () {
                                Navigator.pushNamed(context, '/add_expense');
                              },
                              icon: const Icon(Icons.remove_circle_outline,
                                  size: 20),
                              label: const Text('Add Expense',
                                  style:
                                      TextStyle(fontWeight: FontWeight.bold)),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: secondary,
                                foregroundColor: Colors.white,
                                padding:
                                    const EdgeInsets.symmetric(vertical: 16),
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12)),
                                elevation: 8,
                                shadowColor: Colors.black26,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // Categories Grid - uses live category totals
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Categories',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          TextButton(
                            onPressed: () {
                              Navigator.pushNamed(context, '/analytics');
                            },
                            child: const Text(
                              'View All',
                              style: TextStyle(
                                  color: primary, fontWeight: FontWeight.bold),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          _buildCategoryItem(
                            Icons.restaurant,
                            'FOOD',
                            currencyFormat
                                .format(categoryTotals['Food'] ?? 0),
                            Colors.orange,
                          ),
                          _buildCategoryItem(
                            Icons.directions_car,
                            'TRANSPORT',
                            currencyFormat
                                .format(categoryTotals['Transport'] ?? 0),
                            Colors.blue,
                          ),
                          _buildCategoryItem(
                            Icons.shopping_bag,
                            'SHOPPING',
                            currencyFormat
                                .format(categoryTotals['Shopping'] ?? 0),
                            Colors.purple,
                          ),
                          _buildCategoryItem(
                            Icons.receipt_long,
                            'BILLS',
                            currencyFormat
                                .format(categoryTotals['Bills'] ?? 0),
                            Colors.green,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // Recent Transactions - uses live transaction data
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
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          TextButton(
                            onPressed: () {
                              Navigator.pushNamed(
                                  context, '/transactions_history');
                            },
                            child: const Text(
                              'See All',
                              style: TextStyle(
                                  color: primary, fontWeight: FontWeight.bold),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      // Show live recent transactions or empty state
                      if (txProvider.recentTransactions.isEmpty)
                        Container(
                          padding: const EdgeInsets.all(24),
                          decoration: BoxDecoration(
                            color: secondary.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Center(
                            child: Text(
                              'No transactions yet.\nAdd your first income or expense!',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.5),
                                fontSize: 14,
                              ),
                            ),
                          ),
                        )
                      else
                        ...txProvider.recentTransactions.map((tx) {
                          final isIncome = tx.type == 'income';
                          final catColor = getCategoryColor(tx.category);
                          final catIcon = getCategoryIconByName(tx.category);
                          final dateStr =
                              DateFormat('MMM dd, yyyy').format(tx.date);
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: _buildTransactionItem(
                              icon: catIcon,
                              iconColor: isIncome ? primary : catColor,
                              bgLight: (isIncome ? primary : catColor)
                                  .withOpacity(0.1),
                              title: tx.title,
                              subtitle: dateStr,
                              amount:
                                  '${isIncome ? '+' : '-'}${currencyFormat.format(tx.amount)}',
                              amountColor:
                                  isIncome ? Colors.green : Colors.red,
                              secondary: secondary,
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
      floatingActionButton: Container(
        height: 60,
        width: 60,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: _currentIndex == 1
                  ? const Color(0xFFF25C05).withOpacity(0.6)
                  : primary.withOpacity(0.6),
              blurRadius: 16,
              spreadRadius: 4,
            ),
          ],
        ),
        child: FloatingActionButton(
          onPressed: () {
            Navigator.pushNamed(context, '/add_expense');
          },
          backgroundColor:
              _currentIndex == 1 ? const Color(0xFFF25C05) : primary,
          elevation: 0,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
          child: const Icon(Icons.add, color: Colors.white, size: 32),
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,

      bottomNavigationBar: BottomAppBar(
        color: secondary,
        surfaceTintColor: Colors.transparent,
        shape: const CircularNotchedRectangle(),
        notchMargin: 8.0,
        child: SizedBox(
          height: 60,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildNavItem(
                  icon: Icons.home,
                  label: 'HOME',
                  isActive: _currentIndex == 0,
                  index: 0,
                  color:
                      _currentIndex == 1 ? const Color(0xFFF25C05) : primary),
              _buildNavItem(
                  icon: Icons.receipt_long,
                  label: 'HISTORY',
                  isActive: _currentIndex == 1,
                  index: 1,
                  color:
                      _currentIndex == 1 ? const Color(0xFFF25C05) : primary),
              const SizedBox(width: 48),
              _buildNavItem(
                  icon: Icons.pie_chart,
                  label: 'BUDGET',
                  isActive: _currentIndex == 2,
                  index: 2,
                  color:
                      _currentIndex == 1 ? const Color(0xFFF25C05) : primary),
              _buildNavItem(
                  icon: Icons.person,
                  label: 'PROFILE',
                  isActive: _currentIndex == 3,
                  index: 3,
                  color:
                      _currentIndex == 1 ? const Color(0xFFF25C05) : primary),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatCard({
    required String title,
    required String amount,
    required String change,
    required IconData icon,
    required Color iconColor,
    required Color secondary,
  }) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: secondary.withOpacity(0.4),
          border: Border.all(color: Colors.white.withOpacity(0.05)),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: iconColor, size: 16),
                const SizedBox(width: 4),
                Text(
                  title,
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.6),
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              amount,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              change,
              style: TextStyle(
                color: iconColor,
                fontSize: 10,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryItem(
      IconData icon, String title, String amount, Color color) {
    return Column(
      children: [
        Container(
          width: 56,
          height: 56,
          decoration: BoxDecoration(
            color: color.withOpacity(0.2),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Icon(icon, color: color, size: 28),
        ),
        const SizedBox(height: 8),
        Text(
          title,
          style: TextStyle(
            color: Colors.white.withOpacity(0.6),
            fontSize: 10,
            fontWeight: FontWeight.bold,
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          amount,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 12,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildTransactionItem({
    required IconData icon,
    required Color iconColor,
    required Color bgLight,
    required String title,
    required String subtitle,
    required String amount,
    required Color amountColor,
    required Color secondary,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: secondary.withOpacity(0.2),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: bgLight,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: iconColor, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.6),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          Text(
            amount,
            style: TextStyle(
              color: amountColor,
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNavItem({
    required IconData icon,
    required String label,
    required int index,
    required Color color,
    bool isActive = false,
  }) {
    return InkWell(
      onTap: () {
        setState(() {
          _currentIndex = index;
        });
        if (index == 1) {
          Navigator.pushNamed(context, '/transactions_history');
        } else if (index == 2) {
          Navigator.pushNamed(context, '/analytics');
        } else if (index == 3) {
          Navigator.pushNamed(context, '/profile');
        }
      },
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: isActive ? color : Colors.white.withOpacity(0.4)),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              color: isActive ? color : Colors.white.withOpacity(0.4),
              fontSize: 10,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}
