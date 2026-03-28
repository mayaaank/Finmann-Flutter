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
import 'package:finmann/shared/widgets/fm_card.dart';
import 'package:finmann/shared/widgets/fm_skeleton.dart';

// Softer, more harmonious palette — avoids harsh reds/yellows clashing
const _kPieColors = [
  Color.fromARGB(255, 81, 189, 137), // soft indigo
  Color.fromARGB(255, 77, 159, 217), // mint green
  Color(0xFFFFB17A), // warm peach
  Color.fromARGB(255, 199, 123, 148), // rose
  Color.fromARGB(255, 173, 221, 243), // sky blue
  Color.fromARGB(255, 139, 123, 168), // lavender
  Color.fromARGB(255, 92, 151, 145), // teal
  Color(0xFFFFF176), // pale yellow
];
Color _pc(int i) => _kPieColors[i % _kPieColors.length];

// ─── Main Tab ────────────────────────────────────────────────
class AnalyticsTab extends StatefulWidget {
  final UserModel user;
  const AnalyticsTab({super.key, required this.user});
  @override State<AnalyticsTab> createState() => _AnalyticsTabState();
}

class _AnalyticsTabState extends State<AnalyticsTab>
    with SingleTickerProviderStateMixin {
  late final TabController _tabs = TabController(length: 2, vsync: this);
  int _touched = -1;

  @override
  void dispose() { _tabs.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.cream100,
      appBar: _appBar(),
      body: BlocBuilder<TransactionBloc, TransactionState>(
        builder: (context, state) {
          if (state is! TransactionLoaded) {
            return ListView(
              padding: const EdgeInsets.all(16),
              children: const [
                FmSkeleton(width: double.infinity, height: 90),
                SizedBox(height: 12),
                FmSkeleton(width: double.infinity, height: 90),
                SizedBox(height: 12),
                FmSkeleton(width: double.infinity, height: 320),
              ],
            );
          }
          final now = DateTime.now();
          final month = state.transactions.where(
              (t) => t.date.year == now.year && t.date.month == now.month).toList();
          final expenses = month.where((t) => t.isExpense).toList();
          final totalExp = expenses.fold(0.0, (s, t) => s + t.amount);
          final totalInc = month.where((t) => t.isIncome).fold(0.0, (s, t) => s + t.amount);
          final catMap = <String, double>{};
          for (final t in expenses) catMap[t.category] = (catMap[t.category] ?? 0) + t.amount;
          final sorted = catMap.entries.toList()..sort((a, b) => b.value.compareTo(a.value));
          final bars = _monthBars(state.transactions);
          final score = _healthScore(totalInc, totalExp, expenses);

          return TabBarView(controller: _tabs, children: [
            // ── Overview ──
            ListView(padding: const EdgeInsets.fromLTRB(16, 20, 16, 100), children: [
              _SummaryRow(income: totalInc, expense: totalExp)
                  .animate().fadeIn(duration: 300.ms).slideY(begin: 0.08, end: 0),
              const SizedBox(height: 12),
              _HealthScore(score: score)
                  .animate().fadeIn(delay: 60.ms).slideY(begin: 0.08, end: 0),
              const SizedBox(height: 12),
              if (sorted.isEmpty) const _NoData()
              else ...[
                _PieCard(sorted: sorted, total: totalExp, touched: _touched,
                    onTouch: (i) => setState(() => _touched = i))
                    .animate().fadeIn(delay: 120.ms).slideY(begin: 0.08, end: 0),
                const SizedBox(height: 12),
                _CategoryBars(sorted: sorted, total: totalExp)
                    .animate().fadeIn(delay: 180.ms).slideY(begin: 0.08, end: 0),
              ],
            ]),
            // ── Trends ──
            ListView(padding: const EdgeInsets.fromLTRB(16, 20, 16, 100), children: [
              _BarChart(bars: bars)
                  .animate().fadeIn(duration: 300.ms).slideY(begin: 0.08, end: 0),
              const SizedBox(height: 12),
              _Insights(transactions: state.transactions)
                  .animate().fadeIn(delay: 100.ms).slideY(begin: 0.08, end: 0),
            ]),
          ]);
        },
      ),
    );
  }

  /// Score 0–100: savings rate + transaction diversity + low overspend
  int _healthScore(double inc, double exp, List<TransactionModel> expenses) {
    if (inc == 0) return 0;
    final savings = ((inc - exp) / inc * 100).clamp(0.0, 100.0);
    final diversity = (expenses.map((e) => e.category).toSet().length).clamp(0, 8) / 8 * 20;
    final base = (savings * 0.8 + diversity).clamp(0.0, 100.0);
    return base.round();
  }

  PreferredSizeWidget _appBar() => PreferredSize(
    preferredSize: const Size.fromHeight(96),
    child: Container(
      decoration: const BoxDecoration(
        color: AppColors.cream100,
        border: Border(bottom: BorderSide(color: AppColors.border)),
      ),
      child: SafeArea(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 10, 20, 8),
          child: Text('Analytics', style: TextStyle(fontFamily: 'DM Sans', 
              color: AppColors.textPrimary, fontSize: 24,
              fontWeight: FontWeight.w800, letterSpacing: -0.5)),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: _PillTabs(controller: _tabs),
        ),
      ])),
    ),
  );

  List<({String label, double income, double expense})> _monthBars(
      List<TransactionModel> all) {
    final now = DateTime.now();
    return List.generate(6, (i) {
      final m = DateTime(now.year, now.month - 5 + i);
      final txns = all.where(
          (t) => t.date.year == m.year && t.date.month == m.month).toList();
      return (
        label: DateFormat('MMM').format(m),
        income: txns.where((t) => t.isIncome).fold(0.0, (s, t) => s + t.amount),
        expense: txns.where((t) => t.isExpense).fold(0.0, (s, t) => s + t.amount),
      );
    });
  }
}

