import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../data/models/transaction_model.dart';
import '../../../data/models/user_model.dart';
import '../../blocs/transaction/transaction_bloc.dart';
import '../../blocs/transaction/transaction_state.dart';

class AnalyticsTab extends StatefulWidget {
  final UserModel user;
  const AnalyticsTab({super.key, required this.user});
  @override
  State<AnalyticsTab> createState() => _AnalyticsTabState();
}

class _AnalyticsTabState extends State<AnalyticsTab>
    with SingleTickerProviderStateMixin {
  late TabController _tabs;
  int _touchedPie = -1;

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() { _tabs.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Analytics'),
        bottom: TabBar(
          controller: _tabs,
          indicatorColor: AppColors.primary,
          indicatorWeight: 2,
          labelColor: AppColors.primary,
          unselectedLabelColor: AppColors.textMuted,
          tabs: const [Tab(text: 'Overview'), Tab(text: 'Trends')],
        ),
      ),
      body: BlocBuilder<TransactionBloc, TransactionState>(
        builder: (context, state) {
          if (state is! TransactionLoaded) {
            return const Center(child: CircularProgressIndicator(color: AppColors.primary));
          }

          final now = DateTime.now();
          final monthTxns = state.transactions
              .where((t) => t.date.year == now.year && t.date.month == now.month)
              .toList();
          final expenses = monthTxns.where((t) => t.isExpense).toList();
          final totalExpense = expenses.fold(0.0, (s, t) => s + t.amount);
          final totalIncome = monthTxns.where((t) => t.isIncome).fold(0.0, (s, t) => s + t.amount);

          final Map<String, double> catTotals = {};
          for (final t in expenses) {
            catTotals[t.category] = (catTotals[t.category] ?? 0) + t.amount;
          }
          final sorted = catTotals.entries.toList()
            ..sort((a, b) => b.value.compareTo(a.value));

          // Last 6 months bar data
          final barData = _buildMonthlyBars(state.transactions);

          return TabBarView(
            controller: _tabs,
            children: [
              // ── Overview tab ──────────────────────────────
              ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  _SummaryStrip(income: totalIncome, expense: totalExpense)
                      .animate().fadeIn(duration: 350.ms),
                  const SizedBox(height: 16),
                  if (sorted.isNotEmpty) ...[
                    _PieCard(
                      sorted: sorted,
                      total: totalExpense,
                      touchedIndex: _touchedPie,
                      onTouch: (i) => setState(() => _touchedPie = i),
                    ).animate().fadeIn(delay: 80.ms),
                    const SizedBox(height: 16),
                    _CategoryBars(sorted: sorted, total: totalExpense)
                        .animate().fadeIn(delay: 160.ms),
                  ] else
                    const _NoData(),
                  const SizedBox(height: 80),
                ],
              ),
              // ── Trends tab ────────────────────────────────
              ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  _MonthlyBarChart(data: barData)
                      .animate().fadeIn(duration: 350.ms),
                  const SizedBox(height: 16),
                  _SpendingInsights(transactions: state.transactions)
                      .animate().fadeIn(delay: 100.ms),
                  const SizedBox(height: 80),
                ],
              ),
            ],
          );
        },
      ),
    );
  }

  List<_MonthBar> _buildMonthlyBars(List<TransactionModel> all) {
    final now = DateTime.now();
    return List.generate(6, (i) {
      final month = DateTime(now.year, now.month - 5 + i);
      final txns = all.where((t) =>
        t.date.year == month.year && t.date.month == month.month).toList();
      return _MonthBar(
        label: DateFormat('MMM').format(month),
        income: txns.where((t) => t.isIncome).fold(0.0, (s, t) => s + t.amount),
        expense: txns.where((t) => t.isExpense).fold(0.0, (s, t) => s + t.amount),
      );
    });
  }
}

class _MonthBar { final String label; final double income; final double expense;
  _MonthBar({required this.label, required this.income, required this.expense}); }

