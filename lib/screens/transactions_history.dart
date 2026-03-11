import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/transaction_provider.dart';
import '../models/transaction_model.dart';
import '../utils/constants.dart';

class TransactionsHistoryScreen extends StatefulWidget {
  const TransactionsHistoryScreen({super.key});

  @override
  State<TransactionsHistoryScreen> createState() =>
      _TransactionsHistoryScreenState();
}

class _TransactionsHistoryScreenState extends State<TransactionsHistoryScreen> {
  // Filter: 0 = All, 1 = Expenses, 2 = Income
  int _filterIndex = 0;
  String _searchQuery = '';
  final _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  /// Filter and search transactions based on current filter and search query
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

    // Apply search filter
    if (_searchQuery.isNotEmpty) {
      filtered = filtered.where((tx) {
        return tx.title.toLowerCase().contains(_searchQuery.toLowerCase()) ||
            tx.category.toLowerCase().contains(_searchQuery.toLowerCase()) ||
            tx.notes.toLowerCase().contains(_searchQuery.toLowerCase());
      }).toList();
    }

    // Sort by newest first
    filtered = List.from(filtered);
    filtered.sort((a, b) => b.date.compareTo(a.date));
    return filtered;
  }

  @override
  Widget build(BuildContext context) {
    const Color primary = Color(0xFF00ADB5);
    const Color bgDark = Color(0xFF222831);
    const Color cardDark = Color(0xFF393E46);
    const Color textMain = Color(0xFFEEEEEE);

    final txProvider = Provider.of<TransactionProvider>(context);
    final filteredTx = _getFilteredTransactions(txProvider);
    final currencyFormat =
        NumberFormat.currency(symbol: '\$', decimalDigits: 2);

    return Scaffold(
      backgroundColor: bgDark,
      appBar: AppBar(
        backgroundColor: bgDark,
        elevation: 0,
        title: const Text(
          'Transactions History',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Column(
        children: [
          // Search bar
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
            child: TextField(
              controller: _searchController,
              style: const TextStyle(color: textMain),
              onChanged: (value) => setState(() => _searchQuery = value),
              decoration: InputDecoration(
                hintText: 'Search transactions...',
                hintStyle: TextStyle(color: textMain.withOpacity(0.3)),
                filled: true,
                fillColor: cardDark,
                prefixIcon:
                    Icon(Icons.search, color: textMain.withOpacity(0.4)),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: Icon(Icons.clear,
                            color: textMain.withOpacity(0.4)),
                        onPressed: () {
                          _searchController.clear();
                          setState(() => _searchQuery = '');
                        },
                      )
                    : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(vertical: 16),
              ),
            ),
          ),

          // Filter tabs (All, Expenses, Income)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
            child: Row(
              children: [
                _buildFilterChip('All', 0, primary, cardDark, textMain),
                const SizedBox(width: 8),
                _buildFilterChip('Expenses', 1, primary, cardDark, textMain),
                const SizedBox(width: 8),
                _buildFilterChip('Income', 2, primary, cardDark, textMain),
              ],
            ),
          ),

          // Transaction list
          Expanded(
            child: filteredTx.isEmpty
                ? Center(
                    child: Text(
                      'No transactions found',
                      style: TextStyle(
                          color: textMain.withOpacity(0.5), fontSize: 16),
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    itemCount: filteredTx.length,
                    itemBuilder: (context, index) {
                      final tx = filteredTx[index];
                      final isIncome = tx.type == 'income';
                      final catColor = getCategoryColor(tx.category);
                      final catIcon = getCategoryIconByName(tx.category);
                      final dateStr =
                          DateFormat('MMM dd, yyyy').format(tx.date);

                      return Dismissible(
                        key: Key(tx.id),
                        direction: DismissDirection.endToStart,
                        background: Container(
                          margin: const EdgeInsets.only(bottom: 12),
                          decoration: BoxDecoration(
                            color: Colors.red,
                            borderRadius: BorderRadius.circular(16),
                          ),
                          alignment: Alignment.centerRight,
                          padding: const EdgeInsets.only(right: 24),
                          child:
                              const Icon(Icons.delete, color: Colors.white),
                        ),
                        onDismissed: (_) {
                          txProvider.deleteTransaction(tx.id);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                                content: Text('${tx.title} deleted')),
                          );
                        },
                        child: Container(
                          margin: const EdgeInsets.only(bottom: 12),
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: cardDark.withOpacity(0.5),
                            border: Border.all(
                                color: Colors.white.withOpacity(0.05)),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 40,
                                height: 40,
                                decoration: BoxDecoration(
                                  color:
                                      (isIncome ? primary : catColor)
                                          .withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Icon(catIcon,
                                    color:
                                        isIncome ? primary : catColor,
                                    size: 20),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                  children: [
                                    Text(tx.title,
                                        style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 14,
                                            fontWeight: FontWeight.bold)),
                                    const SizedBox(height: 2),
                                    Text('${tx.category} • $dateStr',
                                        style: TextStyle(
                                            color: Colors.white
                                                .withOpacity(0.5),
                                            fontSize: 12)),
                                  ],
                                ),
                              ),
                              Text(
                                '${isIncome ? '+' : '-'}${currencyFormat.format(tx.amount)}',
                                style: TextStyle(
                                  color: isIncome
                                      ? Colors.green
                                      : Colors.red,
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label, int index, Color primary,
      Color cardDark, Color textMain) {
    final isActive = _filterIndex == index;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _filterIndex = index),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: isActive ? primary : cardDark,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Center(
            child: Text(
              label,
              style: TextStyle(
                color: isActive ? Colors.white : textMain.withOpacity(0.6),
                fontSize: 13,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
