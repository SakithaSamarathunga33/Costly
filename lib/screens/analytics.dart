import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart';
import '../providers/transaction_provider.dart';
import '../utils/constants.dart';

class AnalyticsScreen extends StatelessWidget {
  const AnalyticsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    const Color primary = Color(0xFF00ADB5);
    const Color bgDark = Color(0xFF222831);
    const Color cardDark = Color(0xFF393E46);
    const Color textMain = Color(0xFFEEEEEE);

    final txProvider = Provider.of<TransactionProvider>(context);
    final currencyFormat =
        NumberFormat.currency(symbol: '\$', decimalDigits: 2);
    final categoryTotals = txProvider.expensesByCategory;
    final monthlyExp = txProvider.monthlyExpenses;
    final monthlyInc = txProvider.monthlyIncome;

    // Prepare pie chart data from category totals
    final pieEntries = categoryTotals.entries.toList();
    final totalExpenses = txProvider.totalExpenses;

    return Scaffold(
      backgroundColor: bgDark,
      appBar: AppBar(
        backgroundColor: bgDark,
        elevation: 0,
        title: const Text(
          'Analytics',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Summary cards
            Row(
              children: [
                _buildSummaryCard('Total Income',
                    currencyFormat.format(txProvider.totalIncome),
                    Colors.green, cardDark),
                const SizedBox(width: 12),
                _buildSummaryCard('Total Expenses',
                    currencyFormat.format(txProvider.totalExpenses),
                    Colors.red, cardDark),
              ],
            ),
            const SizedBox(height: 12),
            _buildSummaryCard('Current Balance',
                currencyFormat.format(txProvider.currentBalance),
                primary, cardDark,
                fullWidth: true),
            const SizedBox(height: 24),

            // Spending by Category - Pie Chart
            const Text(
              'Spending by Category',
              style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: cardDark,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.white.withOpacity(0.05)),
              ),
              child: pieEntries.isEmpty
                  ? SizedBox(
                      height: 200,
                      child: Center(
                        child: Text('No expense data yet',
                            style: TextStyle(
                                color: textMain.withOpacity(0.5))),
                      ),
                    )
                  : Column(
                      children: [
                        SizedBox(
                          height: 200,
                          child: PieChart(
                            PieChartData(
                              sections: pieEntries.map((entry) {
                                final color =
                                    getCategoryColor(entry.key);
                                final percent = totalExpenses > 0
                                    ? (entry.value / totalExpenses * 100)
                                    : 0.0;
                                return PieChartSectionData(
                                  value: entry.value,
                                  color: color,
                                  title:
                                      '${percent.toStringAsFixed(0)}%',
                                  titleStyle: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold),
                                  radius: 60,
                                );
                              }).toList(),
                              centerSpaceRadius: 40,
                              sectionsSpace: 2,
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        // Legend
                        ...pieEntries.map((entry) {
                          final color = getCategoryColor(entry.key);
                          return Padding(
                            padding:
                                const EdgeInsets.symmetric(vertical: 4),
                            child: Row(
                              children: [
                                Container(
                                    width: 12,
                                    height: 12,
                                    decoration: BoxDecoration(
                                        color: color,
                                        borderRadius:
                                            BorderRadius.circular(3))),
                                const SizedBox(width: 8),
                                Expanded(
                                    child: Text(entry.key,
                                        style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 13))),
                                Text(
                                    currencyFormat.format(entry.value),
                                    style: TextStyle(
                                        color:
                                            textMain.withOpacity(0.7),
                                        fontSize: 13,
                                        fontWeight: FontWeight.bold)),
                              ],
                            ),
                          );
                        }),
                      ],
                    ),
            ),
            const SizedBox(height: 24),

            // Monthly Expenses Bar Chart
            const Text(
              'Monthly Overview',
              style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: cardDark,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.white.withOpacity(0.05)),
              ),
              child: Column(
                children: [
                  // Legend for bar chart
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _chartLegend('Income', Colors.green),
                      const SizedBox(width: 24),
                      _chartLegend('Expenses', Colors.red),
                    ],
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    height: 200,
                    child: BarChart(
                      BarChartData(
                        alignment: BarChartAlignment.spaceAround,
                        maxY: _getMaxY(monthlyExp, monthlyInc),
                        barTouchData: BarTouchData(enabled: true),
                        titlesData: FlTitlesData(
                          show: true,
                          bottomTitles: AxisTitles(
                            sideTitles: SideTitles(
                              showTitles: true,
                              getTitlesWidget: (value, meta) {
                                const months = [
                                  'J', 'F', 'M', 'A', 'M', 'J',
                                  'J', 'A', 'S', 'O', 'N', 'D'
                                ];
                                final idx = value.toInt();
                                if (idx >= 0 && idx < 12) {
                                  return Padding(
                                    padding: const EdgeInsets.only(top: 4),
                                    child: Text(months[idx],
                                        style: TextStyle(
                                            color:
                                                textMain.withOpacity(0.5),
                                            fontSize: 10)),
                                  );
                                }
                                return const Text('');
                              },
                            ),
                          ),
                          leftTitles: const AxisTitles(
                              sideTitles:
                                  SideTitles(showTitles: false)),
                          topTitles: const AxisTitles(
                              sideTitles:
                                  SideTitles(showTitles: false)),
                          rightTitles: const AxisTitles(
                              sideTitles:
                                  SideTitles(showTitles: false)),
                        ),
                        gridData: const FlGridData(show: false),
                        borderData: FlBorderData(show: false),
                        barGroups: List.generate(12, (index) {
                          final month = index + 1;
                          return BarChartGroupData(
                            x: index,
                            barRods: [
                              BarChartRodData(
                                toY: monthlyInc[month] ?? 0,
                                color: Colors.green,
                                width: 6,
                                borderRadius: BorderRadius.circular(3),
                              ),
                              BarChartRodData(
                                toY: monthlyExp[month] ?? 0,
                                color: Colors.red,
                                width: 6,
                                borderRadius: BorderRadius.circular(3),
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
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  /// Get max Y value for bar chart scaling
  double _getMaxY(Map<int, double> expenses, Map<int, double> income) {
    double max = 100;
    for (var v in expenses.values) {
      if (v > max) max = v;
    }
    for (var v in income.values) {
      if (v > max) max = v;
    }
    return max * 1.2; // 20% padding
  }

  Widget _buildSummaryCard(
      String title, String amount, Color color, Color cardDark,
      {bool fullWidth = false}) {
    return fullWidth
        ? Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: cardDark,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: color.withOpacity(0.3)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: TextStyle(
                        color: Colors.white.withOpacity(0.6),
                        fontSize: 12,
                        fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                Text(amount,
                    style: TextStyle(
                        color: color,
                        fontSize: 24,
                        fontWeight: FontWeight.bold)),
              ],
            ),
          )
        : Expanded(
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: cardDark,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: color.withOpacity(0.3)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: TextStyle(
                          color: Colors.white.withOpacity(0.6),
                          fontSize: 12,
                          fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  Text(amount,
                      style: TextStyle(
                          color: color,
                          fontSize: 20,
                          fontWeight: FontWeight.bold)),
                ],
              ),
            ),
          );
  }

  Widget _chartLegend(String label, Color color) {
    return Row(
      children: [
        Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(
                color: color, borderRadius: BorderRadius.circular(2))),
        const SizedBox(width: 6),
        Text(label,
            style: const TextStyle(color: Colors.white70, fontSize: 12)),
      ],
    );
  }
}