// ── Widgets ───────────────────────────────────────────────────

final _pieColors = [
  AppColors.primary, AppColors.accent, AppColors.warning,
  AppColors.expense, AppColors.info, const Color(0xFFCE93D8),
  const Color(0xFF80CBC4), const Color(0xFFFFCC02),
];

class _SummaryStrip extends StatelessWidget {
  final double income, expense;
  const _SummaryStrip({required this.income, required this.expense});

  @override
  Widget build(BuildContext context) {
    final savings = income - expense;
    final savingsPct = income > 0 ? (savings / income * 100).clamp(0.0, 100.0) : 0.0;
    return Row(children: [
      Expanded(child: _Strip(label: 'Income', value: CurrencyFormatter.formatCompact(income), color: AppColors.income)),
      const SizedBox(width: 8),
      Expanded(child: _Strip(label: 'Spent', value: CurrencyFormatter.formatCompact(expense), color: AppColors.expense)),
      const SizedBox(width: 8),
      Expanded(child: _Strip(label: 'Saved', value: '${savingsPct.toStringAsFixed(0)}%', color: AppColors.accent)),
    ]);
  }
}

class _Strip extends StatelessWidget {
  final String label, value; final Color color;
  const _Strip({required this.label, required this.value, required this.color});
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(vertical: 14),
    decoration: BoxDecoration(
      color: color.withOpacity(0.08),
      borderRadius: BorderRadius.circular(14),
      border: Border.all(color: color.withOpacity(0.2)),
    ),
    child: Column(children: [
      Text(value, style: TextStyle(color: color, fontWeight: FontWeight.w800, fontSize: 16)),
      const SizedBox(height: 2),
      Text(label, style: const TextStyle(color: AppColors.textMuted, fontSize: 11)),
    ]),
  );
}

class _PieCard extends StatelessWidget {
  final List<MapEntry<String, double>> sorted;
  final double total;
  final int touchedIndex;
  final ValueChanged<int> onTouch;
  const _PieCard({required this.sorted, required this.total, required this.touchedIndex, required this.onTouch});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Text('Expense Breakdown',
          style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w700, fontSize: 16)),
        const SizedBox(height: 20),
        SizedBox(
          height: 220,
          child: PieChart(PieChartData(
            pieTouchData: PieTouchData(touchCallback: (_, r) =>
              onTouch(r?.touchedSection?.touchedSectionIndex ?? -1)),
            sections: sorted.asMap().entries.map((e) {
              final touched = e.key == touchedIndex;
              final color = _pieColors[e.key % _pieColors.length];
              return PieChartSectionData(
                color: color,
                value: e.value.value,
                title: touched
                  ? '${(e.value.value / total * 100).toStringAsFixed(1)}%'
                  : '',
                radius: touched ? 90 : 76,
                titleStyle: const TextStyle(
                  color: Colors.white, fontWeight: FontWeight.w700, fontSize: 12),
                borderSide: touched
                  ? const BorderSide(color: Colors.white24, width: 2)
                  : BorderSide.none,
              );
            }).toList(),
            centerSpaceRadius: 44,
            sectionsSpace: 2.5,
          )),
        ),
        if (touchedIndex >= 0 && touchedIndex < sorted.length) ...[
          const SizedBox(height: 12),
          Center(child: Text(
            '${sorted[touchedIndex].key}  •  ${CurrencyFormatter.format(sorted[touchedIndex].value)}',
            style: const TextStyle(color: AppColors.textSecondary, fontSize: 13, fontWeight: FontWeight.w600),
          )),
        ],
      ]),
    );
  }
}

