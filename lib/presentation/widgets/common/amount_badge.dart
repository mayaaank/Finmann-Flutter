import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../data/models/transaction_model.dart';

class AmountBadge extends StatelessWidget {
  final double amount;
  final TransactionType type;

  const AmountBadge({super.key, required this.amount, required this.type});

  @override
  Widget build(BuildContext context) {
    final isIncome = type == TransactionType.income;
    return Text(
      '${isIncome ? '+' : '-'} ${CurrencyFormatter.format(amount)}',
      style: TextStyle(
        color: isIncome ? AppColors.income : AppColors.expense,
        fontWeight: FontWeight.w700,
        fontSize: 14,
      ),
    );
  }
}
