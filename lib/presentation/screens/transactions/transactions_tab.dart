import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../core/utils/date_formatter.dart';
import '../../../data/models/transaction_model.dart';
import '../../../data/models/user_model.dart';
import '../../blocs/transaction/transaction_bloc.dart';
import '../../blocs/transaction/transaction_event.dart';
import '../../blocs/transaction/transaction_state.dart';
import '../../widgets/common/amount_badge.dart';
import 'add_transaction_sheet.dart';

class TransactionsTab extends StatefulWidget {
  final UserModel user;
  const TransactionsTab({super.key, required this.user});

  @override
  State<TransactionsTab> createState() => _TransactionsTabState();
}

class _TransactionsTabState extends State<TransactionsTab> {
  String? _filterType; // 'income' | 'expense' | null
  String? _filterCategory;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Transactions'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_rounded),
            onPressed: () =>
                showAddTransactionSheet(context, userId: widget.user.id),
          ),
        ],
      ),
      body: BlocBuilder<TransactionBloc, TransactionState>(
        builder: (context, state) {
          if (state is TransactionLoading) {
            return const Center(
                child: CircularProgressIndicator(color: AppColors.primary));
          }
          if (state is TransactionLoaded) {
            var txns = state.transactions;

            if (_filterType == 'income') {
              txns = txns.where((t) => t.isIncome).toList();
            } else if (_filterType == 'expense') {
              txns = txns.where((t) => t.isExpense).toList();
            }
            if (_filterCategory != null) {
              txns = txns.where((t) => t.category == _filterCategory).toList();
            }

            return Column(
              children: [
                _FilterBar(
                  filterType: _filterType,
                  onTypeChanged: (t) => setState(() => _filterType = t),
                ),
                Expanded(
                  child: txns.isEmpty
                      ? const _EmptyFiltered()
                      : ListView.builder(
                          padding: const EdgeInsets.fromLTRB(16, 4, 16, 80),
                          itemCount: txns.length,
                          itemBuilder: (context, i) =>
                              _TxRow(tx: txns[i], userId: widget.user.id)
                                  .animate()
                                  .fadeIn(delay: Duration(milliseconds: i * 30)),
                        ),
                ),
              ],
            );
          }
          return const SizedBox.shrink();
        },
      ),
    );
  }
}

class _FilterBar extends StatelessWidget {
  final String? filterType;
  final ValueChanged<String?> onTypeChanged;
  const _FilterBar({required this.filterType, required this.onTypeChanged});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          _Chip(
              label: 'All',
              selected: filterType == null,
              onTap: () => onTypeChanged(null)),
          const SizedBox(width: 8),
          _Chip(
              label: 'Income',
              selected: filterType == 'income',
              color: AppColors.income,
              onTap: () => onTypeChanged('income')),
          const SizedBox(width: 8),
          _Chip(
              label: 'Expense',
              selected: filterType == 'expense',
              color: AppColors.expense,
              onTap: () => onTypeChanged('expense')),
        ],
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  final String label;
  final bool selected;
  final Color? color;
  final VoidCallback onTap;
  const _Chip(
      {required this.label,
      required this.selected,
      this.color,
      required this.onTap});

  @override
  Widget build(BuildContext context) {
    final c = color ?? AppColors.primary;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          color: selected ? c.withOpacity(0.15) : AppColors.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
              color: selected ? c : AppColors.border),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: selected ? c : AppColors.textMuted,
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}

class _TxRow extends StatelessWidget {
  final TransactionModel tx;
  final String userId;
  const _TxRow({required this.tx, required this.userId});

  @override
  Widget build(BuildContext context) {
    final emoji = AppConstants.categoryIcons[tx.category] ?? '💸';
    return Dismissible(
      key: Key(tx.id),
      direction: DismissDirection.endToStart,
      background: Container(
        margin: const EdgeInsets.only(bottom: 8),
        decoration: BoxDecoration(
          color: AppColors.expense.withOpacity(0.2),
          borderRadius: BorderRadius.circular(14),
        ),
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        child: const Icon(Icons.delete_outline_rounded, color: AppColors.expense),
      ),
      confirmDismiss: (_) async {
        return await showDialog<bool>(
          context: context,
          builder: (_) => AlertDialog(
            backgroundColor: AppColors.surfaceElevated,
            title: const Text('Delete Transaction'),
            content: const Text('Are you sure you want to delete this?'),
            actions: [
              TextButton(
                  onPressed: () => Navigator.pop(context, false),
                  child: const Text('Cancel')),
              TextButton(
                  onPressed: () => Navigator.pop(context, true),
                  child: const Text('Delete',
                      style: TextStyle(color: AppColors.expense))),
            ],
          ),
        );
      },
      onDismissed: (_) {
        context.read<TransactionBloc>().add(DeleteTransaction(tx.id));
      },
      child: GestureDetector(
        onTap: () =>
            showAddTransactionSheet(context, userId: userId, existing: tx),
        child: Container(
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.border),
          ),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: AppColors.bg700,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Center(
                    child:
                        Text(emoji, style: const TextStyle(fontSize: 20))),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(tx.category,
                        style: const TextStyle(
                            color: AppColors.textPrimary,
                            fontWeight: FontWeight.w600,
                            fontSize: 14)),
                    if (tx.description != null && tx.description!.isNotEmpty)
                      Text(tx.description!,
                          style: const TextStyle(
                              color: AppColors.textMuted, fontSize: 12),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis),
                    Text(DateFormatter.smartFormat(tx.date),
                        style: const TextStyle(
                            color: AppColors.textMuted, fontSize: 11)),
                  ],
                ),
              ),
              AmountBadge(amount: tx.amount, type: tx.type),
            ],
          ),
        ),
      ),
    );
  }
}

class _EmptyFiltered extends StatelessWidget {
  const _EmptyFiltered();
  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text('🔍', style: TextStyle(fontSize: 40)),
          SizedBox(height: 12),
          Text('No transactions found',
              style: TextStyle(color: AppColors.textMuted)),
        ],
      ),
    );
  }
}