class _CategoryBars extends StatelessWidget {
  final List<MapEntry<String, double>> sorted;
  final double total;
  const _CategoryBars({required this.sorted, required this.total});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Text('By Category',
          style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w700, fontSize: 16)),
        const SizedBox(height: 16),
        ...sorted.asMap().entries.map((e) {
          final color = _pieColors[e.key % _pieColors.length];
          final pct = total > 0 ? e.value.value / total : 0.0;
          return Padding(
            padding: const EdgeInsets.only(bottom: 14),
            child: Column(children: [
              Row(children: [
                Container(width: 10, height: 10,
                  decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
                const SizedBox(width: 8),
                Expanded(child: Text(e.value.key,
                  style: const TextStyle(color: AppColors.textPrimary, fontSize: 13))),
                Text(CurrencyFormatter.formatCompact(e.value.value),
                  style: TextStyle(color: color, fontWeight: FontWeight.w700, fontSize: 13)),
                const SizedBox(width: 6),
                Text('${(pct * 100).toStringAsFixed(0)}%',
                  style: const TextStyle(color: AppColors.textMuted, fontSize: 11)),
              ]),
              const SizedBox(height: 6),
              TweenAnimationBuilder<double>(
                tween: Tween(begin: 0, end: pct),
                duration: const Duration(milliseconds: 900),
                curve: Curves.easeOutCubic,
                builder: (_, v, __) => ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: v, backgroundColor: AppColors.bg700,
                    valueColor: AlwaysStoppedAnimation(color), minHeight: 6,
                  ),
                ),
              ),
            ]),
          );
        }),
      ]),
    );
  }
}

class _MonthlyBarChart extends StatelessWidget {
  final List<_MonthBar> data;
  const _MonthlyBarChart({required this.data});

  @override
  Widget build(BuildContext context) {
    final maxY = data.fold(0.0, (m, b) => [m, b.income, b.expense].reduce((a, c) => a > c ? a : c));
    final topY = maxY < 1000 ? 1000.0 : (maxY * 1.2);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Text('6-Month Trend',
          style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w700, fontSize: 16)),
        const SizedBox(height: 8),
        Row(children: [
          _Dot(color: AppColors.income, label: 'Income'),
          const SizedBox(width: 16),
          _Dot(color: AppColors.expense, label: 'Expense'),
        ]),
        const SizedBox(height: 20),
        SizedBox(
          height: 200,
          child: BarChart(BarChartData(
            maxY: topY,
            gridData: FlGridData(
              show: true,
              drawVerticalLine: false,
              getDrawingHorizontalLine: (_) => FlLine(
                color: AppColors.border, strokeWidth: 0.5),
            ),
            borderData: FlBorderData(show: false),
            titlesData: FlTitlesData(
              bottomTitles: AxisTitles(sideTitles: SideTitles(
                showTitles: true, reservedSize: 24,
                getTitlesWidget: (v, _) => Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Text(data[v.toInt()].label,
                    style: const TextStyle(color: AppColors.textMuted, fontSize: 10)),
                ),
              )),
              leftTitles: AxisTitles(sideTitles: SideTitles(
                showTitles: true, reservedSize: 42,
                getTitlesWidget: (v, _) => Text(
                  CurrencyFormatter.formatCompact(v),
                  style: const TextStyle(color: AppColors.textMuted, fontSize: 9)),
              )),
              topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
              rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            ),
            barGroups: data.asMap().entries.map((e) => BarChartGroupData(
              x: e.key,
              barRods: [
                BarChartRodData(
                  toY: e.value.income,
                  color: AppColors.income,
                  width: 10,
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
                ),
                BarChartRodData(
                  toY: e.value.expense,
                  color: AppColors.expense,
                  width: 10,
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
                ),
              ],
              barsSpace: 4,
            )).toList(),
            barTouchData: BarTouchData(
              touchTooltipData: BarTouchTooltipData(
                getTooltipColor: (_) => AppColors.surfaceElevated,
                getTooltipItem: (group, _, rod, rodIndex) => BarTooltipItem(
                  '${rodIndex == 0 ? "In" : "Out"}\n${CurrencyFormatter.formatCompact(rod.toY)}',
                  TextStyle(
                    color: rodIndex == 0 ? AppColors.income : AppColors.expense,
                    fontWeight: FontWeight.w700, fontSize: 11,
                  ),
                ),
              ),
            ),
          )),
        ),
      ]),
    );
  }
}

