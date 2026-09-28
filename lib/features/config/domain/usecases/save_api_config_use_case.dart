import 'package:equatable/equatable.dart';
import 'package:listillify/core/errors/failures.dart';
import 'package:listillify/core/result/result.dart';
import 'package:listillify/core/usecases/usecase.dart';
import 'package:listillify/features/config/domain/entities/api_config.dart';
import 'package:listillify/features/config/domain/repositories/config_repository.dart';

/// Parámetros de entrada para el caso de uso [SaveApiConfigUseCase].
class SaveApiConfigParams extends Equatable {
  final ApiConfig config;

  const SaveApiConfigParams({required this.config});

  @override
  List<Object?> get props => [config];
}

/// PATRÓN DE DISEÑO: Command Pattern / Use Case Interactor
/// Caso de uso que valida y persiste la configuración de API de Spotify.
/// Principio de Responsabilidad Única (SOLID S).
class SaveApiConfigUseCase implements UseCase<void, SaveApiConfigParams> {
  final ConfigRepository _repository;

  SaveApiConfigUseCase(this._repository);

  @override
  Future<Result<void>> call(SaveApiConfigParams params) async {
    final config = params.config;

    // Validación de negocio en la capa de dominio
    if (!config.isValid) {
      return const FailureResult(
        ValidationFailure(message: 'El Client ID de Spotify no puede estar vacío.'),
      );
    }

    return await _repository.saveConfig(config);
  }
}
