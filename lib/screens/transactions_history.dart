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
  String? _tagFilter;
  final Set<String> _selectedIds = {};
  final _searchController = TextEditingController();

  bool get _selectionActive => _selectedIds.isNotEmpty;
  void _exitSelection() => setState(() => _selectedIds.clear());

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Read filter from route arguments
    final args = ModalRoute.of(context)?.settings.arguments;
    if (args is String && _categoryFilter == null) {
      _categoryFilter = args;
    } else if (args is Map<String, dynamic> && _filterIndex == 0) {
      final type = args['type'] as String?;
      if (type == 'income') _filterIndex = 2;
      if (type == 'expense') _filterIndex = 1;
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

    // Apply tag filter if set
    if (_tagFilter != null) {
      filtered =
          filtered.where((tx) => tx.tags.contains(_tagFilter)).toList();
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
    final cs = Theme.of(context).colorScheme;
    const Color primary = Color(0xFF5D3891);
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

    return PopScope(
      canPop: !_selectionActive,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop && _selectionActive) _exitSelection();
      },
      child: RootBackHandler(
      child: Scaffold(
      backgroundColor: cs.surface,
      appBar: AppBar(
        backgroundColor: cs.surface,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        automaticallyImplyLeading: false,
        centerTitle: true,
        leading: _selectionActive
            ? IconButton(
                icon: Icon(Icons.close_rounded,
                    color: cs.onSurface, size: 22),
                onPressed: _exitSelection,
              )
            : null,
        title: _selectionActive
            ? Text(
                '${_selectedIds.length} selected',
                style: TextStyle(
                  color: cs.onSurface,
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                ),
              )
            : Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Transaction History',
                    style: TextStyle(
                      color: cs.onSurface,
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  Text(
                    DateFormat('MMMM yyyy').format(txProvider.selectedMonth),
                    style: TextStyle(
                      color: cs.onSurface.withOpacity(0.5),
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
        actions: _selectionActive
            ? [
                IconButton(
                  icon: Icon(Icons.select_all_rounded,
                      color: cs.onSurface, size: 22),
                  tooltip: 'Select all',
                  onPressed: () => setState(() => _selectedIds
                      .addAll(filteredTx.map((t) => t.id))),
                ),
                IconButton(
                  icon: const Icon(Icons.delete_outline_rounded,
                      color: Colors.red, size: 22),
                  tooltip: 'Delete selected',
                  onPressed: () async {
                    final ids = _selectedIds.toList();
                    _exitSelection();
                    await txProvider.deleteTransactions(ids);
                    if (mounted) {
                      showTopToast(
                          context, '${ids.length} transaction${ids.length == 1 ? '' : 's'} deleted');
                    }
                  },
                ),
              ]
            : [
                IconButton(
                  icon: Icon(Icons.calendar_today_outlined,
                      color: cs.onSurface, size: 20),
                  onPressed: () {},
                ),
              ],
      ),
      body: Stack(
        children: [
          ScreenEntrance(
            child: CustomScrollView(
              slivers: [
                // --- Summary Card ---
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
                            style: TextStyle(
                              color: cs.surfaceContainerLow,
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

                // --- Search Bar ---
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 20, vertical: 10),
                    child: Container(
                      decoration: BoxDecoration(
                        color: cs.surfaceContainerLow,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                            color: Colors.grey.withOpacity(0.15), width: 1),
                      ),
                      child: TextField(
                        controller: _searchController,
                        style: TextStyle(color: cs.onSurface, fontSize: 14),
                        onChanged: (value) =>
                            setState(() => _searchQuery = value),
                        decoration: InputDecoration(
                          hintText: 'Search transactions',
                          hintStyle: TextStyle(
                            color: cs.onSurface.withOpacity(0.3),
                            fontSize: 14,
                          ),
                          prefixIcon: Icon(Icons.search,
                              color: cs.onSurface.withOpacity(0.35), size: 20),
                          suffixIcon: _searchQuery.isNotEmpty
                              ? IconButton(
                                  icon: Icon(Icons.clear,
                                      color: cs.onSurface.withOpacity(0.4),
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

                // --- Filter Chips ---
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

                // --- Active Category Filter ---
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

                // --- Active Tag Filter ---
                if (_tagFilter != null)
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 20, vertical: 4),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: primary.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                  color: primary.withValues(alpha: 0.3)),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.label_outline,
                                    size: 14, color: primary),
                                const SizedBox(width: 6),
                                Text(
                                  '#$_tagFilter',
                                  style: TextStyle(
                                    color: primary,
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const SizedBox(width: 6),
                                GestureDetector(
                                  onTap: () =>
                                      setState(() => _tagFilter = null),
                                  child: const Icon(Icons.close,
                                      size: 14, color: primary),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                const SliverToBoxAdapter(child: SizedBox(height: 8)),

                // --- Grouped Transaction List ---
                if (filteredTx.isEmpty)
                  SliverFillRemaining(
                    hasScrollBody: false,
                    child: Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.receipt_long,
                              size: 56, color: cs.onSurface.withOpacity(0.15)),
                          const SizedBox(height: 12),
                          Text(
                            'No transactions found',
                            style: TextStyle(
                              color: cs.onSurface.withOpacity(0.4),
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
                              color: cs.onSurface.withOpacity(0.4),
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

                              return GestureDetector(
                                onLongPress: () =>
                                    setState(() => _selectedIds.add(tx.id)),
                                onTap: _selectionActive
                                    ? () => setState(() {
                                          if (_selectedIds.contains(tx.id)) {
                                            _selectedIds.remove(tx.id);
                                          } else {
                                            _selectedIds.add(tx.id);
                                          }
                                        })
                                    : null,
                                child: Dismissible(
                                key: Key(tx.id),
                                direction: _selectionActive
                                    ? DismissDirection.none
                                    : DismissDirection.endToStart,
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
                                    color: _selectedIds.contains(tx.id)
                                        ? primary.withValues(alpha: 0.08)
                                        : Colors.white,
                                    borderRadius: BorderRadius.circular(16),
                                    border: _selectedIds.contains(tx.id)
                                        ? Border.all(
                                            color: primary.withValues(alpha: 0.4),
                                            width: 1.5)
                                        : null,
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
                                              style: TextStyle(
                                                color: cs.onSurface,
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
                                                    cs.onSurface.withOpacity(0.4),
                                                fontSize: 12,
                                                fontWeight: FontWeight.w400,
                                              ),
                                            ),
                                            if (tx.tags.isNotEmpty) ...[
                                              const SizedBox(height: 5),
                                              Wrap(
                                                spacing: 4,
                                                runSpacing: 2,
                                                children: tx.tags
                                                    .map((tag) => GestureDetector(
                                                          onTap: () => setState(
                                                              () => _tagFilter =
                                                                  _tagFilter ==
                                                                          tag
                                                                      ? null
                                                                      : tag),
                                                          child: Container(
                                                            padding:
                                                                const EdgeInsets
                                                                    .symmetric(
                                                                    horizontal:
                                                                        7,
                                                                    vertical:
                                                                        2),
                                                            decoration:
                                                                BoxDecoration(
                                                              color: _tagFilter ==
                                                                      tag
                                                                  ? primary
                                                                  : primary
                                                                      .withValues(
                                                                          alpha:
                                                                              0.1),
                                                              borderRadius:
                                                                  BorderRadius
                                                                      .circular(
                                                                          10),
                                                            ),
                                                            child: Text(
                                                              '#$tag',
                                                              style: TextStyle(
                                                                fontSize: 10,
                                                                fontWeight:
                                                                    FontWeight
                                                                        .w600,
                                                                color: _tagFilter ==
                                                                        tag
                                                                    ? Colors
                                                                        .white
                                                                    : primary,
                                                              ),
                                                            ),
                                                          ),
                                                        ))
                                                    .toList(),
                                              ),
                                            ],
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
                                                  : cs.onSurface,
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
                                            icon: Icon(
                                              Icons.edit_outlined,
                                              size: 18,
                                              color: cs.onSurface,
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
                              ),
                              ); // GestureDetector
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
      ),
    );
  }

  // --- Filter Chip ---
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
