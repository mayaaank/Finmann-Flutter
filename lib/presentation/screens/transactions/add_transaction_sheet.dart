//lib\presentation\screens\transactions\add_transaction_sheet.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_theme.dart';
import '../../../data/models/transaction_model.dart';
import '../../blocs/transaction/transaction_bloc.dart';
import '../../blocs/transaction/transaction_event.dart';
import '../../widgets/common/fm_button.dart';
import '../../widgets/common/fm_text_field.dart';

void showAddTransactionSheet(BuildContext context,
    {required String userId, TransactionModel? existing}) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: AppColors.bg800,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (_) => BlocProvider.value(
      value: context.read<TransactionBloc>(),
      child: AddTransactionSheet(userId: userId, existing: existing),
    ),
  );
}

class AddTransactionSheet extends StatefulWidget {
  final String userId;
  final TransactionModel? existing;

  const AddTransactionSheet({super.key, required this.userId, this.existing});

  @override
  State<AddTransactionSheet> createState() => _AddTransactionSheetState();
}

class _AddTransactionSheetState extends State<AddTransactionSheet> {
  final _form = GlobalKey<FormState>();
  final _amountCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  final _dateCtrl = TextEditingController();

  TransactionType _type = TransactionType.expense;
  String? _selectedCategory;
  DateTime _selectedDate = DateTime.now();

  List<String> get _categories => _type == TransactionType.expense
      ? AppConstants.expenseCategories
      : AppConstants.incomeCategories;

  @override
  void initState() {
    super.initState();
    if (widget.existing != null) {
      final e = widget.existing!;
      _type = e.type;
      _amountCtrl.text = e.amount.toString();
      _descCtrl.text = e.description ?? '';
      _selectedCategory = e.category;
      _selectedDate = e.date;
    }
    _dateCtrl.text = DateFormat('dd MMM yyyy').format(_selectedDate);
  }

  @override
  void dispose() {
    _amountCtrl.dispose();
    _descCtrl.dispose();
    _dateCtrl.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_form.currentState!.validate()) return;
    if (_selectedCategory == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Please select a category'),
            backgroundColor: AppColors.expense),
      );
      return;
    }
    final amount = double.parse(_amountCtrl.text.trim());

    if (widget.existing != null) {
      context.read<TransactionBloc>().add(
            EditTransaction(widget.existing!.copyWith(
              type: _type,
              amount: amount,
              category: _selectedCategory,
              description:
                  _descCtrl.text.trim().isEmpty ? null : _descCtrl.text.trim(),
              date: _selectedDate,
            )),
          );
    } else {
      context.read<TransactionBloc>().add(AddTransaction(
            userId: widget.userId,
            type: _type,
            amount: amount,
            category: _selectedCategory!,
            description:
                _descCtrl.text.trim().isEmpty ? null : _descCtrl.text.trim(),
            date: _selectedDate,
          ));
    }

    Navigator.pop(context);
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: const ColorScheme.dark(
            primary: AppColors.primary,
            onPrimary: AppColors.bg900,
            surface: AppColors.surface,
          ),
        ),
        child: child!,
      ),
    );
    if (picked != null) {
      setState(() {
        _selectedDate = picked;
        _dateCtrl.text = DateFormat('dd MMM yyyy').format(picked);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.existing != null;
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
        left: 20,
        right: 20,
        top: 20,
      ),
      child: Form(
        key: _form,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Handle
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.border,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Text(isEditing ? 'Edit Transaction' : 'Add Transaction',
                style: Theme.of(context).textTheme.headlineLarge),
            const SizedBox(height: 20),
            // Type toggle
            Container(
              decoration: BoxDecoration(
                color: AppColors.bg700,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  _TypeTab(
                    label: 'Expense',
                    icon: Icons.arrow_upward_rounded,
                    isSelected: _type == TransactionType.expense,
                    color: AppColors.expense,
                    onTap: () => setState(() {
                      _type = TransactionType.expense;
                      _selectedCategory = null;
                    }),
                  ),
                  _TypeTab(
                    label: 'Income',
                    icon: Icons.arrow_downward_rounded,
                    isSelected: _type == TransactionType.income,
                    color: AppColors.income,
                    onTap: () => setState(() {
                      _type = TransactionType.income;
                      _selectedCategory = null;
                    }),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            // Amount
            FmTextField(
              label: 'Amount (₹)',
              hint: '0.00',
              controller: _amountCtrl,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              prefixIcon: Icons.currency_rupee_rounded,
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,2}'))
              ],
              validator: (v) {
                if (v == null || v.trim().isEmpty) return 'Enter amount';
                final d = double.tryParse(v);
                if (d == null || d <= 0) return 'Enter a valid amount';
                return null;
              },
            ),
            const SizedBox(height: 16),
            // Category
            DropdownButtonFormField<String>(
              value: _selectedCategory,
              hint: const Text('Select Category'),
              dropdownColor: AppColors.surfaceElevated,
              style: const TextStyle(color: AppColors.textPrimary),
              decoration: InputDecoration(
                filled: true,
                fillColor: AppColors.bg700,
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: AppColors.border),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: AppColors.border),
                ),
                prefixIcon: const Icon(Icons.category_outlined,
                    color: AppColors.textMuted, size: 20),
              ),
              items: _categories
                  .map((c) => DropdownMenuItem(
                        value: c,
                        child: Row(
                          children: [
                            Text(AppConstants.categoryIcons[c] ?? '📦',
                                style: const TextStyle(fontSize: 16)),
                            const SizedBox(width: 8),
                            Text(c),
                          ],
                        ),
                      ))
                  .toList(),
              onChanged: (v) => setState(() => _selectedCategory = v),
            ),
            const SizedBox(height: 16),
            // Date
            FmTextField(
              label: 'Date',
              controller: _dateCtrl,
              prefixIcon: Icons.calendar_today_outlined,
              readOnly: true,
              onTap: _pickDate,
            ),
            const SizedBox(height: 16),
            // Description
            FmTextField(
              label: 'Note (optional)',
              hint: 'e.g. College canteen lunch',
              controller: _descCtrl,
              prefixIcon: Icons.notes_rounded,
              maxLines: 2,
            ),
            const SizedBox(height: 24),
            FmButton(
              label: isEditing ? 'Save Changes' : 'Add Transaction',
              icon: isEditing ? Icons.save_rounded : Icons.add_rounded,
              onPressed: _submit,
            ),
          ],
        ),
      ),
    );
  }
}

class _TypeTab extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool isSelected;
  final Color color;
  final VoidCallback onTap;

  const _TypeTab({
    required this.label,
    required this.icon,
    required this.isSelected,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isSelected ? color.withOpacity(0.15) : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
            border: isSelected ? Border.all(color: color.withOpacity(0.4)) : null,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: isSelected ? color : AppColors.textMuted, size: 16),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  color: isSelected ? color : AppColors.textMuted,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
