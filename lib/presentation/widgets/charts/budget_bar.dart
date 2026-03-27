import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../data/models/budget_model.dart';
import '../../../core/constants/app_constants.dart';

class BudgetBar extends StatelessWidget {
  final BudgetModel budget;
  final double spent;
  final VoidCallback? onTap;

  const BudgetBar({super.key, required this.budget, required this.spent, this.onTap});

  @override
  Widget build(BuildContext context) {
    final pct = (spent / budget.limitAmount).clamp(0.0, 1.0);
    final over = spent > budget.limitAmount;
    final color = pct < 0.7 ? AppColors.primary : pct < 0.9 ? AppColors.warning : AppColors.expense;
    final emoji = AppConstants.categoryIcons[budget.category] ?? '📦';

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        margin: const EdgeInsets.only(bottom: 10),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: over ? AppColors.expense.withOpacity(0.4) : AppColors.border),
        ),
        child: Column(children: [
          Row(children: [
            Text(emoji, style: const TextStyle(fontSize: 18)),
            const SizedBox(width: 10),
            Expanded(child: Text(budget.category,
              style: const TextStyle(color: AppColors.textPrimary,
                fontWeight: FontWeight.w600, fontSize: 14))),
            Text(
              '${CurrencyFormatter.formatCompact(spent)} / ${CurrencyFormatter.formatCompact(budget.limitAmount)}',
              style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.w700),
            ),
          ]),
          const SizedBox(height: 10),
          TweenAnimationBuilder<double>(
            tween: Tween(begin: 0, end: pct),
            duration: const Duration(milliseconds: 900),
            curve: Curves.easeOutCubic,
            builder: (_, v, __) => ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: v, backgroundColor: AppColors.bg700,
                valueColor: AlwaysStoppedAnimation(color), minHeight: 7,
              ),
            ),
          ),
          if (over) ...[
            const SizedBox(height: 6),
            Row(children: [
              const Icon(Icons.warning_amber_rounded, color: AppColors.expense, size: 13),
              const SizedBox(width: 4),
              Text(
                'Over by ${CurrencyFormatter.format(spent - budget.limitAmount)}',
                style: const TextStyle(color: AppColors.expense, fontSize: 11),
              ),
            ]),
          ],
        ]),
      ),
    );
  }
}
