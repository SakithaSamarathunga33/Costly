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
import '../widgets/root_back_handler.dart';

class AnalyticsScreen extends StatefulWidget {
  const AnalyticsScreen({super.key});

  @override
  State<AnalyticsScreen> createState() => _AnalyticsScreenState();
}

class _AnalyticsScreenState extends State<AnalyticsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _pickDateRange(
      BuildContext context, TransactionProvider txProvider) async {
    final initial = txProvider.customDateRange ??
        DateTimeRange(
          start: txProvider.selectedMonth,
          end: DateTime(txProvider.selectedMonth.year,
              txProvider.selectedMonth.month + 1, 0),
        );
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      initialDateRange: initial,
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: const ColorScheme.light(primary: Color(0xFF5D3891)),
        ),
        child: child!,
      ),
    );
    if (picked != null) {
      txProvider.setCustomDateRange(picked);
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    const Color primary = Color(0xFF5D3891);
    final txProvider = Provider.of<TransactionProvider>(context);
    final authProvider = Provider.of<AuthProvider>(context);
    final customCats =
        Provider.of<CategoryProvider>(context).customCategories;
    final budgetProvider = Provider.of<BudgetProvider>(context);
    final currencySymbol = authProvider.currencySymbol;
    final fmt = NumberFormat.currency(
        symbol: '$currencySymbol ', decimalDigits: 2);

    final hasRange = txProvider.hasCustomRange;
    final rangeLabel = hasRange
        ? '${DateFormat('MMM d').format(txProvider.customDateRange!.start)} – '
            '${DateFormat('MMM d').format(txProvider.customDateRange!.end)}'
        : DateFormat('MMMM yyyy').format(txProvider.selectedMonth);

    return RootBackHandler(
      child: Scaffold(
        backgroundColor: cs.surface,
        appBar: AppBar(
          backgroundColor: cs.surface,
          elevation: 0,
          surfaceTintColor: Colors.transparent,
          automaticallyImplyLeading: false,
          centerTitle: true,
          title: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Analytics',
                  style: TextStyle(
                      color: cs.onSurface,
                      fontSize: 18,
                      fontWeight: FontWeight.w700)),
              GestureDetector(
                onTap: () => _pickDateRange(context, txProvider),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(rangeLabel,
                        style: TextStyle(
                            color: hasRange ? primary : cs.onSurfaceVariant,
                            fontSize: 12,
                            fontWeight: FontWeight.w600)),
                    const SizedBox(width: 4),
                    Icon(Icons.arrow_drop_down,
                        size: 16,
                        color: hasRange
                            ? primary
                            : cs.onSurfaceVariant),
                  ],
                ),
              ),
            ],
          ),
          actions: [
            if (hasRange)
              IconButton(
                icon: const Icon(Icons.close_rounded, size: 20, color: primary),
                onPressed: () => txProvider.clearCustomDateRange(),
                tooltip: 'Clear date range',
              )
            else
              IconButton(
                icon: Icon(Icons.calendar_today_outlined,
                    color: cs.onSurface, size: 20),
                onPressed: () => _pickDateRange(context, txProvider),
              ),
          ],
          bottom: TabBar(
            controller: _tabController,
            labelColor: primary,
            unselectedLabelColor: cs.onSurface.withValues(alpha: 0.4),
            indicatorColor: primary,
            indicatorSize: TabBarIndicatorSize.label,
            labelStyle: const TextStyle(
                fontSize: 13, fontWeight: FontWeight.w700),
            tabs: const [
              Tab(text: 'Expenses'),
              Tab(text: 'Income'),
              Tab(text: 'Trends'),
            ],
          ),
        ),
        body: Stack(
          fit: StackFit.expand,
          children: [
            TabBarView(
              controller: _tabController,
              children: [
                _ExpensesTab(
                    txProvider: txProvider,
                    budgetProvider: budgetProvider,
                    customCats: customCats,
                    fmt: fmt,
                    currencySymbol: currencySymbol),
                _IncomeTab(
                    txProvider: txProvider,
                    customCats: customCats,
                    fmt: fmt,
                    currencySymbol: currencySymbol),
                _TrendsTab(
                    txProvider: txProvider,
                    customCats: customCats,
                    fmt: fmt),
              ],
            ),
            const FloatingNavBar(currentIndex: 2),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────── EXPENSES TAB ────────────────────────────────────

class _ExpensesTab extends StatelessWidget {
  final TransactionProvider txProvider;
  final BudgetProvider budgetProvider;
  final List<Map<String, dynamic>> customCats;
  final NumberFormat fmt;
  final String currencySymbol;

  const _ExpensesTab({
    required this.txProvider,
    required this.budgetProvider,
    required this.customCats,
    required this.fmt,
    required this.currencySymbol,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    const primary = Color(0xFF5D3891);

    final totalExpenses = txProvider.filteredTotalExpenses;
    final totalIncome = txProvider.filteredTotalIncome;
    final categoryTotals = txProvider.filteredExpensesByCategory;
    final rollingTotals = txProvider.rollingSixMonthExpenseTotals;
    final rollingLabels = txProvider.rollingSixMonthLabels;
    final budgetPercent =
        totalIncome > 0 ? (totalExpenses / totalIncome * 100).clamp(0, 100) : 0;

    final pieEntries = categoryTotals.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    final List<Color> catColors = _catColorList();

    String formatCompact(double v) => v >= 1000
        ? '$currencySymbol ${(v / 1000).toStringAsFixed(1)}k'
        : '$currencySymbol ${v.toStringAsFixed(0)}';

    return SingleChildScrollView(
      padding: const EdgeInsets.only(left: 20, right: 20, top: 16, bottom: 120),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        // Summary card
        _summaryCard(
          label: 'Total Expenses',
          amount: fmt.format(totalExpenses),
          badgeLabel: '+${budgetPercent.toStringAsFixed(0)}% of income',
          progressValue: (budgetPercent / 100).toDouble(),
        ),
        const SizedBox(height: 24),

        // Monthly bar chart
        _chartCard(context, 
          title: '6-Month Trend',
          child: SizedBox(
            height: 160,
            child: BarChart(_buildBarData(
                rollingTotals, rollingLabels, fmt, primary, cs.onSurface)),
          ),
        ),
        const SizedBox(height: 24),

        // Category breakdown
        _chartCard(context, 
          title: 'Category Breakdown',
          child: pieEntries.isEmpty
              ? SizedBox(
                  height: 120,
                  child: Center(
                      child: Text('No expense data',
                          style: TextStyle(
                              color: cs.onSurface.withValues(alpha: 0.4)))))
              : _DonutWithLegend(
                  entries: pieEntries,
                  total: totalExpenses,
                  catColors: catColors,
                  customCats: customCats,
                  formatCompact: formatCompact,
                  textMain: cs.onSurface),
        ),
        const SizedBox(height: 24),

        // Top categories list
        Text('Top Categories',
            style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w700,
                color: cs.onSurface)),
        const SizedBox(height: 14),
        ...pieEntries.take(5).map((entry) => _CategoryRow(
              entry: entry,
              total: totalExpenses,
              txCount: txProvider.filteredTransactions
                  .where((t) =>
                      t.category == entry.key && t.type == 'expense')
                  .length,
              customCats: customCats,
              fmt: fmt,
              budgetProvider: budgetProvider,
              bg: Theme.of(context).colorScheme.surfaceContainerLow,
            )),
        const SizedBox(height: 20),
      ]),
    );
  }
}

