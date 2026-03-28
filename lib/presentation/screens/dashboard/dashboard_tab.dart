import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/di/service_locator.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../core/utils/date_formatter.dart';
import '../../../data/models/transaction_model.dart';
import '../../../data/models/user_model.dart';
import '../../../data/repositories/i_budget_repository.dart';
import '../../../data/models/budget_model.dart';
import '../../blocs/auth/auth_bloc.dart';
import '../../blocs/auth/auth_event.dart';
import '../../blocs/transaction/transaction_bloc.dart';
import '../../blocs/transaction/transaction_state.dart';
import '../../widgets/charts/velocity_card.dart';
import '../../widgets/charts/budget_bar.dart';
import 'package:finmann/shared/widgets/amount_badge.dart';
import '../transactions/add_transaction_sheet.dart';
import '../transactions/nlp_input_sheet.dart';

class DashboardTab extends StatefulWidget {
  final UserModel user;
  const DashboardTab({super.key, required this.user});

  @override
  State<DashboardTab> createState() => _DashboardTabState();
}

class _DashboardTabState extends State<DashboardTab> {
  List<BudgetModel> _budgets = [];
  final _budgetRepo = sl<IBudgetRepository>();

  @override
  void initState() { super.initState(); _loadBudgets(); }

  Future<void> _loadBudgets() async {
    final now = DateTime.now();
    final b = await _budgetRepo.getForMonth(widget.user.id, now.year, now.month);
    if (mounted) setState(() => _budgets = b);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: BlocBuilder<TransactionBloc, TransactionState>(
        builder: (context, state) {
          final now = DateTime.now();
          final allTxns = state is TransactionLoaded ? state.transactions : <TransactionModel>[];
          final monthTxns = allTxns.where(
            (t) => t.date.year == now.year && t.date.month == now.month).toList();
          final totalIncome = monthTxns.where((t) => t.isIncome).fold(0.0, (s, t) => s + t.amount);
          final totalExpense = monthTxns.where((t) => t.isExpense).fold(0.0, (s, t) => s + t.amount);
          final balance = state is TransactionLoaded ? state.balance : 0.0;
          final recent = allTxns.take(5).toList();

          return CustomScrollView(
            slivers: [
              _SliverAppBar(user: widget.user),
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                sliver: SliverList(delegate: SliverChildListDelegate([
                  const SizedBox(height: 8),
                  // Balance hero — slower, smoother entry with tighter vertical travel
                  _BalanceHero(
                    balance: balance,
                    income: totalIncome,
                    expense: totalExpense,
                    userName: widget.user.name.split(' ').first,
                  ).animate().fadeIn(duration: 500.ms, curve: Curves.easeOutQuart)
                   .slideY(begin: 0.03, curve: Curves.easeOutQuart),
                  const SizedBox(height: 16),
                  // Quick actions — slight upward reveal added for consistency
                  _QuickActions(userId: widget.user.id)
                    .animate()
                    .fadeIn(delay: 100.ms, duration: 400.ms)
                    .slideY(begin: 0.03, curve: Curves.easeOutCubic),
                  const SizedBox(height: 20),
                  // Velocity — nudged delay to sit after quick actions settle
                  if (monthTxns.isNotEmpty)
                    VelocityCard(
                      spent: totalExpense,
                      income: totalIncome,
                      daysInMonth: DateTime(now.year, now.month + 1, 0).day,
                      dayOfMonth: now.day,
                    ).animate()
                     .fadeIn(delay: 160.ms, duration: 420.ms)
                     .slideY(begin: 0.03, curve: Curves.easeOutCubic),
                  if (monthTxns.isNotEmpty) const SizedBox(height: 16),
                  // Budgets
                  if (_budgets.isNotEmpty) ...[
                    _SectionHeader(
                      title: 'Budgets',
                      action: 'Manage',
                      onAction: () => _showBudgetManager(context, monthTxns),
                    ).animate().fadeIn(delay: 220.ms, duration: 380.ms),
                    const SizedBox(height: 10),
                    ..._budgets.take(3).map((b) {
                      final spent = monthTxns.where((t) => t.isExpense && t.category == b.category)
                          .fold(0.0, (s, t) => s + t.amount);
                      // Snappier horizontal slide, tighter travel distance
                      return BudgetBar(budget: b, spent: spent)
                          .animate()
                          .fadeIn(delay: 260.ms, duration: 350.ms)
                          .slideX(begin: 0.03, curve: Curves.easeOutCubic);
                    }),
                    const SizedBox(height: 8),
                  ],
                  // Set budget CTA if none
                  if (_budgets.isEmpty) ...[
                    _SetBudgetCta(onTap: () => _showBudgetManager(context, monthTxns))
                        .animate().fadeIn(delay: 220.ms, duration: 380.ms),
                    const SizedBox(height: 16),
                  ],
                  // Recent transactions
                  _SectionHeader(
                    title: 'Recent',
                    action: recent.isEmpty ? null : null,
                  ).animate().fadeIn(delay: 280.ms, duration: 360.ms),
                  const SizedBox(height: 10),
                  if (recent.isEmpty)
                    const _EmptyState().animate().fadeIn(delay: 320.ms, duration: 400.ms)
                  else
                    // Longer base delay + 60 ms per-item stagger with easeOutCubic
                    ...recent.asMap().entries.map((e) =>
                      _TxTile(tx: e.value)
                        .animate()
                        .fadeIn(
                          delay: Duration(milliseconds: 300 + e.key * 60),
                          duration: 300.ms,
                          curve: Curves.easeOutCubic,
                        )
                        .slideX(begin: 0.03, curve: Curves.easeOutCubic)
                    ),
                  const SizedBox(height: 100),
                ])),
              ),
            ],
          );
        },
      ),
      floatingActionButton: _Fab(userId: widget.user.id),
    );
  }

  void _showBudgetManager(BuildContext context, List<TransactionModel> monthTxns) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
      builder: (_) => _BudgetManagerSheet(
        userId: widget.user.id,
        budgets: _budgets,
        monthTxns: monthTxns,
        repo: _budgetRepo,
        onSaved: () { Navigator.pop(context); _loadBudgets(); },
      ),
    );
  }
}

