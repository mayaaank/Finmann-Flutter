// lib/presentation/screens/transactions/transactions_tab.dart
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
  String? _filterType;

  List<TransactionModel> _filtered(List<TransactionModel> all) {
    if (_filterType == 'income') return all.where((t) => t.isIncome).toList();
    if (_filterType == 'expense') return all.where((t) => t.isExpense).toList();
    return all;
  }

  Map<String, List<TransactionModel>> _groupByDate(
      List<TransactionModel> txns) {
    final map = <String, List<TransactionModel>>{};
    for (final t in txns) {
      final key = DateFormatter.smartFormat(t.date);
      map.putIfAbsent(key, () => []).add(t);
    }
    return map;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg900,
      body: BlocBuilder<TransactionBloc, TransactionState>(
        builder: (context, state) {
          if (state is TransactionLoading) {
            return const Center(
                child: CircularProgressIndicator(color: AppColors.primary));
          }

          if (state is TransactionLoaded) {
            final all = state.transactions;
            final txns = _filtered(all);
            final grouped = _groupByDate(txns);
            final dateKeys = grouped.keys.toList();

            final totalIncome = all
                .where((t) => t.isIncome)
                .fold(0.0, (s, t) => s + t.amount);
            final totalExpense = all
                .where((t) => t.isExpense)
                .fold(0.0, (s, t) => s + t.amount);

            return CustomScrollView(
              slivers: [
                // ── Sliver App Bar ──────────────────────────────────
                SliverAppBar(
                  pinned: true,
                  expandedHeight: 196,
                  backgroundColor: AppColors.bg900,
                  elevation: 0,
                  flexibleSpace: FlexibleSpaceBar(
                    collapseMode: CollapseMode.pin,
                    background: SafeArea(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Title + Add button
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text('Transactions',
                                        style: Theme.of(context)
                                            .textTheme
                                            .headlineLarge
                                            ?.copyWith(fontSize: 24)),
                                    const SizedBox(height: 2),
                                    Text('${all.length} records',
                                        style: const TextStyle(
                                            color: AppColors.textMuted,
                                            fontSize: 12)),
                                  ],
                                ),
                                GestureDetector(
                                  onTap: () => showAddTransactionSheet(context,
                                      userId: widget.user.id),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 14, vertical: 9),
                                    decoration: BoxDecoration(
                                      gradient: const LinearGradient(colors: [
                                        AppColors.primary,
                                        AppColors.accent,
                                      ]),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: const Row(children: [
                                      Icon(Icons.add_rounded,
                                          color: AppColors.bg900, size: 16),
                                      SizedBox(width: 5),
                                      Text('Add',
                                          style: TextStyle(
                                              color: AppColors.bg900,
                                              fontWeight: FontWeight.w700,
                                              fontSize: 13)),
                                    ]),
                                  ),
                                ),
                              ],
                            ),

                            const SizedBox(height: 16),

                            // ── Income / Expense summary cards ────
                            Row(children: [
                              _SummaryCard(
                                label: 'Income',
                                amount: totalIncome,
                                icon: Icons.arrow_downward_rounded,
                                color: AppColors.income,
                              ),
                              const SizedBox(width: 10),
                              _SummaryCard(
                                label: 'Expense',
                                amount: totalExpense,
                                icon: Icons.arrow_upward_rounded,
                                color: AppColors.expense,
                              ),
                            ]),
                          ],
                        ),
                      ),
                    ),
                  ),

                  // ── Filter bar pinned below collapsed app bar ─────
                  bottom: PreferredSize(
                    preferredSize: const Size.fromHeight(48),
                    child: Container(
                      color: AppColors.bg900,
                      padding: const EdgeInsets.fromLTRB(16, 4, 16, 10),
                      child: Row(children: [
                        _FilterChip(
                          label: 'All',
                          selected: _filterType == null,
                          onTap: () => setState(() => _filterType = null),
                        ),
                        const SizedBox(width: 8),
                        _FilterChip(
                          label: 'Income',
                          selected: _filterType == 'income',
                          color: AppColors.income,
                          onTap: () => setState(() => _filterType = 'income'),
                        ),
                        const SizedBox(width: 8),
                        _FilterChip(
                          label: 'Expense',
                          selected: _filterType == 'expense',
                          color: AppColors.expense,
                          onTap: () => setState(() => _filterType = 'expense'),
                        ),
                      ]),
                    ),
                  ),
                ),

                // ── Grouped transaction list ─────────────────────────
                if (txns.isEmpty)
                  const SliverFillRemaining(child: _EmptyState())
                else
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(16, 4, 16, 100),
                    sliver: SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (context, i) {
                          final key = dateKeys[i];
                          final rows = grouped[key]!;
                          return _DateSection(
                            label: key,
                            transactions: rows,
                            userId: widget.user.id,
                          ).animate().fadeIn(
                              delay: Duration(milliseconds: i * 50));
                        },
                        childCount: dateKeys.length,
                      ),
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

// ── Summary Card ─────────────────────────────────────────────────────────────