class _Dot extends StatelessWidget {
  final Color color; final String label;
  const _Dot({required this.color, required this.label});
  @override
  Widget build(BuildContext context) => Row(children: [
    Container(width: 8, height: 8, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
    const SizedBox(width: 5),
    Text(label, style: const TextStyle(color: AppColors.textMuted, fontSize: 11)),
  ]);
}

class _SpendingInsights extends StatelessWidget {
  final List<TransactionModel> transactions;
  const _SpendingInsights({required this.transactions});

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    // Best month (lowest expense)
    final monthlyExpense = <String, double>{};
    for (final t in transactions) {
      if (!t.isExpense) continue;
      final key = '${t.date.year}-${t.date.month.toString().padLeft(2,'0')}';
      monthlyExpense[key] = (monthlyExpense[key] ?? 0) + t.amount;
    }
    final bestEntry = monthlyExpense.entries.isEmpty ? null
        : monthlyExpense.entries.reduce((a, b) => a.value < b.value ? a : b);

    final thisMonthExp = transactions.where((t) =>
      t.isExpense && t.date.year == now.year && t.date.month == now.month)
      .fold(0.0, (s, t) => s + t.amount);
    final lastMonthExp = transactions.where((t) =>
      t.isExpense && t.date.year == now.year && t.date.month == now.month - 1)
      .fold(0.0, (s, t) => s + t.amount);
    final momDelta = lastMonthExp > 0 ? ((thisMonthExp - lastMonthExp) / lastMonthExp * 100) : 0.0;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Text('Insights',
          style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w700, fontSize: 16)),
        const SizedBox(height: 16),
        if (lastMonthExp > 0)
          _InsightRow(
            icon: momDelta <= 0 ? Icons.trending_down_rounded : Icons.trending_up_rounded,
            color: momDelta <= 0 ? AppColors.income : AppColors.expense,
            text: momDelta <= 0
              ? 'You spent ${momDelta.abs().toStringAsFixed(0)}% less than last month 🎉'
              : 'You spent ${momDelta.toStringAsFixed(0)}% more than last month',
          ),
        if (bestEntry != null) ...[
          const SizedBox(height: 10),
          _InsightRow(
            icon: Icons.emoji_events_rounded,
            color: AppColors.warning,
            text: 'Your lowest-spend month was ${bestEntry.key} — ${CurrencyFormatter.formatCompact(bestEntry.value)}',
          ),
        ],
        if (transactions.isEmpty)
          const Text('Log more transactions to see insights',
            style: TextStyle(color: AppColors.textMuted)),
      ]),
    );
  }
}

class _InsightRow extends StatelessWidget {
  final IconData icon; final Color color; final String text;
  const _InsightRow({required this.icon, required this.color, required this.text});
  @override
  Widget build(BuildContext context) => Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
    Container(
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(color: color.withOpacity(0.12), borderRadius: BorderRadius.circular(8)),
      child: Icon(icon, color: color, size: 16),
    ),
    const SizedBox(width: 10),
    Expanded(child: Text(text, style: const TextStyle(color: AppColors.textSecondary, fontSize: 13))),
  ]);
}

class _NoData extends StatelessWidget {
  const _NoData();
  @override
  Widget build(BuildContext context) => const Center(child: Padding(
    padding: EdgeInsets.all(48),
    child: Column(children: [
      Text('📊', style: TextStyle(fontSize: 40)),
      SizedBox(height: 12),
      Text('No data yet', style: TextStyle(color: AppColors.textMuted)),
    ]),
  ));
}
