import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:listillify/features/config/domain/repositories/config_repository.dart';
import 'package:listillify/features/config/domain/usecases/get_api_config_use_case.dart';
import 'package:listillify/features/config/domain/usecases/save_api_config_use_case.dart';
import 'package:listillify/features/config/infrastructure/repositories/secure_config_repository.dart';
import 'package:listillify/features/config/presentation/cubit/config_cubit.dart';

/// PATRÓN DE DISEÑO: Service Locator / Composition Root / Dependency Injection
/// Gestiona la creación e inyección de dependencias para asegurar bajo acoplamiento (SOLID D).
class DependencyInjection {
  DependencyInjection._();

  static late final FlutterSecureStorage secureStorage;
  static late final ConfigRepository configRepository;
  static late final GetApiConfigUseCase getApiConfigUseCase;
  static late final SaveApiConfigUseCase saveApiConfigUseCase;

  /// Inicializa los adaptadores de infraestructura y casos de uso.
  static void init({FlutterSecureStorage? storage}) {
    secureStorage = storage ?? const FlutterSecureStorage();
    configRepository = SecureConfigRepository(storage: secureStorage);
    getApiConfigUseCase = GetApiConfigUseCase(configRepository);
    saveApiConfigUseCase = SaveApiConfigUseCase(configRepository);
  }

  /// Crea una nueva instancia de [ConfigCubit] con sus dependencias inyectadas.
  static ConfigCubit createConfigCubit() {
    return ConfigCubit(
      getApiConfigUseCase: getApiConfigUseCase,
      saveApiConfigUseCase: saveApiConfigUseCase,
    );
  }
}