// ─────────────────────────── INCOME TAB ──────────────────────────────────────

class _IncomeTab extends StatelessWidget {
  final TransactionProvider txProvider;
  final List<Map<String, dynamic>> customCats;
  final NumberFormat fmt;
  final String currencySymbol;

  const _IncomeTab({
    required this.txProvider,
    required this.customCats,
    required this.fmt,
    required this.currencySymbol,
  });

  @override
  Widget build(BuildContext context) {
    const primary = Color(0xFF5D3891);
    final textMain = Theme.of(context).colorScheme.onSurface;

    final totalIncome = txProvider.filteredTotalIncome;
    final totalExpenses = txProvider.filteredTotalExpenses;
    final categoryTotals = txProvider.filteredIncomeByCategory;
    final rollingTotals = txProvider.rollingSixMonthIncomeTotals;
    final rollingLabels = txProvider.rollingSixMonthLabels;
    final savingsRate = totalIncome > 0
        ? ((totalIncome - totalExpenses) / totalIncome * 100).clamp(0, 100)
        : 0;

    final pieEntries = categoryTotals.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    final List<Color> catColors = _catColorList();

    String formatCompact(double v) => v >= 1000
        ? '$currencySymbol ${(v / 1000).toStringAsFixed(1)}k'
        : '$currencySymbol ${v.toStringAsFixed(0)}';

    return SingleChildScrollView(
      padding: const EdgeInsets.only(left: 20, right: 20, top: 16, bottom: 120),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        // Summary card
        _summaryCard(
          label: 'Total Income',
          amount: fmt.format(totalIncome),
          badgeLabel: '${savingsRate.toStringAsFixed(0)}% saved',
          progressValue: (savingsRate / 100).toDouble(),
          color: const Color(0xFF2ECC71),
        ),
        const SizedBox(height: 24),

        // Monthly bar chart
        _chartCard(context, 
          title: '6-Month Income Trend',
          child: SizedBox(
            height: 160,
            child: BarChart(_buildBarData(
                rollingTotals, rollingLabels, fmt,
                const Color(0xFF2ECC71), textMain,
                barColor: const Color(0xFF2ECC71))),
          ),
        ),
        const SizedBox(height: 24),

        // Income vs Expenses comparison
        _chartCard(context, 
          title: 'Income vs Expenses',
          child: Column(children: [
            _comparisonRow('Income', totalIncome,
                totalIncome > 0 ? totalIncome : 1, const Color(0xFF2ECC71), fmt),
            const SizedBox(height: 10),
            _comparisonRow('Expenses', totalExpenses,
                totalIncome > 0 ? totalIncome : 1, const Color(0xFFE74C3C), fmt),
            const SizedBox(height: 10),
            _comparisonRow(
                'Net',
                totalIncome - totalExpenses,
                totalIncome > 0 ? totalIncome : 1,
                primary,
                fmt),
          ]),
        ),
        const SizedBox(height: 24),

        if (pieEntries.isNotEmpty) ...[
          // Income category breakdown
          _chartCard(context, 
            title: 'Income Sources',
            child: _DonutWithLegend(
              entries: pieEntries,
              total: totalIncome,
              catColors: catColors,
              customCats: customCats,
              formatCompact: formatCompact,
              textMain: textMain,
            ),
          ),
          const SizedBox(height: 24),
        ],

        Text('Income by Source',
            style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w700,
                color: textMain)),
        const SizedBox(height: 14),
        ...pieEntries.map((entry) => _CategoryRow(
              entry: entry,
              total: totalIncome,
              txCount: txProvider.filteredTransactions
                  .where((t) =>
                      t.category == entry.key && t.type == 'income')
                  .length,
              customCats: customCats,
              fmt: fmt,
              budgetProvider: null,
              bg: Theme.of(context).colorScheme.surfaceContainerLow,
            )),
        const SizedBox(height: 20),
      ]),
    );
  }

  Widget _comparisonRow(
      String label, double value, double max, Color color, NumberFormat fmt) {
    final pct = max > 0 ? (value.abs() / max).clamp(0.0, 1.0) : 0.0;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label,
                style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF2D2D2D).withValues(alpha: 0.7))),
            Text(fmt.format(value),
                style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: color)),
          ],
        ),
        const SizedBox(height: 4),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: pct,
            backgroundColor: color.withValues(alpha: 0.12),
            valueColor: AlwaysStoppedAnimation<Color>(color),
            minHeight: 6,
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────── TRENDS TAB ──────────────────────────────────────