class _SliverAppBar extends StatelessWidget {
  final UserModel user;
  const _SliverAppBar({required this.user});

  @override
  Widget build(BuildContext context) {
    return SliverAppBar(
      floating: true,
      backgroundColor: AppColors.cream100,
      title: Row(children: [
        Container(
          width: 34, height: 34,
          decoration: BoxDecoration(
            color: AppColors.primary,
            borderRadius: BorderRadius.circular(AppRadius.md),
          ),
          child: const Icon(Icons.account_balance_wallet_rounded, color: Colors.white, size: 17),
        ),
        const SizedBox(width: 10),
        const Text('FinMann',
          style: TextStyle(color: AppColors.textPrimary, fontSize: 20, fontWeight: FontWeight.w800)),
      ]),
      actions: [
        PopupMenuButton(
          icon: CircleAvatar(
            backgroundColor: AppColors.surfaceElevated,
            radius: 17,
            child: Text(user.name[0].toUpperCase(),
              style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.w800, fontSize: 14)),
          ),
          color: AppColors.surfaceElevated,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          itemBuilder: (_) => <PopupMenuEntry<dynamic>>[
            PopupMenuItem(
              child: Text('Hi, ${user.name.split(' ').first}',
                style: const TextStyle(color: AppColors.textSecondary, fontSize: 13)),
              enabled: false,
            ),
            const PopupMenuDivider(),
            PopupMenuItem(
              child: const Row(children: [
                Icon(Icons.logout_rounded, color: AppColors.expense, size: 18),
                SizedBox(width: 10),
                Text('Sign Out', style: TextStyle(color: AppColors.expense)),
              ]),
              onTap: () => context.read<AuthBloc>().add(LogoutRequested()),
            ),
          ],
        ),
        const SizedBox(width: 8),
      ],
    );
  }
}

class _BalanceHero extends StatelessWidget {
  final double balance;
  final double income;
  final double expense;
  final String userName;
  const _BalanceHero({required this.balance, required this.income, required this.expense, required this.userName});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.primaryDark,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.2)),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Text('Good ${_greeting()}, $userName 👋',
            style: const TextStyle(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.w500)),
          const Spacer(),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(AppRadius.pill),
            ),
            child: Text(DateFormatter.formatMonth(DateTime.now()),
              style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w600)),
          ),
        ]),
        const SizedBox(height: 12),
        const Text('Total Balance', style: TextStyle(color: Colors.white60, fontSize: 12)),
        const SizedBox(height: 6),
        TweenAnimationBuilder<double>(
          tween: Tween(begin: 0, end: balance),
          duration: const Duration(milliseconds: 900),
          curve: Curves.easeOutCubic,
          builder: (_, v, __) => Text(
            CurrencyFormatter.format(v),
            style: AppTypography.hero.copyWith(
              color: Colors.white,
              fontSize: 38,
            ),
          ),
        ),
        const SizedBox(height: 20),
        const Divider(color: Colors.white24, height: 1),
        const SizedBox(height: 16),
        Row(children: [
          Expanded(child: _MiniStat(label: 'Income', amount: income, isIncome: true)),
          Container(width: 1, height: 32, color: Colors.white24),
          Expanded(child: _MiniStat(label: 'Expense', amount: expense, isIncome: false)),
        ]),
      ]),
    );
  }

  String _greeting() {
    final h = DateTime.now().hour;
    if (h < 12) return 'Morning';
    if (h < 17) return 'Afternoon';
    return 'Evening';
  }
}