class _SummaryCard extends StatelessWidget {
  final String label;
  final double amount;
  final IconData icon;
  final Color color;

  const _SummaryCard({
    required this.label,
    required this.amount,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: color.withOpacity(0.08),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: color.withOpacity(0.2)),
        ),
        child: Row(children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: color.withOpacity(0.15),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: color, size: 14),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label,
                      style: TextStyle(
                          color: color,
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.4)),
                  const SizedBox(height: 2),
                  Text(CurrencyFormatter.format(amount),
                      style: const TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 14,
                          fontWeight: FontWeight.w800),
                      overflow: TextOverflow.ellipsis),
                ]),
          ),
        ]),
      ),
    );
  }
}

// ── Filter Chip ───────────────────────────────────────────────────────────────

class _FilterChip extends StatelessWidget {
  final String label;
  final bool selected;
  final Color? color;
  final VoidCallback onTap;

  const _FilterChip({
    required this.label,
    required this.selected,
    this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final c = color ?? AppColors.primary;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        decoration: BoxDecoration(
          color: selected ? c.withOpacity(0.12) : AppColors.bg800,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: selected ? c : AppColors.border),
        ),
        child: Text(label,
            style: TextStyle(
                color: selected ? c : AppColors.textMuted,
                fontSize: 12,
                fontWeight: FontWeight.w700)),
      ),
    );
  }
}

// ── Date Section ──────────────────────────────────────────────────────────────

class _DateSection extends StatelessWidget {
  final String label;
  final List<TransactionModel> transactions;
  final String userId;

  const _DateSection({
    required this.label,
    required this.transactions,
    required this.userId,
  });

  @override
  Widget build(BuildContext context) {
    final net = transactions.fold(
        0.0, (s, t) => s + (t.isIncome ? t.amount : -t.amount));

    return Padding(
      padding: const EdgeInsets.only(top: 20),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        // Date label + day net amount
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Text(label.toUpperCase(),
              style: const TextStyle(
                  color: AppColors.textMuted,
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.0)),
          Text(
            '${net >= 0 ? '+' : ''}${CurrencyFormatter.format(net)}',
            style: TextStyle(
                color: net >= 0 ? AppColors.income : AppColors.expense,
                fontSize: 11,
                fontWeight: FontWeight.w700),
          ),
        ]),

        const SizedBox(height: 8),

        // Grouped card
        Container(
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.border),
          ),
          child: Column(
            children: List.generate(transactions.length, (i) {
              final tx = transactions[i];
              final isLast = i == transactions.length - 1;
              return Column(children: [
                _TxRow(tx: tx, userId: userId),
                if (!isLast)
                  const Divider(
                      height: 1,
                      thickness: 1,
                      color: AppColors.border,
                      indent: 64,
                      endIndent: 0),
              ]);
            }),
          ),
        ),
      ]),
    );
  }
}

// ── Transaction Row ───────────────────────────────────────────────────────────

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
        decoration: BoxDecoration(
          color: AppColors.expense.withOpacity(0.12),
          borderRadius: BorderRadius.circular(16),
        ),
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        child:
            const Icon(Icons.delete_outline_rounded, color: AppColors.expense),
      ),
      confirmDismiss: (_) async => await showDialog<bool>(
        context: context,
        builder: (_) => AlertDialog(
          backgroundColor: AppColors.surfaceElevated,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
          title: const Text('Delete Transaction'),
          content: const Text('This cannot be undone.'),
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
      ),
      onDismissed: (_) =>
          context.read<TransactionBloc>().add(DeleteTransaction(tx.id)),
      child: GestureDetector(
        onTap: () =>
            showAddTransactionSheet(context, userId: userId, existing: tx),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
          child: Row(children: [
            // Emoji avatar
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: AppColors.bg700,
                borderRadius: BorderRadius.circular(13),
              ),
              child: Center(
                  child:
                      Text(emoji, style: const TextStyle(fontSize: 20))),
            ),
            const SizedBox(width: 12),

            // Category + note
            Expanded(
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(tx.category,
                        style: const TextStyle(
                            color: AppColors.textPrimary,
                            fontWeight: FontWeight.w600,
                            fontSize: 14)),
                    if (tx.description != null &&
                        tx.description!.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(tx.description!,
                          style: const TextStyle(
                              color: AppColors.textMuted, fontSize: 12),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis),
                    ],
                  ]),
            ),

            // Amount badge
            AmountBadge(amount: tx.amount, type: tx.type),
          ]),
        ),
      ),
    );
  }
}

// ── Empty State ───────────────────────────────────────────────────────────────

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: AppColors.bg800,
            shape: BoxShape.circle,
            border: Border.all(color: AppColors.border),
          ),
          child: const Text('🔍', style: TextStyle(fontSize: 36)),
        ),
        const SizedBox(height: 16),
        const Text('No transactions found',
            style: TextStyle(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w600,
                fontSize: 15)),
        const SizedBox(height: 6),
        const Text('Try a different filter',
            style: TextStyle(color: AppColors.textMuted, fontSize: 13)),
      ]),
    );
  }
}