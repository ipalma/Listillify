import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:listillify/core/usecases/usecase.dart';
import 'package:listillify/features/config/domain/entities/api_config.dart';
import 'package:listillify/features/config/domain/usecases/get_api_config_use_case.dart';
import 'package:listillify/features/config/domain/usecases/save_api_config_use_case.dart';
import 'package:listillify/features/config/presentation/cubit/config_state.dart';

/// PATRÓN DE DISEÑO: Observer / Presentation Controller (BLoC / Cubit)
/// Gestiona el estado de la configuración de la API de Spotify y notifica a los oyentes de la UI.
/// Mantiene desacoplada la vista de los casos de uso del dominio.
class ConfigCubit extends Cubit<ConfigState> {
  final GetApiConfigUseCase getApiConfigUseCase;
  final SaveApiConfigUseCase saveApiConfigUseCase;

  ConfigCubit({
    required this.getApiConfigUseCase,
    required this.saveApiConfigUseCase,
  }) : super(const ConfigInitial());

  /// Carga la configuración actual desde el repositorio.
  Future<void> loadConfig() async {
    emit(const ConfigLoading());
    final result = await getApiConfigUseCase(const NoParams());

    result.when(
      onSuccess: (config) => emit(ConfigLoaded(config)),
      onFailure: (failure) => emit(ConfigError(failure.message)),
    );
  }

  /// Guarda una nueva configuración con el [clientId] proporcionado.
  Future<void> saveConfig(String clientId) async {
    emit(const ConfigLoading());
    final config = ApiConfig(clientId: clientId.trim());

    final result = await saveApiConfigUseCase(SaveApiConfigParams(config: config));

    result.when(
      onSuccess: (_) => emit(ConfigSavedSuccess(config)),
      onFailure: (failure) => emit(ConfigError(failure.message)),
    );
  }
}
