//C:\Users\dev\Finmann-Flutter\lib\presentation\screens\transactions\nlp_input_sheet.dart
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/nlp_parser.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../data/models/transaction_model.dart';
import '../../blocs/transaction/transaction_bloc.dart';
import '../../blocs/transaction/transaction_event.dart';

void showNlpSheet(BuildContext context, {required String userId}) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: AppColors.bg800,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
    builder: (_) => BlocProvider.value(
      value: context.read<TransactionBloc>(),
      child: NlpInputSheet(userId: userId),
    ),
  );
}

class NlpInputSheet extends StatefulWidget {
  final String userId;
  const NlpInputSheet({super.key, required this.userId});

  @override
  State<NlpInputSheet> createState() => _NlpInputSheetState();
}

class _NlpInputSheetState extends State<NlpInputSheet> {
  final _ctrl = TextEditingController();
  NlpResult? _preview;
  bool _confirmed = false;

  static const _examples = [
    'spent 200 on food at mess',
    'bought books for 350',
    'received 5000 allowance',
    'paid 120 for Swiggy',
    'uber 80 yesterday',
  ];

  void _parse(String val) {
    setState(() => _preview = NlpParser.parse(val));
  }

  void _submit() {
    if (_preview == null || _preview!.amount == null) return;
    context.read<TransactionBloc>().add(AddTransaction(
      userId: widget.userId,
      type: _preview!.type,
      amount: _preview!.amount!,
      category: _preview!.category ??
          (_preview!.type == TransactionType.expense ? 'Other' : 'Other'),
      description: _preview!.description,
      date: _preview!.date,
    ));
    setState(() => _confirmed = true);
    Future.delayed(const Duration(milliseconds: 800), () => Navigator.pop(context));
  }

  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
        left: 20, right: 20, top: 20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 40, height: 4,
              decoration: BoxDecoration(color: AppColors.border, borderRadius: BorderRadius.circular(2)),
            ),
          ),
          const SizedBox(height: 20),
          Row(children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                gradient: const LinearGradient(colors: [AppColors.primary, AppColors.accent]),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.auto_awesome_rounded, color: AppColors.bg900, size: 18),
            ),
            const SizedBox(width: 10),
            Text('Quick Add', style: Theme.of(context).textTheme.headlineLarge),
          ]),
          const SizedBox(height: 6),
          const Text('Describe your transaction in plain English',
            style: TextStyle(color: AppColors.textMuted, fontSize: 13)),
          const SizedBox(height: 20),
          // Input field
          Container(
            decoration: BoxDecoration(
              color: AppColors.bg700,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: _preview != null ? AppColors.primary : AppColors.border),
            ),
            child: TextField(
              controller: _ctrl,
              autofocus: true,
              onChanged: _parse,
              style: const TextStyle(color: AppColors.textPrimary, fontSize: 15),
              decoration: InputDecoration(
                hintText: 'e.g. "spent 200 on food"',
                hintStyle: const TextStyle(color: AppColors.textMuted),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.all(16),
                suffixIcon: _ctrl.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear, color: AppColors.textMuted, size: 18),
                        onPressed: () { _ctrl.clear(); setState(() => _preview = null); },
                      )
                    : null,
              ),
            ),
          ),
          // Examples
          if (_preview == null) ...[
            const SizedBox(height: 16),
            Wrap(
              spacing: 8, runSpacing: 8,
              children: _examples.map((e) => GestureDetector(
                onTap: () { _ctrl.text = e; _parse(e); },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                  decoration: BoxDecoration(
                    color: AppColors.bg600,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Text(e, style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                ),
              )).toList(),
            ),
          ],
          // Preview card
          if (_preview != null) ...[
            const SizedBox(height: 16),
            _PreviewCard(result: _preview!, confirmed: _confirmed)
              .animate().fadeIn(duration: 200.ms).slideY(begin: 0.1),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: (_preview!.amount != null && !_confirmed) ? _submit : null,
                icon: _confirmed
                    ? const Icon(Icons.check_circle_rounded, size: 18)
                    : const Icon(Icons.add_rounded, size: 18),
                label: Text(_confirmed ? 'Added!' : 'Add Transaction'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _confirmed ? AppColors.primaryDark : AppColors.primary,
                  foregroundColor: AppColors.bg900,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
              ),
            ),
          ],
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}

class _PreviewCard extends StatelessWidget {
  final NlpResult result;
  final bool confirmed;
  const _PreviewCard({required this.result, required this.confirmed});

  @override
  Widget build(BuildContext context) {
    final isIncome = result.type == TransactionType.income;
    final color = isIncome ? AppColors.income : AppColors.expense;
    final emoji = result.category != null
        ? (AppConstants.categoryIcons[result.category!] ?? '💸')
        : '💸';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(children: [
        Text(emoji, style: const TextStyle(fontSize: 28)),
        const SizedBox(width: 12),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  isIncome ? 'Income' : 'Expense',
                  style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.w700),
                ),
              ),
              if (result.category != null) ...[
                const SizedBox(width: 6),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: AppColors.bg700,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(result.category!,
                    style: const TextStyle(color: AppColors.textSecondary, fontSize: 11)),
                ),
              ],
            ]),
            const SizedBox(height: 4),
            if (result.description != null && result.description!.isNotEmpty)
              Text(result.description!,
                style: const TextStyle(color: AppColors.textMuted, fontSize: 12)),
          ]),
        ),
        Text(
          result.amount != null
              ? '${isIncome ? '+' : '-'}${CurrencyFormatter.format(result.amount!)}'
              : '— amount not detected',
          style: TextStyle(color: color, fontWeight: FontWeight.w800, fontSize: 15),
        ),
      ]),
    );
  }
}
