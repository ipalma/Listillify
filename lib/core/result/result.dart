import 'package:equatable/equatable.dart';
import 'package:listillify/core/errors/failures.dart';

/// PATRÓN DE DISEÑO: Result Pattern (Either / Monad de manejo de errores funcional)
/// Permite modelar operaciones que pueden tener éxito con un valor de tipo [T]
/// o fracasar con un [Failure] de dominio, evitando excepciones no controladas.
sealed class Result<T> extends Equatable {
  const Result();

  /// Retorna `true` si el resultado es exitoso.
  bool get isSuccess => this is Success<T>;

  /// Retorna `true` si el resultado representa un error.
  bool get isFailure => this is FailureResult<T>;

  /// Permite acceder al valor si fue exitoso, o null en caso de fallo.
  T? get dataOrNull => switch (this) {
        Success(data: final d) => d,
        FailureResult() => null,
      };

  /// Permite acceder al fallo si ocurrió un error, o null en caso de éxito.
  Failure? get failureOrNull => switch (this) {
        Success() => null,
        FailureResult(failure: final f) => f,
      };

  /// Ejecuta [onSuccess] si fue exitoso o [onFailure] si fue fallido.
  R when<R>({
    required R Function(T data) onSuccess,
    required R Function(Failure failure) onFailure,
  }) {
    return switch (this) {
      Success(data: final data) => onSuccess(data),
      FailureResult(failure: final failure) => onFailure(failure),
    };
  }
}

/// Representa una operación exitosa con datos de tipo [T].
final class Success<T> extends Result<T> {
  final T data;

  const Success(this.data);

  @override
  List<Object?> get props => [data];

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Success && data == other.data);

  @override
  int get hashCode => data.hashCode;
}

/// Representa una operación fallida con su respectivo [Failure].
final class FailureResult<T> extends Result<T> {
  final Failure failure;

  const FailureResult(this.failure);

  @override
  List<Object?> get props => [failure];

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is FailureResult && failure == other.failure);

  @override
  int get hashCode => failure.hashCode;
}
