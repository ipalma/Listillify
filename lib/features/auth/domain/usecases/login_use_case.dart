import 'package:equatable/equatable.dart';
import 'package:listillify/core/errors/failures.dart';
import 'package:listillify/core/result/result.dart';
import 'package:listillify/core/usecases/usecase.dart';
import 'package:listillify/features/auth/domain/entities/user_session.dart';
import 'package:listillify/features/auth/domain/repositories/auth_repository.dart';

/// Parámetros de entrada para el caso de uso [LoginUseCase].
class LoginParams extends Equatable {
  final String clientId;

  const LoginParams({required this.clientId});

  @override
  List<Object?> get props => [clientId];
}

/// PATRÓN DE DISEÑO: Command Pattern / Use Case Interactor
/// Caso de uso responsable de autenticar al usuario con Spotify.
/// Principio de Responsabilidad Única (SOLID S).
class LoginUseCase implements UseCase<UserSession, LoginParams> {
  final AuthRepository repository;

  LoginUseCase(this.repository);

  @override
  Future<Result<UserSession>> call(LoginParams params) async {
    if (params.clientId.trim().isEmpty) {
      return const FailureResult(
        ValidationFailure(message: 'El Client ID es requerido para iniciar sesión en Spotify.'),
      );
    }

    return await repository.login(params.clientId.trim());
  }
}
