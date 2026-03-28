import 'package:get_it/get_it.dart';
import '../../data/repositories/auth_repository.dart';
import '../../data/repositories/i_transaction_repository.dart';
import '../../data/repositories/transaction_repository.dart';
import '../../data/repositories/i_budget_repository.dart';
import '../../data/repositories/budget_repository.dart';
import '../../data/repositories/i_goal_repository.dart';
import '../../data/repositories/goal_repository.dart';
import '../../presentation/blocs/auth/auth_bloc.dart';
import '../../presentation/blocs/transaction/transaction_bloc.dart';
import '../../presentation/blocs/analytics/analytics_bloc.dart';
import '../../presentation/blocs/budget/budget_bloc.dart';
import '../../presentation/blocs/goal/goal_bloc.dart';

final sl = GetIt.instance;

void setupLocator() {
  sl.registerLazySingleton(() => AuthRepository());
  sl.registerLazySingleton<ITransactionRepository>(() => TransactionRepository());
  sl.registerLazySingleton<IBudgetRepository>(() => BudgetRepository());
  sl.registerLazySingleton<IGoalRepository>(() => GoalRepository());

  sl.registerFactory(() => AuthBloc(sl<AuthRepository>()));
  sl.registerFactory(() => TransactionBloc(sl<ITransactionRepository>()));
  sl.registerFactory(() => AnalyticsBloc(sl<ITransactionRepository>()));
  sl.registerFactory(() => BudgetBloc(sl<IBudgetRepository>()));
  sl.registerFactory(() => GoalBloc(sl<IGoalRepository>()));
}
