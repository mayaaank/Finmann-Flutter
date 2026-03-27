import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/currency_formatter.dart';

class VelocityCard extends StatelessWidget {
  final double spent;
  final double income;
  final int daysInMonth;
  final int dayOfMonth;

  const VelocityCard({
    super.key,
    required this.spent,
    required this.income,
    required this.daysInMonth,
    required this.dayOfMonth,
  });

  @override
  Widget build(BuildContext context) {
    final daysLeft = daysInMonth - dayOfMonth;
    final dailyRate = dayOfMonth > 0 ? spent / dayOfMonth : 0.0;
    final projected = dailyRate * daysInMonth;
    final overBudget = income > 0 && projected > income;
    final overBy = projected - income;

    final pctUsed = income > 0 ? (spent / income).clamp(0.0, 1.0) : 0.0;
    final statusColor = pctUsed < 0.6
        ? AppColors.primary
        : pctUsed < 0.85
            ? AppColors.warning
            : AppColors.expense;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: statusColor.withOpacity(0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(Icons.speed_rounded, color: statusColor, size: 18),
            ),
            const SizedBox(width: 10),
            Text('Spending Velocity',
              style: Theme.of(context).textTheme.titleLarge),
            const Spacer(),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: statusColor.withOpacity(0.12),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                '${(pctUsed * 100).toStringAsFixed(0)}%',
                style: TextStyle(color: statusColor, fontSize: 12, fontWeight: FontWeight.w700),
              ),
            ),
          ]),
          const SizedBox(height: 16),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: pctUsed,
              backgroundColor: AppColors.bg700,
              valueColor: AlwaysStoppedAnimation(statusColor),
              minHeight: 8,
            ),
          ),
          const SizedBox(height: 12),
          Row(children: [
            _Stat(label: 'Daily burn', value: CurrencyFormatter.format(dailyRate), color: statusColor),
            const SizedBox(width: 16),
            _Stat(label: 'Days left', value: '$daysLeft days'),
            const SizedBox(width: 16),
            _Stat(label: 'Projected', value: CurrencyFormatter.formatCompact(projected)),
          ]),
          if (overBudget) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: AppColors.expenseSurface,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppColors.expense.withOpacity(0.3)),
              ),
              child: Row(children: [
                const Icon(Icons.warning_amber_rounded, color: AppColors.expense, size: 16),
                const SizedBox(width: 8),
                Expanded(child: Text(
                  'At this rate, you\'ll overspend by ${CurrencyFormatter.format(overBy)}',
                  style: const TextStyle(color: AppColors.expense, fontSize: 12),
                )),
              ]),
            ).animate().shake(duration: 400.ms, delay: 600.ms),
          ],
        ],
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  final String label;
  final String value;
  final Color? color;
  const _Stat({required this.label, required this.value, this.color});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(value, style: TextStyle(
          color: color ?? AppColors.textPrimary,
          fontWeight: FontWeight.w700, fontSize: 13,
        )),
        Text(label, style: const TextStyle(color: AppColors.textMuted, fontSize: 11)),
      ],
    );
  }
}