// ── Pill Tabs ─────────────────────────────────────────────────
class _PillTabs extends StatefulWidget {
  final TabController controller;
  const _PillTabs({required this.controller});
  @override State<_PillTabs> createState() => _PillTabsState();
}
class _PillTabsState extends State<_PillTabs> {
  @override
  void initState() { super.initState(); widget.controller.addListener(() => setState(() {})); }
  @override
  Widget build(BuildContext context) => Container(
    height: 36,
    decoration: BoxDecoration(color: AppColors.cream300,
        borderRadius: BorderRadius.circular(12), border: Border.all(color: AppColors.border)),
    child: Row(children: ['Overview', 'Trends'].asMap().entries.map((e) {
      final active = widget.controller.index == e.key;
      return Expanded(child: GestureDetector(
        onTap: () => widget.controller.animateTo(e.key),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          margin: const EdgeInsets.all(3),
          decoration: BoxDecoration(
            color: active ? AppColors.primary : Colors.transparent,
            borderRadius: BorderRadius.circular(9),
          ),
          alignment: Alignment.center,
          child: Text(e.value, style: TextStyle(fontFamily: 'DM Sans', 
              color: active ? AppColors.cream100 : AppColors.textMuted,
              fontWeight: FontWeight.w700, fontSize: 13)),
        ),
      ));
    }).toList()),
  );
}

// ── Summary Row ───────────────────────────────────────────────
class _SummaryRow extends StatelessWidget {
  final double income, expense;
  const _SummaryRow({required this.income, required this.expense});
  @override
  Widget build(BuildContext context) {
    final pct = income > 0 ? ((income - expense) / income * 100).clamp(0.0, 100.0) : 0.0;
    return Row(children: [
      _StatTile('Income', CurrencyFormatter.formatCompact(income), AppColors.income, Icons.arrow_downward_rounded),
      const SizedBox(width: 10),
      _StatTile('Spent', CurrencyFormatter.formatCompact(expense), AppColors.expense, Icons.arrow_upward_rounded),
      const SizedBox(width: 10),
      _StatTile('Saved', '${pct.toStringAsFixed(0)}%', AppColors.accent, Icons.savings_rounded),
    ]);
  }
}

