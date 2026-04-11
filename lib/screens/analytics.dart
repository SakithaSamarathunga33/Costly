import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart';
import '../providers/auth_provider.dart';
import '../providers/transaction_provider.dart';
import '../providers/category_provider.dart';
import '../providers/budget_provider.dart';
import '../utils/constants.dart';
import '../widgets/floating_nav_bar.dart';
import '../widgets/app_animations.dart';
import '../widgets/root_back_handler.dart';

class AnalyticsScreen extends StatelessWidget {
  const AnalyticsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    const Color primary = Color(0xFF5D3891);
    const Color bg = Color(0xFFF8F6FC);
    const Color textMain = Color(0xFF2D2D2D);

    final txProvider = Provider.of<TransactionProvider>(context);
    final authProvider = Provider.of<AuthProvider>(context);
    final customCats = Provider.of<CategoryProvider>(context).customCategories;
    final budgetProvider = Provider.of<BudgetProvider>(context);
    final currencySymbol = authProvider.currencySymbol;
    final currencyFormat =
        NumberFormat.currency(symbol: '$currencySymbol ', decimalDigits: 2);
    final categoryTotals = txProvider.expensesByCategory;
    final rollingTotals = txProvider.rollingSixMonthExpenseTotals;
    final rollingLabels = txProvider.rollingSixMonthLabels;
    final totalExpenses = txProvider.totalExpenses;

    // Category entries sorted by value
    final pieEntries = categoryTotals.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    // Budget percentage (assume a simple budget = total income)
    final totalIncome = txProvider.totalIncome;
    final budgetPercent =
        totalIncome > 0 ? (totalExpenses / totalIncome * 100).clamp(0, 100) : 0;

    // Format total for donut center
    String _formatCompact(double value) {
      if (value >= 1000) {
        return '$currencySymbol ${(value / 1000).toStringAsFixed(1)}k';
      }
      return '$currencySymbol ${value.toStringAsFixed(0)}';
    }

