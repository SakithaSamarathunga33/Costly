import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/auth_provider.dart';
import '../providers/transaction_provider.dart';
import '../providers/category_provider.dart';
import '../models/transaction_model.dart';
import '../screens/edit_transaction.dart';
import '../utils/constants.dart';
import '../widgets/floating_nav_bar.dart';
import '../widgets/app_animations.dart';
import '../widgets/root_back_handler.dart';
import '../utils/top_toast.dart';

class TransactionsHistoryScreen extends StatefulWidget {
  const TransactionsHistoryScreen({super.key});

  @override
  State<TransactionsHistoryScreen> createState() =>
      _TransactionsHistoryScreenState();
}

class _TransactionsHistoryScreenState extends State<TransactionsHistoryScreen> {
  int _filterIndex = 0;
  String _searchQuery = '';
  String? _categoryFilter;
  final _searchController = TextEditingController();

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Read category filter from route arguments (passed from category tap)
    final args = ModalRoute.of(context)?.settings.arguments;
    if (args is String && _categoryFilter == null) {
      _categoryFilter = args;
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _clearCategoryFilter() {
    setState(() => _categoryFilter = null);
  }

  List<TransactionModel> _getFilteredTransactions(
      TransactionProvider provider) {
    List<TransactionModel> filtered;

    switch (_filterIndex) {
      case 1:
        filtered = provider.expenses;
        break;
      case 2:
        filtered = provider.incomeList;
        break;
      default:
        filtered = provider.transactions;
    }

    // Apply category filter if set
    if (_categoryFilter != null) {
      filtered =
          filtered.where((tx) => tx.category == _categoryFilter).toList();
    }

    if (_searchQuery.isNotEmpty) {
      filtered = filtered.where((tx) {
        return tx.title.toLowerCase().contains(_searchQuery.toLowerCase()) ||
            tx.category.toLowerCase().contains(_searchQuery.toLowerCase()) ||
            tx.notes.toLowerCase().contains(_searchQuery.toLowerCase());
      }).toList();
    }

    filtered = List.from(filtered);
    filtered.sort((a, b) => b.date.compareTo(a.date));
    return filtered;
  }

  /// Groups transactions by date label (TODAY/YESTERDAY only when viewing current month).
  Map<String, List<TransactionModel>> _groupByDate(
    List<TransactionModel> transactions,
    bool useRelativeDayLabels,
  ) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final Map<String, List<TransactionModel>> grouped = {};

    for (final tx in transactions) {
      final txDate = DateTime(tx.date.year, tx.date.month, tx.date.day);
      String label;

      if (!useRelativeDayLabels) {
        label = DateFormat('EEE, MMM d').format(tx.date).toUpperCase();
      } else if (txDate == today) {
        label = 'TODAY, ${DateFormat('MMM d').format(tx.date).toUpperCase()}';
      } else if (txDate == yesterday) {
        label =
            'YESTERDAY, ${DateFormat('MMM d').format(tx.date).toUpperCase()}';
      } else {
        label = DateFormat('MMM d').format(tx.date).toUpperCase();
      }

      grouped.putIfAbsent(label, () => []);
      grouped[label]!.add(tx);
    }

    return grouped;
  }

