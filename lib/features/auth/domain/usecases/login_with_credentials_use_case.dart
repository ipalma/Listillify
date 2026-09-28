import 'package:equatable/equatable.dart';
import 'package:listillify/core/errors/failures.dart';
import 'package:listillify/core/result/result.dart';
import 'package:listillify/core/usecases/usecase.dart';
import 'package:listillify/features/auth/domain/entities/user_session.dart';
import 'package:listillify/features/auth/domain/repositories/auth_repository.dart';

/// PATRÓN DE DISEÑO: Command / Use Case (Clean Architecture / SOLID S)
/// Parámetros requeridos para iniciar sesión con credenciales de usuario y contraseña.
class LoginWithCredentialsParams extends Equatable {
  final String username;
  final String password;

  const LoginWithCredentialsParams({
    required this.username,
    required this.password,
  });

  @override
  List<Object?> get props => [username, password];
}

/// Caso de uso para autenticación directa con usuario y contraseña.
/// Valida que los campos no estén vacíos antes de delegar en el repositorio.
class LoginWithCredentialsUseCase implements UseCase<UserSession, LoginWithCredentialsParams> {
  final AuthRepository repository;

  LoginWithCredentialsUseCase(this.repository);

  @override
  Future<Result<UserSession>> call(LoginWithCredentialsParams params) async {
    final username = params.username.trim();
    final password = params.password.trim();

    if (username.isEmpty || password.isEmpty) {
      return const FailureResult(
        ValidationFailure(message: 'El usuario y la contraseña no pueden estar vacíos.'),
      );
    }

    return await repository.loginWithCredentials(
      username: username,
      password: password,
    );
  }
}