Widget _StatTile(String label, String value, Color color, IconData icon) =>
    Expanded(child: Container(
      padding: const EdgeInsets.fromLTRB(10, 12, 10, 12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [color.withValues(alpha: 0.10), color.withValues(alpha: 0.04)],
          begin: Alignment.topLeft, end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.22)),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Container(padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(color: color.withValues(alpha: 0.18),
                borderRadius: BorderRadius.circular(6)),
            child: Icon(icon, color: color, size: 11)),
          const SizedBox(width: 5),
          Text(label, style: TextStyle(fontFamily: 'DM Sans', color: AppColors.textMuted, fontSize: 10)),
        ]),
        const SizedBox(height: 7),
        Text(value, style: TextStyle(fontFamily: 'DM Sans', 
            color: color, fontWeight: FontWeight.w800, fontSize: 15, letterSpacing: -0.3)),
      ]),
    ));

// ── Health Score ──────────────────────────────────────────────
class _HealthScore extends StatelessWidget {
  final int score;
  const _HealthScore({required this.score});

  (String label, Color color, String emoji) get _grade {
    if (score >= 80) return ('Excellent', AppColors.income, '🏆');
    if (score >= 60) return ('Good', AppColors.accent, '👍');
    if (score >= 40) return ('Fair', AppColors.warning, '⚡');
    return ('Needs work', AppColors.expense, '💡');
  }

  @override
  Widget build(BuildContext context) {
    final (label, color, emoji) = _grade;
    final pct = score / 100.0;
    return FmCard(
      borderColor: color.withValues(alpha: 0.25),
      backgroundColor: color.withValues(alpha: 0.04),
      child: Row(children: [
        SizedBox(width: 68, height: 68, child: Stack(alignment: Alignment.center, children: [
          TweenAnimationBuilder<double>(
            tween: Tween(begin: 0, end: pct),
            duration: const Duration(milliseconds: 1100),
            curve: Curves.easeOutCubic,
            builder: (_, v, __) => CircularProgressIndicator(
              value: v, strokeWidth: 6,
              backgroundColor: AppColors.cream300,
              valueColor: AlwaysStoppedAnimation(color),
              strokeCap: StrokeCap.round,
            ),
          ),
          Text(emoji, style: const TextStyle(fontSize: 22)),
        ])),
        const SizedBox(width: 16),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Text('Financial Health', style: TextStyle(fontFamily: 'DM Sans', 
                color: AppColors.textPrimary, fontWeight: FontWeight.w700, fontSize: 14)),
            const Spacer(),
            _chip(label, color),
          ]),
          const SizedBox(height: 4),
          TweenAnimationBuilder<int>(
            tween: IntTween(begin: 0, end: score),
            duration: const Duration(milliseconds: 1100),
            builder: (_, v, __) => Text('$v / 100',
                style: TextStyle(fontFamily: 'DM Sans', 
                    color: color, fontSize: 22,
                    fontWeight: FontWeight.w800, letterSpacing: -1)),
          ),
          Text('Based on savings rate & spending variety',
              style: TextStyle(fontFamily: 'DM Sans', color: AppColors.textMuted, fontSize: 10)),
        ])),
      ]),
    );
  }
}

// ── Pie Card ──────────────────────────────────────────────────
class _PieCard extends StatelessWidget {
  final List<MapEntry<String, double>> sorted;
  final double total;
  final int touched;
  final ValueChanged<int> onTouch;
  const _PieCard({required this.sorted, required this.total,
    required this.touched, required this.onTouch});

