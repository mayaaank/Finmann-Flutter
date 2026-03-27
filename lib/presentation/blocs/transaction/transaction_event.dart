import 'package:equatable/equatable.dart';
import '../../../data/models/transaction_model.dart';

abstract class TransactionEvent extends Equatable {
  const TransactionEvent();
  @override
  List<Object?> get props => [];
}

class LoadTransactions extends TransactionEvent {
  final String userId;
  const LoadTransactions(this.userId);
  @override
  List<Object?> get props => [userId];
}

class AddTransaction extends TransactionEvent {
  final String userId;
  final TransactionType type;
  final double amount;
  final String category;
  final String? description;
  final DateTime date;

  const AddTransaction({
    required this.userId,
    required this.type,
    required this.amount,
    required this.category,
    this.description,
    required this.date,
  });

  @override
  List<Object?> get props => [userId, type, amount, category, date];
}

class EditTransaction extends TransactionEvent {
  final TransactionModel transaction;
  const EditTransaction(this.transaction);
  @override
  List<Object?> get props => [transaction];
}

class DeleteTransaction extends TransactionEvent {
  final String id;
  const DeleteTransaction(this.id);
  @override
  List<Object?> get props => [id];
}
