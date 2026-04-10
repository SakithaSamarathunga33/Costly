import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/auth_provider.dart';
import '../providers/transaction_provider.dart';
import '../providers/category_provider.dart';
import '../models/transaction_model.dart';
import '../screens/edit_transaction.dart';
import '../utils/constants.dart';
import '../widgets/app_animations.dart';
import '../utils/top_toast.dart';

class IncomeListScreen extends StatefulWidget {
  const IncomeListScreen({super.key});

  @override
  State<IncomeListScreen> createState() => _IncomeListScreenState();
}

class _IncomeListScreenState extends State<IncomeListScreen> {
  String _searchQuery = '';
  final Set<String> _selectedIds = {};
  final _searchController = TextEditingController();

  bool get _selectionActive => _selectedIds.isNotEmpty;

  void _exitSelection() => setState(() => _selectedIds.clear());

  Future<void> _confirmDeleteSelected(TransactionProvider txProvider) async {
    final n = _selectedIds.length;
    if (n == 0) return;
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete income'),
        content: Text(
          n == 1
              ? 'Delete this income entry?'
              : 'Delete $n income entries?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (ok != true || !mounted) return;
    final ids = _selectedIds.toList();
    final success = await txProvider.deleteTransactions(ids);
    if (!mounted) return;
    setState(() => _selectedIds.clear());
    if (success) {
      showTopToast(
        context,
        n == 1 ? '1 entry deleted' : '$n entries deleted',
      );
    } else if (txProvider.error != null) {
      showTopToast(context, txProvider.error!);
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<TransactionModel> _getFiltered(TransactionProvider provider) {
    List<TransactionModel> filtered = List.from(provider.incomeList);

    if (_searchQuery.isNotEmpty) {
      filtered = filtered.where((tx) {
        return tx.title.toLowerCase().contains(_searchQuery.toLowerCase()) ||
            tx.category.toLowerCase().contains(_searchQuery.toLowerCase()) ||
            tx.notes.toLowerCase().contains(_searchQuery.toLowerCase());
      }).toList();
    }

    filtered.sort((a, b) => b.date.compareTo(a.date));
    return filtered;
  }

  Map<String, List<TransactionModel>> _groupByDate(
      List<TransactionModel> transactions, bool useRelative) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final Map<String, List<TransactionModel>> grouped = {};

    for (final tx in transactions) {
      final txDate = DateTime(tx.date.year, tx.date.month, tx.date.day);
      String label;
      if (!useRelative) {
        label = DateFormat('EEE, MMM d').format(tx.date).toUpperCase();
      } else if (txDate == today) {
        label = 'TODAY, ${DateFormat('MMM d').format(tx.date).toUpperCase()}';
      } else if (txDate == yesterday) {
        label = 'YESTERDAY, ${DateFormat('MMM d').format(tx.date).toUpperCase()}';
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
    const Color green = Color(0xFF2ECC71);
    const Color bg = Color(0xFFF8F6FC);
    const Color textMain = Color(0xFF2D2D2D);

    final txProvider = Provider.of<TransactionProvider>(context);
    final authProvider = Provider.of<AuthProvider>(context);
    final customCats = Provider.of<CategoryProvider>(context).customCategories;

    final currencySymbol = authProvider.currencySymbol;
    final currencyFormat =
        NumberFormat.currency(symbol: '$currencySymbol ', decimalDigits: 2);

    final filtered = _getFiltered(txProvider);
    final grouped = _groupByDate(filtered, txProvider.isViewingCurrentMonth);

    final sm = txProvider.selectedMonth;
    final totalIncome = txProvider.totalIncome;

    return PopScope(
      canPop: !_selectionActive,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop && _selectionActive) {
          _exitSelection();
        }
      },
      child: Scaffold(
        backgroundColor: bg,
        appBar: AppBar(
          backgroundColor: bg,
          elevation: 0,
          surfaceTintColor: Colors.transparent,
          leading: _selectionActive
              ? IconButton(
                  icon:
                      const Icon(Icons.close_rounded, color: textMain, size: 22),
                  onPressed: _exitSelection,
                  tooltip: 'Cancel',
                )
              : IconButton(
                  icon: const Icon(Icons.arrow_back_rounded,
                      color: textMain, size: 22),
                  onPressed: () => Navigator.pop(context),
                ),
          centerTitle: true,
          title: _selectionActive
              ? Text(
                  '${_selectedIds.length} selected',
                  style: const TextStyle(
                    color: textMain,
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                  ),
                )
              : Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      'Income',
                      style: TextStyle(
                        color: textMain,
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Text(
                      DateFormat('MMMM yyyy').format(sm),
                      style: TextStyle(
                        color: textMain.withOpacity(0.5),
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
          actions: _selectionActive
              ? [
                  IconButton(
                    icon: const Icon(Icons.delete_outline_rounded,
                        color: Colors.red, size: 24),
                    tooltip: 'Delete selected',
                    onPressed:
                        _selectedIds.isEmpty ? null : () => _confirmDeleteSelected(txProvider),
                  ),
                ]
              : null,
        ),
      body: ScreenEntrance(
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
                      colors: [Color(0xFF27AE60), Color(0xFF2ECC71)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: green.withOpacity(0.35),
                        blurRadius: 20,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '${DateFormat('MMMM').format(sm).toUpperCase()} INCOME',
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.7),
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 1.5,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              currencyFormat.format(totalIncome),
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 32,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '${filtered.length} transaction${filtered.length == 1 ? '' : 's'}',
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.7),
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        width: 56,
                        height: 56,
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.arrow_downward_rounded,
                          color: Colors.white,
                          size: 28,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // ─── Search Bar ───
            SliverToBoxAdapter(
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
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
                    onChanged: (v) => setState(() => _searchQuery = v),
                    decoration: InputDecoration(
                      hintText: 'Search income',
                      hintStyle: TextStyle(
                          color: textMain.withOpacity(0.3), fontSize: 14),
                      prefixIcon: Icon(Icons.search,
                          color: textMain.withOpacity(0.35), size: 20),
                      suffixIcon: _searchQuery.isNotEmpty
                          ? IconButton(
                              icon: Icon(Icons.clear,
                                  color: textMain.withOpacity(0.4), size: 18),
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

            const SliverToBoxAdapter(child: SizedBox(height: 4)),

            // ─── Grouped Income List ───
            if (filtered.isEmpty)
              SliverFillRemaining(
                hasScrollBody: false,
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.account_balance_wallet_outlined,
                          size: 56, color: textMain.withOpacity(0.15)),
                      const SizedBox(height: 12),
                      Text(
                        'No income found',
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
              ...grouped.entries.expand((entry) {
                return [
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
                  SliverPadding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    sliver: SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (context, index) {
                          final tx = entry.value[index];
                          final catIcon =
                              getCategoryIconByName(tx.category, customCats);
                          final timeStr =
                              DateFormat('hh:mm a').format(tx.date);

                          final isSelected = _selectedIds.contains(tx.id);

                          return Dismissible(
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
                            child: GestureDetector(
                              onLongPress: () => setState(() {
                                _selectedIds.add(tx.id);
                              }),
                              onTap: () {
                                if (_selectionActive) {
                                  setState(() {
                                    if (isSelected) {
                                      _selectedIds.remove(tx.id);
                                    } else {
                                      _selectedIds.add(tx.id);
                                    }
                                  });
                                }
                              },
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 220),
                                margin: const EdgeInsets.only(bottom: 10),
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 14, vertical: 14),
                                decoration: BoxDecoration(
                                  color: isSelected
                                      ? const Color(0xFFF0FFF4)
                                      : Colors.white,
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(
                                    color: isSelected
                                        ? const Color(0xFF27AE60)
                                        : Colors.transparent,
                                    width: 1.5,
                                  ),
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
                                    if (_selectionActive) ...[
                                      Padding(
                                        padding:
                                            const EdgeInsets.only(right: 10),
                                        child: Icon(
                                          isSelected
                                              ? Icons.check_circle_rounded
                                              : Icons
                                                  .radio_button_unchecked_rounded,
                                          color: isSelected
                                              ? const Color(0xFF27AE60)
                                              : textMain.withOpacity(0.35),
                                          size: 22,
                                        ),
                                      ),
                                    ],
                                    Container(
                                      width: 44,
                                      height: 44,
                                      decoration: BoxDecoration(
                                        color: primary.withOpacity(0.1),
                                        borderRadius:
                                            BorderRadius.circular(12),
                                      ),
                                      child: Icon(catIcon,
                                          color: primary, size: 20),
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
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    if (!_selectionActive)
                                      Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Text(
                                            '+${currencyFormat.format(tx.amount)}',
                                            style: const TextStyle(
                                              color: Color(0xFF27AE60),
                                              fontSize: 15,
                                              fontWeight: FontWeight.w700,
                                            ),
                                          ),
                                          const SizedBox(width: 4),
                                          IconButton(
                                            tooltip: 'Edit',
                                            onPressed: () {
                                              Navigator.push(
                                                context,
                                                MaterialPageRoute(
                                                  builder: (_) =>
                                                      EditTransactionScreen(
                                                          transaction: tx),
                                                ),
                                              );
                                            },
                                            icon: Icon(
                                              Icons.edit_outlined,
                                              size: 18,
                                              color:
                                                  textMain.withOpacity(0.4),
                                            ),
                                            visualDensity:
                                                VisualDensity.compact,
                                            constraints:
                                                const BoxConstraints(),
                                          ),
                                        ],
                                      )
                                    else
                                      Text(
                                        '+${currencyFormat.format(tx.amount)}',
                                        style: const TextStyle(
                                          color: Color(0xFF27AE60),
                                          fontSize: 15,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                  ],
                                ),
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

            const SliverToBoxAdapter(child: SizedBox(height: 32)),
          ],
        ),
      ),
    ),
  );
  }
}