  @override
  Widget build(BuildContext context) {
    final hasTouch = touched >= 0 && touched < sorted.length;
    return FmCard(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [
        Text('Expense Breakdown', style: TextStyle(fontFamily: 'DM Sans', 
            color: AppColors.textPrimary, fontWeight: FontWeight.w700, fontSize: 16)),
        const Spacer(),
        _chip(CurrencyFormatter.formatCompact(total), AppColors.expense),
      ]),
      const SizedBox(height: 18),
      // Fixed height — radius never grows outside this box
      SizedBox(height: 200, child: Stack(alignment: Alignment.center, children: [
        PieChart(PieChartData(
          pieTouchData: PieTouchData(touchCallback: (_, r) =>
              onTouch(r?.touchedSection?.touchedSectionIndex ?? -1)),
          sections: sorted.asMap().entries.map((e) {
            final active = e.key == touched;
            final c = _pc(e.key);
            final pct = total > 0 ? e.value.value / total * 100 : 0.0;
            return PieChartSectionData(
              color: active ? c : c.withValues(alpha: 0.75),
              value: e.value.value,
              // Show % label only on active slice, inside the ring
              title: active ? '${pct.toStringAsFixed(0)}%' : '',
              titleStyle: TextStyle(fontFamily: 'DM Sans', 
                  color: Colors.white, fontSize: 11, fontWeight: FontWeight.w700),
              titlePositionPercentageOffset: 0.6,
              // Small radius bump — stays within fixed SizedBox
              radius: active ? 74 : 62,
              borderSide: active
                  ? BorderSide(color: c, width: 2)
                  : BorderSide(color: c.withValues(alpha: 0.15), width: 0.5),
            );
          }).toList(),
          centerSpaceRadius: 54, sectionsSpace: 2,
        )),
        // Tap center to deselect
        GestureDetector(
          onTap: () { if (hasTouch) onTouch(-1); },
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 200),
            transitionBuilder: (child, anim) =>
                FadeTransition(opacity: anim, child: ScaleTransition(scale: anim, child: child)),
            child: hasTouch
                ? _CenterLabel(key: ValueKey(touched),
                    value: CurrencyFormatter.formatCompact(sorted[touched].value),
                    label: sorted[touched].key, color: _pc(touched))
                : _CenterLabel(key: const ValueKey('total'),
                    value: CurrencyFormatter.formatCompact(total),
                    label: 'Tap a slice', color: AppColors.textMuted),
          ),
        ),
      ])),
      const SizedBox(height: 14),
      // Legend chips — always visible, no layout shift
      Wrap(spacing: 7, runSpacing: 7, children: sorted.asMap().entries.take(6).map((e) {
        final c = _pc(e.key);
        final active = e.key == touched;
        final pct = total > 0 ? e.value.value / total * 100 : 0.0;
        return GestureDetector(
          onTap: () => onTouch(active ? -1 : e.key),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
            decoration: BoxDecoration(
              color: active ? c.withValues(alpha: 0.18) : c.withValues(alpha: 0.06),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: active ? c : c.withValues(alpha: 0.2)),
            ),
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              Container(width: 7, height: 7,
                  decoration: BoxDecoration(color: c, shape: BoxShape.circle)),
              const SizedBox(width: 5),
              Text('${e.value.key}  ${pct.toStringAsFixed(0)}%',
                  style: TextStyle(fontFamily: 'DM Sans', 
                      color: active ? c : AppColors.textSecondary,
                      fontSize: 11,
                      fontWeight: active ? FontWeight.w700 : FontWeight.w400)),
            ]),
          ),
        );
      }).toList()),
    ]));
  }
}

class _CenterLabel extends StatelessWidget {
  final String value, label; final Color color;
  const _CenterLabel({super.key, required this.value, required this.label, required this.color});
  @override
  Widget build(BuildContext context) => Column(mainAxisSize: MainAxisSize.min, children: [
    Text(value, style: TextStyle(fontFamily: 'DM Sans', 
        color: color, fontWeight: FontWeight.w800, fontSize: 15, letterSpacing: -0.3)),
    const SizedBox(height: 2),
    Text(label, style: TextStyle(fontFamily: 'DM Sans', color: AppColors.textMuted, fontSize: 10)),
  ]);
}

// ── Category Bars ─────────────────────────────────────────────
class _CategoryBars extends StatelessWidget {
  final List<MapEntry<String, double>> sorted;
  final double total;
  const _CategoryBars({required this.sorted, required this.total});

