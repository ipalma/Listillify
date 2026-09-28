import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:listillify/core/usecases/usecase.dart';
import 'package:listillify/features/auth/domain/usecases/get_current_session_use_case.dart';
import 'package:listillify/features/auth/domain/usecases/login_use_case.dart';
import 'package:listillify/features/auth/domain/usecases/logout_use_case.dart';
import 'package:listillify/features/auth/presentation/cubit/auth_state.dart';

/// PATRÓN DE DISEÑO: Observer / Presentation Controller (BLoC / Cubit)
/// Administra el ciclo de vida del estado de autenticación (verificar sesión, login con Spotify, logout).
class AuthCubit extends Cubit<AuthState> {
  final LoginUseCase loginUseCase;
  final GetCurrentSessionUseCase getCurrentSessionUseCase;
  final LogoutUseCase logoutUseCase;

  AuthCubit({
    required this.loginUseCase,
    required this.getCurrentSessionUseCase,
    required this.logoutUseCase,
  }) : super(const AuthInitial());

  /// Comprueba si existe una sesión previa persistida en el dispositivo.
  Future<void> checkAuthStatus() async {
    emit(const AuthLoading(message: 'Verificando sesión...'));
    final result = await getCurrentSessionUseCase(const NoParams());

    result.when(
      onSuccess: (session) {
        if (session != null && session.isAuthenticated) {
          emit(Authenticated(session));
        } else {
          emit(const Unauthenticated());
        }
      },
      onFailure: (failure) => emit(AuthError(failure.message)),
    );
  }

  /// Inicia el flujo de autenticación con el [clientId] proporcionado.
  Future<void> login(String clientId) async {
    emit(const AuthLoading(message: 'Abriendo Spotify para iniciar sesión...'));
    final result = await loginUseCase(LoginParams(clientId: clientId));

    result.when(
      onSuccess: (session) => emit(Authenticated(session)),
      onFailure: (failure) => emit(AuthError(failure.message)),
    );
  }

  /// Cierra la sesión activa del usuario.
  Future<void> logout() async {
    emit(const AuthLoading(message: 'Cerrando sesión...'));
    final result = await logoutUseCase(const NoParams());

    result.when(
      onSuccess: (_) => emit(const Unauthenticated()),
      onFailure: (failure) => emit(AuthError(failure.message)),
    );
  }
}