class _TrendsTab extends StatelessWidget {
  final TransactionProvider txProvider;
  final List<Map<String, dynamic>> customCats;
  final NumberFormat fmt;

  const _TrendsTab({
    required this.txProvider,
    required this.customCats,
    required this.fmt,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final textMain = cs.onSurface;
    final rollingLabels = txProvider.rollingSixMonthLabels;
    final trends = txProvider.categoryTrends;

    if (trends.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.bar_chart_outlined,
                size: 56,
                color: const Color(0xFF5D3891).withValues(alpha: 0.3)),
            const SizedBox(height: 16),
            Text('No spending data yet',
                style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: textMain)),
          ],
        ),
      );
    }

    return ListView(
      padding:
          const EdgeInsets.only(left: 20, right: 20, top: 16, bottom: 120),
      children: [
        Text('Category Spending Trends',
            style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w700,
                color: textMain)),
        const SizedBox(height: 6),
        Text('6-month history per category',
            style: TextStyle(
                fontSize: 12, color: textMain.withValues(alpha: 0.45))),
        const SizedBox(height: 16),
        ...trends.entries.map((e) {
          final catColor = getCategoryColor(e.key, customCats);
          final maxVal = e.value.reduce((a, b) => a > b ? a : b);
          return Container(
            margin: const EdgeInsets.only(bottom: 16),
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: cs.surfaceContainerLow,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                    color: Colors.black.withValues(alpha: 0.04),
                    blurRadius: 8,
                    offset: const Offset(0, 2)),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: catColor.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(getCategoryIconByName(e.key, customCats),
                          color: catColor, size: 18),
                    ),
                    const SizedBox(width: 10),
                    Text(e.key,
                        style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: textMain)),
                  ],
                ),
                const SizedBox(height: 14),
                SizedBox(
                  height: 80,
                  child: BarChart(
                    BarChartData(
                      alignment: BarChartAlignment.spaceAround,
                      maxY: maxVal > 0 ? maxVal * 1.3 : 100,
                      barTouchData: BarTouchData(
                        enabled: true,
                        touchTooltipData: BarTouchTooltipData(
                          tooltipRoundedRadius: 6,
                          getTooltipItem: (group, gi, rod, ri) =>
                              BarTooltipItem(
                            fmt.format(rod.toY),
                            const TextStyle(
                                color: Colors.white,
                                fontSize: 11,
                                fontWeight: FontWeight.w600),
                          ),
                        ),
                      ),
                      titlesData: FlTitlesData(
                        bottomTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            getTitlesWidget: (v, _) {
                              final idx = v.toInt();
                              return Padding(
                                padding: const EdgeInsets.only(top: 4),
                                child: Text(
                                  idx >= 0 && idx < rollingLabels.length
                                      ? rollingLabels[idx]
                                      : '',
                                  style: TextStyle(
                                      fontSize: 9,
                                      color:
                                          textMain.withValues(alpha: 0.4)),
                                ),
                              );
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
                      barGroups: List.generate(6, (i) {
                        final isLast = i == 5;
                        return BarChartGroupData(
                          x: i,
                          barRods: [
                            BarChartRodData(
                              toY: e.value[i],
                              color: isLast
                                  ? catColor
                                  : catColor.withValues(alpha: 0.25),
                              width: 12,
                              borderRadius: BorderRadius.circular(4),
                            ),
                          ],
                        );
                      }),
                    ),
                  ),
                ),
              ],
            ),
          );
        }),
      ],
    );
  }
}