    // Category colors for pie chart
    final List<Color> catColors = [
      const Color(0xFF5D3891),
      const Color(0xFFFF6B6B),
      const Color(0xFF51CF66),
      const Color(0xFF339AF0),
      const Color(0xFFFCC419),
      const Color(0xFFFF922B),
      const Color(0xFFCC5DE8),
      const Color(0xFF20C997),
      const Color(0xFFE64980),
      const Color(0xFF22B8CF),
    ];

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
              'Analytics',
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
        fit: StackFit.expand,
        children: [
          ScreenEntrance(
            child: SingleChildScrollView(
              padding: const EdgeInsets.only(
                  left: 20, right: 20, top: 8, bottom: 120),
              child: StaggeredColumn(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ─── Total Spending Card ───
                Container(
                  width: double.infinity,
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
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Total Spending',
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.7),
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          // Percentage badge
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.15),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              '+${budgetPercent.toStringAsFixed(0)}%',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        currencyFormat.format(totalExpenses),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 32,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 16),
                      // Progress bar
                      ClipRRect(
                        borderRadius: BorderRadius.circular(6),
                        child: LinearProgressIndicator(
                          value: (budgetPercent / 100).toDouble(),
                          minHeight: 8,
                          backgroundColor: Colors.white.withOpacity(0.15),
                          valueColor:
                              const AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Align(
                        alignment: Alignment.centerRight,
                        child: Text(
                          '${budgetPercent.toStringAsFixed(0)}% of budget',
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.6),
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 28),

                // ─── Monthly Trends ───
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.04),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Monthly Trends',
                            style: TextStyle(
                              color: textMain,
                              fontSize: 17,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: bg,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Row(
                              children: [
                                Text(
                                  '6 mo to selected',
                                  style: TextStyle(
                                    color: textMain.withOpacity(0.5),
                                    fontSize: 12,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                const SizedBox(width: 4),
                                Icon(Icons.keyboard_arrow_down,
                                    color: textMain.withOpacity(0.4), size: 18),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 22),
                      SizedBox(
                        height: 160,
                        child: BarChart(
                          BarChartData(
                            alignment: BarChartAlignment.spaceAround,
                            maxY: _getMaxY(rollingTotals),
                            barTouchData: BarTouchData(
                              enabled: true,
                              touchTooltipData: BarTouchTooltipData(
                                tooltipRoundedRadius: 8,
                                getTooltipItem:
                                    (group, groupIndex, rod, rodIndex) {
                                  return BarTooltipItem(
                                    currencyFormat.format(rod.toY),
                                    const TextStyle(
                                      color: Colors.white,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  );
                                },
                              ),
                            ),
                            titlesData: FlTitlesData(
                              show: true,
                              bottomTitles: AxisTitles(
                                sideTitles: SideTitles(
                                  showTitles: true,
                                  getTitlesWidget: (value, meta) {
                                    final idx = value.toInt();
                                    if (idx >= 0 &&
                                        idx < rollingLabels.length) {
                                      final isSelectedMonth = idx == 5;
                                      return Padding(
                                        padding: const EdgeInsets.only(top: 8),
                                        child: Text(
                                          rollingLabels[idx],
                                          style: TextStyle(
                                            color: isSelectedMonth
                                                ? primary
                                                : textMain.withOpacity(0.35),
                                            fontSize: 11,
                                            fontWeight: isSelectedMonth
                                                ? FontWeight.w700
                                                : FontWeight.w500,
                                          ),
                                        ),
                                      );
                                    }
                                    return const Text('');
                                  },
                                ),
                              ),
                              leftTitles: const AxisTitles(
                                  sideTitles: SideTitles(showTitles: false)),
                              topTitles: const AxisTitles(
                                  sideTitles: SideTitles(showTitles: false)),
                              rightTitles: const AxisTitles(
                                  sideTitles: SideTitles(showTitles: false)),
                            ),
                            gridData: const FlGridData(show: false),
                            borderData: FlBorderData(show: false),
                            barGroups: List.generate(6, (index) {
                              final isSelectedMonth = index == 5;
                              return BarChartGroupData(
                                x: index,
                                barRods: [
                                  BarChartRodData(
                                    toY: rollingTotals[index],
                                    gradient: isSelectedMonth
                                        ? const LinearGradient(
                                            colors: [
                                              Color(0xFF5D3891),
                                              Color(0xFF7B52AB),
                                            ],
                                            begin: Alignment.bottomCenter,
                                            end: Alignment.topCenter,
                                          )
                                        : null,
                                    color: isSelectedMonth
                                        ? null
                                        : primary.withOpacity(0.15),
                                    width: 14,
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                ],
                              );
                            }),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 28),

                // ─── Category Breakdown ───
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.04),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Category Breakdown',
                        style: TextStyle(
                          color: textMain,
                          fontSize: 17,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 20),
                      pieEntries.isEmpty
                          ? SizedBox(
                              height: 160,
                              child: Center(
                                child: Text('No expense data yet',
                                    style: TextStyle(
                                        color: textMain.withOpacity(0.4))),
                              ),
                            )
                          : Row(
                              children: [
                                // Donut chart
                                Expanded(
                                  flex: 5,
                                  child: SizedBox(
                                    height: 140,
                                    child: Stack(
                                      alignment: Alignment.center,
                                      children: [
                                        PieChart(
                                          PieChartData(
                                            sections: pieEntries
                                                .asMap()
                                                .entries
                                                .map((e) {
                                              final idx = e.key;
                                              final entry = e.value;
                                              final color = idx <
                                                      catColors.length
                                                  ? catColors[idx]
                                                  : getCategoryColor(
                                                      entry.key, customCats);
                                              return PieChartSectionData(
                                                value: entry.value,
                                                color: color,
                                                title: '',
                                                radius: 18,
                                              );
                                            }).toList(),
                                            centerSpaceRadius: 42,
                                            sectionsSpace: 3,
                                          ),
                                        ),
                                        // Center label
                                        Column(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Text(
                                              _formatCompact(totalExpenses),
                                              style: const TextStyle(
                                                color: textMain,
                                                fontSize: 18,
                                                fontWeight: FontWeight.w800,
                                              ),
                                            ),
                                            Text(
                                              'TOTAL',
                                              style: TextStyle(
                                                color:
                                                    textMain.withOpacity(0.35),
                                                fontSize: 10,
                                                fontWeight: FontWeight.w600,
                                                letterSpacing: 1,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                                // Legend
                                Expanded(
                                  flex: 4,
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: pieEntries
                                        .asMap()
                                        .entries
                                        .take(5)
                                        .map((e) {
                                      final idx = e.key;
                                      final entry = e.value;
                                      final color = idx < catColors.length
                                          ? catColors[idx]
                                          : getCategoryColor(
                                              entry.key, customCats);
                                      final percent = totalExpenses > 0
                                          ? (entry.value / totalExpenses * 100)
                                              .toStringAsFixed(0)
                                          : '0';
                                      return Padding(
                                        padding: const EdgeInsets.symmetric(
                                            vertical: 5),
                                        child: Row(
                                          children: [
                                            Container(
                                              width: 10,
                                              height: 10,
                                              decoration: BoxDecoration(
                                                color: color,
                                                shape: BoxShape.circle,
                                              ),
                                            ),
                                            const SizedBox(width: 8),
                                            Expanded(
                                              child: Text(
                                                entry.key,
                                                style: TextStyle(
                                                  color:
                                                      textMain.withOpacity(0.6),
                                                  fontSize: 13,
                                                  fontWeight: FontWeight.w500,
                                                ),
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ),
                                            Text(
                                              '$percent%',
                                              style: const TextStyle(
                                                color: textMain,
                                                fontSize: 13,
                                                fontWeight: FontWeight.w700,
                                              ),
                                            ),
                                          ],
                                        ),
                                      );
                                    }).toList(),
                                  ),
                                ),
                              ],
                            ),
                    ],
                  ),
                ),
                const SizedBox(height: 28),

                // ─── Top Categories List ───
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Top Categories',
                          style: TextStyle(
                            color: textMain,
                            fontSize: 17,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        Text(
                          'View All',
                          style: TextStyle(
                            color: primary,
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    ...pieEntries.take(5).map((entry) {
                      final catColor = getCategoryColor(entry.key, customCats);
                      final catIcon =
                          getCategoryIconByName(entry.key, customCats);
                      final txCount = txProvider.transactions
                          .where((tx) =>
                              tx.category == entry.key && tx.type == 'expense')
                          .length;

                      return Container(
                        margin: const EdgeInsets.only(bottom: 10),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 14),
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
                            Container(
                              width: 44,
                              height: 44,
                              decoration: BoxDecoration(
                                color: catColor.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Icon(catIcon, color: catColor, size: 22),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    entry.key,
                                    style: const TextStyle(
                                      color: textMain,
                                      fontSize: 15,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  const SizedBox(height: 3),
                                  Text(
                                    '$txCount Transaction${txCount != 1 ? 's' : ''}',
                                    style: TextStyle(
                                      color: textMain.withOpacity(0.4),
                                      fontSize: 12,
                                      fontWeight: FontWeight.w400,
                                    ),
                                  ),
                                  Builder(builder: (_) {
                                    final limit = budgetProvider.categoryLimit(entry.key);
                                    if (limit <= 0) return const SizedBox.shrink();
                                    final pct = budgetProvider.categoryUsedPercent(entry.key, entry.value);
                                    final barColor = pct >= 90
                                        ? const Color(0xFFE74C3C)
                                        : pct >= 70
                                            ? const Color(0xFFF39C12)
                                            : catColor;
                                    return Padding(
                                      padding: const EdgeInsets.only(top: 6),
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          ClipRRect(
                                            borderRadius: BorderRadius.circular(4),
                                            child: LinearProgressIndicator(
                                              value: pct / 100,
                                              backgroundColor: barColor.withValues(alpha: 0.15),
                                              valueColor: AlwaysStoppedAnimation<Color>(barColor),
                                              minHeight: 5,
                                            ),
                                          ),
                                          const SizedBox(height: 2),
                                          Text(
                                            '${pct.toStringAsFixed(0)}% of limit',
                                            style: TextStyle(
                                              color: barColor,
                                              fontSize: 10,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                        ],
                                      ),
                                    );
                                  }),
                                ],
                              ),
                            ),
                            Text(
                              currencyFormat.format(entry.value),
                              style: const TextStyle(
                                color: textMain,
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      );
                    }),
                    const SizedBox(height: 20),
                  ],
                ),
              ],
            ),
            ),
          ),
          const FloatingNavBar(currentIndex: 2),
        ],
      ),
      ),
    );
  }

  double _getMaxY(List<double> values) {
    double max = 100;
    for (final v in values) {
      if (v > max) max = v;
    }
    return max * 1.3;
  }
}