  @override
  Widget build(BuildContext context) => FmCard(
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text('By Category', style: TextStyle(fontFamily: 'DM Sans', 
          color: AppColors.textPrimary, fontWeight: FontWeight.w700, fontSize: 16)),
      const SizedBox(height: 16),
      ...sorted.asMap().entries.map((e) {
        final c = _pc(e.key);
        final pct = total > 0 ? e.value.value / total : 0.0;
        return Padding(
          padding: const EdgeInsets.only(bottom: 14),
          child: Column(children: [
            Row(children: [
              Container(width: 32, height: 32,
                decoration: BoxDecoration(color: c.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(9)),
                child: Center(child: Container(width: 9, height: 9,
                    decoration: BoxDecoration(color: c, shape: BoxShape.circle)))),
              const SizedBox(width: 10),
              Expanded(child: Text(e.value.key, style: TextStyle(fontFamily: 'DM Sans', 
                  color: AppColors.textPrimary, fontSize: 13, fontWeight: FontWeight.w500))),
              Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                Text(CurrencyFormatter.formatCompact(e.value.value), style: TextStyle(fontFamily: 'DM Sans', 
                    color: c, fontWeight: FontWeight.w700, fontSize: 13)),
                Text('${(pct * 100).toStringAsFixed(0)}%',
                    style: TextStyle(fontFamily: 'DM Sans', color: AppColors.textMuted, fontSize: 10)),
              ]),
            ]),
            const SizedBox(height: 8),
            TweenAnimationBuilder<double>(
              tween: Tween(begin: 0, end: pct),
              duration: const Duration(milliseconds: 900),
              curve: Curves.easeOutCubic,
              builder: (_, v, __) => Stack(children: [
                Container(height: 6, decoration: BoxDecoration(
                    color: AppColors.cream300, borderRadius: BorderRadius.circular(6))),
                FractionallySizedBox(widthFactor: v, child: Container(
                  height: 6,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(colors: [c.withValues(alpha: 0.6), c]),
                    borderRadius: BorderRadius.circular(6),
                    boxShadow: [BoxShadow(color: c.withValues(alpha: 0.4), blurRadius: 6, spreadRadius: 0)],
                  ),
                )),
              ]),
            ),
          ]),
        );
      }),
    ]),
  );
}

// ── Bar Chart ─────────────────────────────────────────────────
class _BarChart extends StatelessWidget {
  final List<({String label, double income, double expense})> bars;
  const _BarChart({required this.bars});

  BarChartRodData _rod(double y, Color c) => BarChartRodData(
    toY: y, width: 10,
    borderRadius: const BorderRadius.vertical(top: Radius.circular(5)),
    gradient: LinearGradient(colors: [c.withValues(alpha: 0.5), c],
        begin: Alignment.bottomCenter, end: Alignment.topCenter),
  );

  @override
  Widget build(BuildContext context) {
    final maxY = bars.fold(0.0,
        (m, b) => [m, b.income, b.expense].reduce((a, c) => a > c ? a : c));
    final topY = maxY < 1000 ? 1000.0 : maxY * 1.2;
    return FmCard(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [
        Text('6-Month Trend', style: TextStyle(fontFamily: 'DM Sans', 
            color: AppColors.textPrimary, fontWeight: FontWeight.w700, fontSize: 16)),
        const Spacer(),
        _dot(AppColors.income, 'In'), const SizedBox(width: 12), _dot(AppColors.expense, 'Out'),
      ]),
      const SizedBox(height: 18),
      SizedBox(height: 200, child: BarChart(BarChartData(
        maxY: topY,
        gridData: FlGridData(show: true, drawVerticalLine: false,
            getDrawingHorizontalLine: (_) =>
                FlLine(color: AppColors.border, strokeWidth: 0.5)),
        borderData: FlBorderData(show: false),
        titlesData: FlTitlesData(
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          bottomTitles: AxisTitles(sideTitles: SideTitles(showTitles: true, reservedSize: 24,
              getTitlesWidget: (v, _) => Padding(padding: const EdgeInsets.only(top: 6),
                child: Text(bars[v.toInt()].label,
                    style: TextStyle(fontFamily: 'DM Sans', color: AppColors.textMuted, fontSize: 10))))),
          leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: true, reservedSize: 42,
              getTitlesWidget: (v, _) => Text(CurrencyFormatter.formatCompact(v),
                  style: TextStyle(fontFamily: 'DM Sans', color: AppColors.textMuted, fontSize: 9)))),
        ),
        barGroups: bars.asMap().entries.map((e) => BarChartGroupData(
            x: e.key, barsSpace: 4, barRods: [
          _rod(e.value.income, AppColors.income),
          _rod(e.value.expense, AppColors.expense),
        ])).toList(),
        barTouchData: BarTouchData(touchTooltipData: BarTouchTooltipData(
          getTooltipColor: (_) => AppColors.surfaceElevated,
          tooltipRoundedRadius: 10,
          getTooltipItem: (g, _, rod, ri) => BarTooltipItem(
            '${ri == 0 ? "In" : "Out"}\n${CurrencyFormatter.formatCompact(rod.toY)}',
            TextStyle(fontFamily: 'DM Sans', 
                color: ri == 0 ? AppColors.income : AppColors.expense,
                fontWeight: FontWeight.w700, fontSize: 11)),
        )),
      ))),
    ]));
  }
}

