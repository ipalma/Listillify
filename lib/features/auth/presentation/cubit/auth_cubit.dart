import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:listillify/core/usecases/usecase.dart';
import 'package:listillify/features/auth/domain/usecases/get_current_session_use_case.dart';
import 'package:listillify/features/auth/domain/usecases/login_use_case.dart';
import 'package:listillify/features/auth/domain/usecases/logout_use_case.dart';
import 'package:listillify/features/auth/domain/usecases/login_with_credentials_use_case.dart';
import 'package:listillify/features/auth/presentation/cubit/auth_state.dart';

/// PATRÓN DE DISEÑO: Observer / Presentation Controller (BLoC / Cubit)
/// Administra el ciclo de vida del estado de autenticación (verificar sesión, login con Spotify, login con usuario/contraseña, logout).
class AuthCubit extends Cubit<AuthState> {
  final LoginUseCase loginUseCase;
  final LoginWithCredentialsUseCase? loginWithCredentialsUseCase;
  final GetCurrentSessionUseCase getCurrentSessionUseCase;
  final LogoutUseCase logoutUseCase;

  AuthCubit({
    required this.loginUseCase,
    this.loginWithCredentialsUseCase,
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

  /// Inicia sesión con credenciales directas de usuario y contraseña (guardadas en Hive).
  Future<void> loginWithCredentials({
    required String username,
    required String password,
  }) async {
    emit(const AuthLoading(message: 'Iniciando sesión con usuario y contraseña...'));
    if (loginWithCredentialsUseCase == null) {
      emit(const AuthError('Caso de uso de login con credenciales no disponible.'));
      return;
    }

    final result = await loginWithCredentialsUseCase!(
      LoginWithCredentialsParams(username: username, password: password),
    );

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