class _MiniStat extends StatelessWidget {
  final String label;
  final double amount;
  final bool isIncome;
  const _MiniStat({required this.label, required this.amount, required this.isIncome});

  @override
  Widget build(BuildContext context) {
    return Row(mainAxisAlignment: MainAxisAlignment.center, children: [
      Container(
        width: 28, height: 28,
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(AppRadius.sm),
        ),
        child: Icon(
          isIncome ? Icons.arrow_downward_rounded : Icons.arrow_upward_rounded,
          color: Colors.white, size: 14,
        ),
      ),
      const SizedBox(width: 10),
      Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(label, style: const TextStyle(color: Colors.white70, fontSize: 11)),
        Text(CurrencyFormatter.formatCompact(amount),
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 14)),
      ]),
    ]);
  }
}

class _QuickActions extends StatelessWidget {
  final String userId;
  const _QuickActions({required this.userId});

  @override
  Widget build(BuildContext context) {
    return Row(children: [
      Expanded(child: _QBtn(
        label: 'Add Expense',
        icon: Icons.arrow_upward_rounded,
        color: AppColors.expense,
        onTap: () => showAddTransactionSheet(context, userId: userId),
      )),
      const SizedBox(width: 10),
      Expanded(child: _QBtn(
        label: 'Quick Add',
        icon: Icons.auto_awesome_rounded,
        color: AppColors.accent,
        onTap: () => showNlpSheet(context, userId: userId),
      )),
    ]);
  }
}

class _QBtn extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;
  const _QBtn({required this.label, required this.icon, required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(AppRadius.lg),
          border: Border.all(color: color.withValues(alpha: 0.25)),
        ),
        child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          Icon(icon, color: color, size: 18),
          const SizedBox(width: 8),
          Text(label, style: TextStyle(color: color, fontWeight: FontWeight.w700, fontSize: 13)),
        ]),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  final String? action;
  final VoidCallback? onAction;
  const _SectionHeader({required this.title, this.action, this.onAction});

  @override
  Widget build(BuildContext context) {
    return Row(children: [
      Text(title, style: Theme.of(context).textTheme.titleLarge),
      const Spacer(),
      if (action != null)
        TextButton(onPressed: onAction, child: Text(action!)),
    ]);
  }
}

class _TxTile extends StatelessWidget {
  final TransactionModel tx;
  const _TxTile({required this.tx});

  Color _getCategoryColor(String category) {
    if (category == 'Food & Dining') return AppColors.expense;
    if (category == 'Transport') return AppColors.info;
    if (category == 'Shopping') return AppColors.warning;
    if (category == 'Entertainment') return AppColors.accent;
    return AppColors.primaryLight;
  }

  @override
  Widget build(BuildContext context) {
    final emoji = AppConstants.categoryIcons[tx.category] ?? '💸';
    final dotColor = _getCategoryColor(tx.category);
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(children: [
        Container(
          width: 42, height: 42,
          decoration: BoxDecoration(color: dotColor.withValues(alpha: 0.15), shape: BoxShape.circle),
          child: Center(child: Text(emoji, style: const TextStyle(fontSize: 19))),
        ),
        const SizedBox(width: 12),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(tx.category,
            style: const TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w600, fontSize: 13)),
          if (tx.description != null && tx.description!.isNotEmpty)
            Text(tx.description!,
              style: const TextStyle(color: AppColors.textMuted, fontSize: 11),
              maxLines: 1, overflow: TextOverflow.ellipsis),
        ])),
        Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
          AmountBadge(amount: tx.amount, type: tx.type),
          const SizedBox(height: 2),
          Text(DateFormatter.smartFormat(tx.date),
            style: const TextStyle(color: AppColors.textMuted, fontSize: 10)),
        ]),
      ]),
    );
  }
}

class _SetBudgetCta extends StatelessWidget {
  final VoidCallback onTap;
  const _SetBudgetCta({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.primary.withValues(alpha: 0.06),
          borderRadius: BorderRadius.circular(AppRadius.lg),
          border: Border.all(color: AppColors.primary.withValues(alpha: 0.2), style: BorderStyle.solid),
        ),
        child: Row(children: [
          const Icon(Icons.account_balance_wallet_outlined, color: AppColors.primary, size: 22),
          const SizedBox(width: 12),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text('Set monthly budgets', style: TextStyle(
              color: AppColors.textPrimary, fontWeight: FontWeight.w600, fontSize: 14)),
            const Text('Get alerts before you overspend',
              style: TextStyle(color: AppColors.textMuted, fontSize: 12)),
          ])),
          const Icon(Icons.chevron_right_rounded, color: AppColors.primary),
        ]),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(32),
      child: Column(children: [
        // Added 100 ms delay before the elastic spring so it doesn't fire mid-fade
        const Text('💸', style: TextStyle(fontSize: 40))
          .animate()
          .scale(delay: 100.ms, duration: 600.ms, curve: Curves.elasticOut),
        const SizedBox(height: 12),
        Text('No transactions yet', style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 4),
        const Text('Tap Quick Add or + to log your first entry',
          style: TextStyle(color: AppColors.textMuted, fontSize: 13), textAlign: TextAlign.center),
      ]),
    );
  }
}