// ── Insights ──────────────────────────────────────────────────
class _Insights extends StatelessWidget {
  final List<TransactionModel> transactions;
  const _Insights({required this.transactions});

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final monthly = <String, double>{};
    for (final t in transactions) {
      if (!t.isExpense) continue;
      final k = '${t.date.year}-${t.date.month.toString().padLeft(2, '0')}';
      monthly[k] = (monthly[k] ?? 0) + t.amount;
    }
    final best = monthly.isEmpty
        ? null : monthly.entries.reduce((a, b) => a.value < b.value ? a : b);
    final thisM = transactions.where((t) =>
        t.isExpense && t.date.year == now.year && t.date.month == now.month)
        .fold(0.0, (s, t) => s + t.amount);
    final lastM = transactions.where((t) =>
        t.isExpense && t.date.year == now.year && t.date.month == now.month - 1)
        .fold(0.0, (s, t) => s + t.amount);
    final delta = lastM > 0 ? (thisM - lastM) / lastM * 100 : 0.0;

    // Top spending weekday
    final weekdayTotals = List<double>.filled(7, 0);
    for (final t in transactions) {
      if (t.isExpense) weekdayTotals[t.date.weekday % 7] += t.amount;
    }
    final maxDay = weekdayTotals.indexOf(weekdayTotals.reduce((a, b) => a > b ? a : b));
    const days = ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'];

    return FmCard(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [
        Text('Insights', style: TextStyle(fontFamily: 'DM Sans', 
            color: AppColors.textPrimary, fontWeight: FontWeight.w700, fontSize: 16)),
        const SizedBox(width: 8),
        _chip('Auto', AppColors.accent),
      ]),
      const SizedBox(height: 14),
      if (lastM > 0) _InsightRow(
        icon: delta <= 0 ? Icons.trending_down_rounded : Icons.trending_up_rounded,
        color: delta <= 0 ? AppColors.income : AppColors.expense,
        text: delta <= 0
            ? 'Spent ${delta.abs().toStringAsFixed(0)}% less than last month 🎉'
            : 'Spent ${delta.toStringAsFixed(0)}% more than last month',
      ),
      if (weekdayTotals.any((v) => v > 0)) ...[
        const SizedBox(height: 10),
        _InsightRow(
          icon: Icons.calendar_today_rounded,
          color: AppColors.info,
          text: '${days[maxDay]}s are your biggest spending day',
        ),
        const SizedBox(height: 12),
        _WeekdayBar(totals: weekdayTotals),
      ],
      if (best != null) ...[
        const SizedBox(height: 10),
        _InsightRow(icon: Icons.emoji_events_rounded, color: AppColors.warning,
            text: 'Best month: ${best.key} — ${CurrencyFormatter.formatCompact(best.value)}'),
      ],
      if (transactions.isEmpty)
        Text('Log more transactions to see insights',
            style: TextStyle(fontFamily: 'DM Sans', color: AppColors.textMuted, fontSize: 13)),
    ]));
  }
}