// ─────────────────────────── SHARED WIDGETS ──────────────────────────────────

class _DonutWithLegend extends StatelessWidget {
  final List<MapEntry<String, double>> entries;
  final double total;
  final List<Color> catColors;
  final List<Map<String, dynamic>> customCats;
  final String Function(double) formatCompact;
  final Color textMain;

  const _DonutWithLegend({
    required this.entries,
    required this.total,
    required this.catColors,
    required this.customCats,
    required this.formatCompact,
    required this.textMain,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Row(
      children: [
        Expanded(
          flex: 5,
          child: SizedBox(
            height: 140,
            child: Stack(
              alignment: Alignment.center,
              children: [
                PieChart(PieChartData(
                  sections: entries.asMap().entries.map((e) {
                    final color = e.key < catColors.length
                        ? catColors[e.key]
                        : getCategoryColor(e.value.key, customCats);
                    return PieChartSectionData(
                        value: e.value.value,
                        color: color,
                        title: '',
                        radius: 18);
                  }).toList(),
                  centerSpaceRadius: 42,
                  sectionsSpace: 3,
                )),
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(formatCompact(total),
                        style: TextStyle(
                            color: cs.onSurface,
                            fontSize: 16,
                            fontWeight: FontWeight.w800)),
                    Text('TOTAL',
                        style: TextStyle(
                            color: cs.onSurface.withValues(alpha: 0.35),
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 1)),
                  ],
                ),
              ],
            ),
          ),
        ),
        Expanded(
          flex: 4,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: entries.asMap().entries.take(5).map((e) {
              final color = e.key < catColors.length
                  ? catColors[e.key]
                  : getCategoryColor(e.value.key, customCats);
              final pct =
                  total > 0 ? (e.value.value / total * 100).toStringAsFixed(0) : '0';
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 5),
                child: Row(
                  children: [
                    Container(
                        width: 10,
                        height: 10,
                        decoration: BoxDecoration(
                            color: color, shape: BoxShape.circle)),
                    const SizedBox(width: 8),
                    Expanded(
                        child: Text(e.value.key,
                            style: TextStyle(
                                color: cs.onSurface.withValues(alpha: 0.6),
                                fontSize: 12,
                                fontWeight: FontWeight.w500),
                            overflow: TextOverflow.ellipsis)),
                    Text('$pct%',
                        style: TextStyle(
                            color: cs.onSurface,
                            fontSize: 12,
                            fontWeight: FontWeight.w700)),
                  ],
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }
}

class _CategoryRow extends StatelessWidget {
  final MapEntry<String, double> entry;
  final double total;
  final int txCount;
  final List<Map<String, dynamic>> customCats;
  final NumberFormat fmt;
  final BudgetProvider? budgetProvider;
  final Color bg;

  const _CategoryRow({
    required this.entry,
    required this.total,
    required this.txCount,
    required this.customCats,
    required this.fmt,
    required this.budgetProvider,
    required this.bg,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final catColor = getCategoryColor(entry.key, customCats);
    final catIcon = getCategoryIconByName(entry.key, customCats);

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: cs.surfaceContainerLow,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 8,
              offset: const Offset(0, 2)),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: catColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(catIcon, color: catColor, size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(entry.key,
                    style: TextStyle(
                        color: cs.onSurface,
                        fontSize: 15,
                        fontWeight: FontWeight.w600)),
                const SizedBox(height: 3),
                Text('$txCount Transaction${txCount != 1 ? 's' : ''}',
                    style: TextStyle(
                        color: cs.onSurface.withValues(alpha: 0.4),
                        fontSize: 12)),
                if (budgetProvider != null)
                  Builder(builder: (_) {
                    final limit =
                        budgetProvider!.categoryLimit(entry.key);
                    if (limit <= 0) return const SizedBox.shrink();
                    final pct = budgetProvider!
                        .categoryUsedPercent(entry.key, entry.value);
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
                              backgroundColor:
                                  barColor.withValues(alpha: 0.15),
                              valueColor:
                                  AlwaysStoppedAnimation<Color>(barColor),
                              minHeight: 5,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text('${pct.toStringAsFixed(0)}% of limit',
                              style: TextStyle(
                                  color: barColor,
                                  fontSize: 10,
                                  fontWeight: FontWeight.w600)),
                        ],
                      ),
                    );
                  }),
              ],
            ),
          ),
          Text(fmt.format(entry.value),
              style: TextStyle(
                  color: cs.onSurface,
                  fontSize: 15,
                  fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }
}

// ─────────────────────────── HELPERS ─────────────────────────────────────────

List<Color> _catColorList() => const [
      Color(0xFF5D3891),
      Color(0xFFFF6B6B),
      Color(0xFF51CF66),
      Color(0xFF339AF0),
      Color(0xFFFCC419),
      Color(0xFFFF922B),
      Color(0xFFCC5DE8),
      Color(0xFF20C997),
      Color(0xFFE64980),
      Color(0xFF22B8CF),
    ];

Widget _summaryCard({
  required String label,
  required String amount,
  required String badgeLabel,
  required double progressValue,
  Color color = const Color(0xFF5D3891),
}) {
  return Container(
    width: double.infinity,
    padding: const EdgeInsets.all(22),
    decoration: BoxDecoration(
      gradient: LinearGradient(
        colors: [color, Color.lerp(color, Colors.white, 0.25)!],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
      borderRadius: BorderRadius.circular(20),
      boxShadow: [
        BoxShadow(
            color: color.withValues(alpha: 0.35),
            blurRadius: 20,
            offset: const Offset(0, 8)),
      ],
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label,
                style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.7),
                    fontSize: 14,
                    fontWeight: FontWeight.w500)),
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(badgeLabel,
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w700)),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text(amount,
            style: const TextStyle(
                color: Colors.white,
                fontSize: 32,
                fontWeight: FontWeight.w800)),
        const SizedBox(height: 16),
        ClipRRect(
          borderRadius: BorderRadius.circular(6),
          child: LinearProgressIndicator(
            value: progressValue.clamp(0.0, 1.0),
            minHeight: 8,
            backgroundColor: Colors.white.withValues(alpha: 0.15),
            valueColor:
                const AlwaysStoppedAnimation<Color>(Colors.white),
          ),
        ),
        const SizedBox(height: 8),
        Align(
          alignment: Alignment.centerRight,
          child: Text(badgeLabel,
              style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.6),
                  fontSize: 12,
                  fontWeight: FontWeight.w500)),
        ),
      ],
    ),
  );
}

