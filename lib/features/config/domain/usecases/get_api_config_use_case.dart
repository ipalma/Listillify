import 'package:listillify/core/result/result.dart';
import 'package:listillify/core/usecases/usecase.dart';
import 'package:listillify/features/config/domain/entities/api_config.dart';
import 'package:listillify/features/config/domain/repositories/config_repository.dart';

/// PATRÓN DE DISEÑO: Command Pattern / Use Case Interactor
/// Caso de uso responsable de recuperar la configuración de acceso a Spotify.
/// Principio de Responsabilidad Única (SOLID S).
class GetApiConfigUseCase implements UseCase<ApiConfig, NoParams> {
  final ConfigRepository _repository;

  GetApiConfigUseCase(this._repository);

  @override
  Future<Result<ApiConfig>> call(NoParams params) async {
    return await _repository.getConfig();
  }
}