// ── Weekday Spending Mini-Bar ─────────────────────────────────
class _WeekdayBar extends StatelessWidget {
  final List<double> totals;
  const _WeekdayBar({required this.totals});
  @override
  Widget build(BuildContext context) {
    const days = ['S', 'M', 'T', 'W', 'T', 'F', 'S'];
    final maxVal = totals.reduce((a, b) => a > b ? a : b);
    final peakIdx = totals.indexOf(maxVal);
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: List.generate(7, (i) {
        final pct = maxVal > 0 ? totals[i] / maxVal : 0.0;
        final isPeak = i == peakIdx;
        final c = isPeak ? AppColors.info : AppColors.textMuted.withValues(alpha: 0.3);
        return Column(mainAxisSize: MainAxisSize.min, children: [
          TweenAnimationBuilder<double>(
            tween: Tween(begin: 0, end: pct),
            duration: Duration(milliseconds: 600 + i * 60),
            curve: Curves.easeOutCubic,
            builder: (_, v, __) => Container(
              width: 26, height: (36 * v).clamp(4.0, 36.0),
              decoration: BoxDecoration(
                color: c,
                borderRadius: BorderRadius.circular(4),
                boxShadow: isPeak
                    ? [BoxShadow(color: AppColors.info.withValues(alpha: 0.3), blurRadius: 6)]
                    : null,
              ),
            ),
          ),
          const SizedBox(height: 4),
          Text(days[i], style: TextStyle(fontFamily: 'DM Sans', 
              color: isPeak ? AppColors.info : AppColors.textMuted, fontSize: 10,
              fontWeight: isPeak ? FontWeight.w700 : FontWeight.w400)),
        ]);
      }),
    );
  }
}

class _InsightRow extends StatelessWidget {
  final IconData icon; final Color color; final String text;
  const _InsightRow({required this.icon, required this.color, required this.text});
  @override
  Widget build(BuildContext context) => Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
    Container(padding: const EdgeInsets.all(7),
      decoration: BoxDecoration(color: color.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(10)),
      child: Icon(icon, color: color, size: 15)),
    const SizedBox(width: 12),
    Expanded(child: Padding(padding: const EdgeInsets.only(top: 3),
      child: Text(text, style: TextStyle(fontFamily: 'DM Sans', 
          color: AppColors.textSecondary, fontSize: 13, height: 1.4)))),
  ]);
}

// ── No Data ───────────────────────────────────────────────────
class _NoData extends StatelessWidget {
  const _NoData();
  @override
  Widget build(BuildContext context) => Center(child: Padding(
    padding: const EdgeInsets.all(48),
    child: Column(children: [
      Container(width: 68, height: 68,
        decoration: BoxDecoration(color: AppColors.primary.withValues(alpha: 0.08),
            shape: BoxShape.circle,
            border: Border.all(color: AppColors.primary.withValues(alpha: 0.15), width: 1.5)),
        child: const Center(child: Text('📊', style: TextStyle(fontSize: 30)))),
      const SizedBox(height: 14),
      Text('No expenses yet', style: TextStyle(fontFamily: 'DM Sans', 
          color: AppColors.textPrimary, fontWeight: FontWeight.w600, fontSize: 15)),
      const SizedBox(height: 5),
      Text('Add transactions to see your breakdown', textAlign: TextAlign.center,
          style: TextStyle(fontFamily: 'DM Sans', color: AppColors.textMuted, fontSize: 12)),
    ]),
  ));
}

// ── Micro helpers ─────────────────────────────────────────────
Widget _chip(String text, Color color) => Container(
  padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
  decoration: BoxDecoration(color: color.withValues(alpha: 0.1),
      borderRadius: BorderRadius.circular(20)),
  child: Text(text, style: TextStyle(fontFamily: 'DM Sans', 
      color: color, fontSize: 11, fontWeight: FontWeight.w600)),
);

Widget _dot(Color color, String label) => Row(children: [
  Container(width: 8, height: 8, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
  const SizedBox(width: 5),
  Text(label, style: TextStyle(fontFamily: 'DM Sans', color: AppColors.textMuted, fontSize: 11)),
]);