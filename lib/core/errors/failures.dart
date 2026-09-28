import 'package:equatable/equatable.dart';

/// PATRÓN DE DISEÑO: Value Object / Domain Error Hierarchy
/// Representa la abstracción base para todos los fallos y errores del dominio.
/// Al heredar de Equatable, permite comparar fallos por valor en los tests unitarios.
abstract class Failure extends Equatable {
  final String message;
  final int? statusCode;

  const Failure({
    required this.message,
    this.statusCode,
  });

  @override
  List<Object?> get props => [message, statusCode];
}

/// Fallo derivado de problemas en llamadas a servicios externos o servidores (HTTP 5xx, timeouts, etc.).
class ServerFailure extends Failure {
  const ServerFailure({
    required super.message,
    super.statusCode,
  });
}

/// Fallo relacionado con la autenticación o expiración de tokens en la API de Spotify.
class AuthFailure extends Failure {
  const AuthFailure({
    required super.message,
    super.statusCode,
  });
}

/// Fallo producido cuando se supera la cuota o tasa de peticiones permitidas (HTTP 429 Too Many Requests).
class RateLimitFailure extends Failure {
  final int retryAfterSeconds;

  const RateLimitFailure({
    required super.message,
    required this.retryAfterSeconds,
    super.statusCode = 429,
  });

  @override
  List<Object?> get props => [message, statusCode, retryAfterSeconds];
}

/// Fallo originado por datos de entrada inválidos proporcionados por el usuario.
class ValidationFailure extends Failure {
  const ValidationFailure({
    required super.message,
    super.statusCode,
  });
}

/// Fallo derivado de operaciones en el almacenamiento seguro local.
class StorageFailure extends Failure {
  const StorageFailure({
    required super.message,
    super.statusCode,
  });
}
