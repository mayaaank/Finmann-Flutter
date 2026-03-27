import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../data/repositories/auth_repository.dart';
import 'auth_event.dart';
import 'auth_state.dart';

class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final AuthRepository _repo;

  AuthBloc(this._repo) : super(AuthInitial()) {
    on<LoginRequested>(_onLogin);
    on<RegisterRequested>(_onRegister);
    on<LogoutRequested>(_onLogout);
  }

  Future<void> _onLogin(LoginRequested e, Emitter<AuthState> emit) async {
    emit(AuthLoading());
    try {
      final user = await _repo.login(email: e.email, password: e.password);
      emit(Authenticated(user));
    } catch (err) {
      emit(AuthError(err.toString().replaceFirst('Exception: ', '')));
    }
  }

  Future<void> _onRegister(RegisterRequested e, Emitter<AuthState> emit) async {
    emit(AuthLoading());
    try {
      final user = await _repo.register(
        email: e.email,
        password: e.password,
        name: e.name,
      );
      emit(Authenticated(user));
    } catch (err) {
      emit(AuthError(err.toString().replaceFirst('Exception: ', '')));
    }
  }

  void _onLogout(LogoutRequested e, Emitter<AuthState> emit) {
    emit(AuthInitial());
  }
}