class _Fab extends StatelessWidget {
  final String userId;
  const _Fab({required this.userId});

  @override
  Widget build(BuildContext context) {
    return FloatingActionButton(
      onPressed: () => showAddTransactionSheet(context, userId: userId),
      backgroundColor: AppColors.primary,
      foregroundColor: AppColors.cream100,
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.lg)),
      child: const Icon(Icons.add_rounded, size: 26),
    );
  }
}

// ─── Budget manager bottom sheet ─────────────────────────────
class _BudgetManagerSheet extends StatefulWidget {
  final String userId;
  final List<BudgetModel> budgets;
  final List<TransactionModel> monthTxns;
  final IBudgetRepository repo;
  final VoidCallback onSaved;

  const _BudgetManagerSheet({
    required this.userId, required this.budgets, required this.monthTxns,
    required this.repo, required this.onSaved,
  });

  @override
  State<_BudgetManagerSheet> createState() => _BudgetManagerSheetState();
}

class _BudgetManagerSheetState extends State<_BudgetManagerSheet> {
  late Map<String, TextEditingController> _ctrls;

  @override
  void initState() {
    super.initState();
    _ctrls = { for (final c in AppConstants.expenseCategories)
      c: TextEditingController(text: widget.budgets
        .where((b) => b.category == c)
        .map((b) => b.limitAmount.toStringAsFixed(0))
        .firstOrNull ?? '')
    };
  }

  @override
  void dispose() { for (final c in _ctrls.values) c.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom + 16,
        left: 20, right: 20, top: 20),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Center(child: Container(width: 40, height: 4,
          decoration: BoxDecoration(color: AppColors.border, borderRadius: BorderRadius.circular(2)))),
        const SizedBox(height: 16),
        Text('Monthly Budgets', style: Theme.of(context).textTheme.headlineLarge),
        const SizedBox(height: 4),
        Text('Set limits per category for ${DateFormatter.formatMonth(now)}',
          style: const TextStyle(color: AppColors.textMuted, fontSize: 13)),
        const SizedBox(height: 20),
        SizedBox(
          height: 340,
          child: ListView(children: AppConstants.expenseCategories.map((cat) {
            final emoji = AppConstants.categoryIcons[cat] ?? '📦';
            final spent = widget.monthTxns.where((t) => t.isExpense && t.category == cat)
                .fold(0.0, (s, t) => s + t.amount);
            return Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Row(children: [
                Text(emoji, style: const TextStyle(fontSize: 18)),
                const SizedBox(width: 10),
                Expanded(child: Text(cat,
                  style: const TextStyle(color: AppColors.textPrimary, fontSize: 13))),
                if (spent > 0)
                  Text(CurrencyFormatter.formatCompact(spent),
                    style: const TextStyle(color: AppColors.textMuted, fontSize: 12)),
                const SizedBox(width: 8),
                SizedBox(
                  width: 90,
                  height: 38,
                  child: TextField(
                    controller: _ctrls[cat],
                    keyboardType: TextInputType.number,
                    style: const TextStyle(color: AppColors.textPrimary, fontSize: 13),
                    decoration: InputDecoration(
                      hintText: '₹ limit',
                      hintStyle: const TextStyle(color: AppColors.textMuted, fontSize: 12),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                      filled: true, fillColor: AppColors.cream300,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10),
                        borderSide: const BorderSide(color: AppColors.border)),
                      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10),
                        borderSide: const BorderSide(color: AppColors.border)),
                      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10),
                        borderSide: const BorderSide(color: AppColors.primary)),
                    ),
                  ),
                ),
              ]),
            );
          }).toList()),
        ),
        const SizedBox(height: 16),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: () async {
              for (final entry in _ctrls.entries) {
                final val = double.tryParse(entry.value.text);
                if (val != null && val > 0) {
                  await widget.repo.upsert(
                    userId: widget.userId, category: entry.key,
                    limitAmount: val, month: now.month, year: now.year);
                }
              }
              widget.onSaved();
            },
            child: const Text('Save Budgets'),
          ),
        ),
      ]),
    );
  }
}