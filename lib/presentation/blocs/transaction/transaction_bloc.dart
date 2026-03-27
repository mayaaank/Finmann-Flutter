import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../data/repositories/transaction_repository.dart';
import 'transaction_event.dart';
import 'transaction_state.dart';

class TransactionBloc extends Bloc<TransactionEvent, TransactionState> {
  final TransactionRepository _repo;

  TransactionBloc(this._repo) : super(TransactionInitial()) {
    on<LoadTransactions>(_onLoad);
    on<AddTransaction>(_onAdd);
    on<EditTransaction>(_onEdit);
    on<DeleteTransaction>(_onDelete);
  }

  List<String> _userIds = [];

  Future<void> _onLoad(LoadTransactions e, Emitter<TransactionState> emit) async {
    emit(TransactionLoading());
    _userIds = [e.userId];
    try {
      final txns = await _repo.getAll(e.userId);
      emit(TransactionLoaded(txns));
    } catch (err) {
      emit(TransactionError(err.toString()));
    }
  }

  Future<void> _onAdd(AddTransaction e, Emitter<TransactionState> emit) async {
    try {
      await _repo.add(
        userId: e.userId,
        type: e.type,
        amount: e.amount,
        category: e.category,
        description: e.description,
        date: e.date,
      );
      if (_userIds.isNotEmpty) add(LoadTransactions(_userIds.first));
    } catch (err) {
      emit(TransactionError(err.toString()));
    }
  }

  Future<void> _onEdit(EditTransaction e, Emitter<TransactionState> emit) async {
    try {
      await _repo.update(e.transaction);
      if (_userIds.isNotEmpty) add(LoadTransactions(_userIds.first));
    } catch (err) {
      emit(TransactionError(err.toString()));
    }
  }

  Future<void> _onDelete(DeleteTransaction e, Emitter<TransactionState> emit) async {
    try {
      await _repo.delete(e.id);
      if (_userIds.isNotEmpty) add(LoadTransactions(_userIds.first));
    } catch (err) {
      emit(TransactionError(err.toString()));
    }
  }
}