Widget _chartCard(BuildContext context, {required String title, required Widget child}) {
  final cs = Theme.of(context).colorScheme;
  return Container(
    width: double.infinity,
    padding: const EdgeInsets.all(20),
    decoration: BoxDecoration(
      color: cs.surfaceContainerLow,
      borderRadius: BorderRadius.circular(20),
      boxShadow: [
        BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 12,
            offset: const Offset(0, 4)),
      ],
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title,
            style: TextStyle(
                color: cs.onSurface,
                fontSize: 17,
                fontWeight: FontWeight.w700)),
        const SizedBox(height: 16),
        child,
      ],
    ),
  );
}

BarChartData _buildBarData(
  List<double> totals,
  List<String> labels,
  NumberFormat fmt,
  Color primary,
  Color textMain, {
  Color? barColor,
}) {
  return BarChartData(
    alignment: BarChartAlignment.spaceAround,
    maxY: _getMaxY(totals),
    barTouchData: BarTouchData(
      enabled: true,
      touchTooltipData: BarTouchTooltipData(
        tooltipRoundedRadius: 8,
        getTooltipItem: (group, gi, rod, ri) => BarTooltipItem(
          fmt.format(rod.toY),
          const TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.w600),
        ),
      ),
    ),
    titlesData: FlTitlesData(
      bottomTitles: AxisTitles(
        sideTitles: SideTitles(
          showTitles: true,
          getTitlesWidget: (value, _) {
            final idx = value.toInt();
            if (idx < 0 || idx >= labels.length) return const Text('');
            return Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(labels[idx],
                  style: TextStyle(
                      color: idx == 5
                          ? primary
                          : textMain.withValues(alpha: 0.35),
                      fontSize: 11,
                      fontWeight: idx == 5
                          ? FontWeight.w700
                          : FontWeight.w500)),
            );
          },
        ),
      ),
      leftTitles:
          const AxisTitles(sideTitles: SideTitles(showTitles: false)),
      topTitles:
          const AxisTitles(sideTitles: SideTitles(showTitles: false)),
      rightTitles:
          const AxisTitles(sideTitles: SideTitles(showTitles: false)),
    ),
    gridData: const FlGridData(show: false),
    borderData: FlBorderData(show: false),
    barGroups: List.generate(6, (i) {
      final isLast = i == 5;
      final bc = barColor ?? primary;
      return BarChartGroupData(
        x: i,
        barRods: [
          BarChartRodData(
            toY: totals[i],
            gradient: (barColor == null && isLast)
                ? const LinearGradient(
                    colors: [Color(0xFF5D3891), Color(0xFF7B52AB)],
                    begin: Alignment.bottomCenter,
                    end: Alignment.topCenter,
                  )
                : null,
            color: (barColor == null && isLast)
                ? null
                : isLast
                    ? bc
                    : bc.withValues(alpha: 0.25),
            width: 14,
            borderRadius: BorderRadius.circular(6),
          ),
        ],
      );
    }),
  );
}

double _getMaxY(List<double> values) {
  double max = 100;
  for (final v in values) {
    if (v > max) max = v;
  }
  return max * 1.3;
}
