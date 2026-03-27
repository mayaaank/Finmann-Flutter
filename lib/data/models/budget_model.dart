import 'package:equatable/equatable.dart';

class BudgetModel extends Equatable {
  final String id;
  final String userId;
  final String category;
  final double limitAmount;
  final int month;
  final int year;

  const BudgetModel({
    required this.id,
    required this.userId,
    required this.category,
    required this.limitAmount,
    required this.month,
    required this.year,
  });

  factory BudgetModel.fromMap(Map<String, dynamic> m) => BudgetModel(
    id: m['id'], userId: m['user_id'], category: m['category'],
    limitAmount: (m['limit_amount'] as num).toDouble(),
    month: m['month'], year: m['year'],
  );

  Map<String, dynamic> toMap() => {
    'id': id, 'user_id': userId, 'category': category,
    'limit_amount': limitAmount, 'month': month, 'year': year,
  };

  @override
  List<Object?> get props => [id, userId, category, month, year];
}