  @override
  Widget build(BuildContext context) {
    const Color primary = Color(0xFF5D3891);
    const Color bg = Color(0xFFF8F6FC);
    const Color textMain = Color(0xFF2D2D2D);

    final txProvider = Provider.of<TransactionProvider>(context);
    final authProvider = Provider.of<AuthProvider>(context);
    final customCats = Provider.of<CategoryProvider>(context).customCategories;
    final filteredTx = _getFilteredTransactions(txProvider);
    final groupedTx = _groupByDate(
      filteredTx,
      txProvider.isViewingCurrentMonth,
    );
    final currencySymbol = authProvider.currencySymbol;
    final currencyFormat =
        NumberFormat.currency(symbol: '$currencySymbol ', decimalDigits: 2);

    final sm = txProvider.selectedMonth;
    final monthTotal = txProvider.netCashFlowForMonth(sm);
    final prevMonth = DateTime(sm.year, sm.month - 1, 1);
    final lastMonthTotal = txProvider.netCashFlowForMonth(prevMonth);

    final percentChange = lastMonthTotal != 0
        ? ((monthTotal - lastMonthTotal) / lastMonthTotal.abs() * 100)
        : 0.0;

    return RootBackHandler(
      child: Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        backgroundColor: bg,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        automaticallyImplyLeading: false,
        centerTitle: true,
        title: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Transaction History',
              style: TextStyle(
                color: textMain,
                fontSize: 18,
                fontWeight: FontWeight.w700,
              ),
            ),
            Text(
              DateFormat('MMMM yyyy').format(txProvider.selectedMonth),
              style: TextStyle(
                color: textMain.withOpacity(0.5),
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.calendar_today_outlined,
                color: textMain, size: 20),
            onPressed: () {},
          ),
        ],
      ),
      body: Stack(
        children: [
          ScreenEntrance(
            child: CustomScrollView(
              slivers: [
                // ─── Summary Card ───
                SliverToBoxAdapter(
                  child: Padding(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                    child: Container(
                      padding: const EdgeInsets.all(22),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF5D3891), Color(0xFF7B52AB)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: primary.withOpacity(0.35),
                            blurRadius: 20,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${DateFormat('MMMM').format(sm).toUpperCase()} SUMMARY',
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.6),
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 1.5,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            currencyFormat.format(monthTotal.abs()),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 32,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Row(
                            children: [
                              Icon(
                                percentChange >= 0
                                    ? Icons.trending_up
                                    : Icons.trending_down,
                                color: percentChange >= 0
                                    ? const Color(0xFF4ADE80)
                                    : const Color(0xFFEF4444),
                                size: 16,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                '${percentChange >= 0 ? '+' : ''}${percentChange.toStringAsFixed(0)}% vs last month',
                                style: TextStyle(
                                  color: percentChange >= 0
                                      ? const Color(0xFF4ADE80)
                                      : const Color(0xFFEF4444),
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

                // ─── Search Bar ───
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 20, vertical: 10),
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                            color: Colors.grey.withOpacity(0.15), width: 1),
                      ),
                      child: TextField(
                        controller: _searchController,
                        style: const TextStyle(color: textMain, fontSize: 14),
                        onChanged: (value) =>
                            setState(() => _searchQuery = value),
                        decoration: InputDecoration(
                          hintText: 'Search transactions',
                          hintStyle: TextStyle(
                            color: textMain.withOpacity(0.3),
                            fontSize: 14,
                          ),
                          prefixIcon: Icon(Icons.search,
                              color: textMain.withOpacity(0.35), size: 20),
                          suffixIcon: _searchQuery.isNotEmpty
                              ? IconButton(
                                  icon: Icon(Icons.clear,
                                      color: textMain.withOpacity(0.4),
                                      size: 18),
                                  onPressed: () {
                                    _searchController.clear();
                                    setState(() => _searchQuery = '');
                                  },
                                )
                              : null,
                          border: InputBorder.none,
                          contentPadding:
                              const EdgeInsets.symmetric(vertical: 14),
                        ),
                      ),
                    ),
                  ),
                ),

                // ─── Filter Chips ───
                SliverToBoxAdapter(
                  child: Padding(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
                    child: Row(
                      children: [
                        _buildChip('All', 0, primary),
                        const SizedBox(width: 10),
                        _buildChip('Expenses', 1, primary),
                        const SizedBox(width: 10),
                        _buildChip('Income', 2, primary),
                      ],
                    ),
                  ),
                ),

                // ─── Active Category Filter ───
                if (_categoryFilter != null)
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 20, vertical: 6),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 14, vertical: 8),
                            decoration: BoxDecoration(
                              color:
                                  getCategoryColor(_categoryFilter!, customCats)
                                      .withOpacity(0.12),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: getCategoryColor(
                                        _categoryFilter!, customCats)
                                    .withOpacity(0.3),
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  getCategoryIconByName(
                                      _categoryFilter!, customCats),
                                  size: 16,
                                  color: getCategoryColor(
                                      _categoryFilter!, customCats),
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  _categoryFilter!,
                                  style: TextStyle(
                                    color: getCategoryColor(
                                        _categoryFilter!, customCats),
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const SizedBox(width: 6),
                                GestureDetector(
                                  onTap: _clearCategoryFilter,
                                  child: Icon(
                                    Icons.close,
                                    size: 16,
                                    color: getCategoryColor(
                                        _categoryFilter!, customCats),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                const SliverToBoxAdapter(child: SizedBox(height: 8)),

                // ─── Grouped Transaction List ───
                if (filteredTx.isEmpty)
                  SliverFillRemaining(
                    hasScrollBody: false,
                    child: Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.receipt_long,
                              size: 56, color: textMain.withOpacity(0.15)),
                          const SizedBox(height: 12),
                          Text(
                            'No transactions found',
                            style: TextStyle(
                              color: textMain.withOpacity(0.4),
                              fontSize: 15,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                else
                  ...groupedTx.entries.expand((entry) {
                    return [
                      // Date header
                      SliverToBoxAdapter(
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(20, 14, 20, 8),
                          child: Text(
                            entry.key,
                            style: TextStyle(
                              color: textMain.withOpacity(0.4),
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.8,
                            ),
                          ),
                        ),
                      ),
                      // Transaction items for this date
                      SliverPadding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        sliver: SliverList(
                          delegate: SliverChildBuilderDelegate(
                            (context, index) {
                              final tx = entry.value[index];
                              final isIncome = tx.type == 'income';
                              final catColor =
                                  getCategoryColor(tx.category, customCats);
                              final catIcon = getCategoryIconByName(
                                  tx.category, customCats);
                              final timeStr =
                                  DateFormat('hh:mm a').format(tx.date);

                              return Dismissible(
                                key: Key(tx.id),
                                direction: DismissDirection.endToStart,
                                background: Container(
                                  margin: const EdgeInsets.only(bottom: 10),
                                  decoration: BoxDecoration(
                                    color: Colors.red,
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                  alignment: Alignment.centerRight,
                                  padding: const EdgeInsets.only(right: 24),
                                  child: const Icon(Icons.delete,
                                      color: Colors.white),
                                ),
                                onDismissed: (_) {
                                  txProvider.deleteTransaction(tx.id);
                                  showTopToast(context, '${tx.title} deleted');
                                },
                                child: Container(
                                  margin: const EdgeInsets.only(bottom: 10),
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 14, vertical: 14),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(16),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withOpacity(0.03),
                                        blurRadius: 8,
                                        offset: const Offset(0, 2),
                                      ),
                                    ],
                                  ),
                                  child: Row(
                                    children: [
                                      // Category icon
                                      Container(
                                        width: 44,
                                        height: 44,
                                        decoration: BoxDecoration(
                                          color: (isIncome ? primary : catColor)
                                              .withOpacity(0.1),
                                          borderRadius:
                                              BorderRadius.circular(12),
                                        ),
                                        child: Icon(
                                          catIcon,
                                          color: isIncome ? primary : catColor,
                                          size: 20,
                                        ),
                                      ),
                                      const SizedBox(width: 14),
                                      // Title + category & time
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
                                                fontWeight: FontWeight.w600,
                                              ),
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                            const SizedBox(height: 3),
                                            Text(
                                              '${tx.category} • $timeStr',
                                              style: TextStyle(
                                                color:
                                                    textMain.withOpacity(0.4),
                                                fontSize: 12,
                                                fontWeight: FontWeight.w400,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      // Amount
                                      Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Text(
                                            '${isIncome ? '+' : '-'}\$${tx.amount.toStringAsFixed(2)}',
                                            style: TextStyle(
                                              color: isIncome
                                                  ? const Color(0xFF22C55E)
                                                  : textMain,
                                              fontSize: 15,
                                              fontWeight: FontWeight.w700,
                                            ),
                                          ),
                                          const SizedBox(width: 4),
                                          IconButton(
                                            tooltip: 'Edit transaction',
                                            onPressed: () {
                                              Navigator.push(
                                                context,
                                                MaterialPageRoute(
                                                  builder: (_) =>
                                                      EditTransactionScreen(
                                                    transaction: tx,
                                                  ),
                                                ),
                                              );
                                            },
                                            icon: const Icon(
                                              Icons.edit_outlined,
                                              size: 18,
                                              color: textMain,
                                            ),
                                            visualDensity:
                                                VisualDensity.compact,
                                            constraints: const BoxConstraints(),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                            childCount: entry.value.length,
                          ),
                        ),
                      ),
                    ];
                  }),

                // Bottom padding for nav bar
                const SliverToBoxAdapter(child: SizedBox(height: 110)),
              ],
            ),
          ),
          const FloatingNavBar(currentIndex: 1),
        ],
      ),
      ),
    );
  }

  // ─── Filter Chip ───
  Widget _buildChip(String label, int index, Color primary) {
    final isActive = _filterIndex == index;
    return GestureDetector(
      onTap: () => setState(() => _filterIndex = index),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 10),
        decoration: BoxDecoration(
          color: isActive ? primary : Colors.white,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: isActive ? primary : Colors.grey.withOpacity(0.2),
            width: 1.5,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isActive ? Colors.white : const Color(0xFF2D2D2D),
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}
