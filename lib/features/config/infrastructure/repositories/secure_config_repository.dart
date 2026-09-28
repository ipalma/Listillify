import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:listillify/core/constants/spotify_constants.dart';
import 'package:listillify/core/errors/failures.dart';
import 'package:listillify/core/result/result.dart';
import 'package:listillify/features/config/domain/entities/api_config.dart';
import 'package:listillify/features/config/domain/repositories/config_repository.dart';

/// PATRÓN DE DISEÑO: Adapter (Arquitectura Hexagonal)
/// Implementa el puerto [ConfigRepository] utilizando [FlutterSecureStorage] como adaptador
/// hacia el almacenamiento seguro del sistema operativo (Windows Credential Manager / Android KeyStore).
class SecureConfigRepository implements ConfigRepository {
  final FlutterSecureStorage _storage;

  SecureConfigRepository({FlutterSecureStorage? storage})
      : _storage = storage ??
            const FlutterSecureStorage(
              aOptions: AndroidOptions(
                resetOnError: true,
              ),
              wOptions: WindowsOptions(
                useBackwardCompatibility: false,
              ),
            );

  @override
  Future<Result<ApiConfig>> getConfig() async {
    try {
      final clientId = await _storage.read(key: SpotifyConstants.secureStorageClientIdKey);
      if (clientId == null || clientId.trim().isEmpty) {
        return const Success(ApiConfig.empty());
      }
      return Success(ApiConfig(clientId: clientId.trim()));
    } catch (e) {
      return FailureResult(
        StorageFailure(message: 'Error al leer la configuración segura: $e'),
      );
    }
  }

  @override
  Future<Result<void>> saveConfig(ApiConfig config) async {
    try {
      await _storage.write(
        key: SpotifyConstants.secureStorageClientIdKey,
        value: config.clientId.trim(),
      );
      return const Success(null);
    } catch (e) {
      return FailureResult(
        StorageFailure(message: 'Error al persistir la configuración segura: $e'),
      );
    }
  }

  @override
  Future<Result<void>> clearConfig() async {
    try {
      await _storage.delete(key: SpotifyConstants.secureStorageClientIdKey);
      return const Success(null);
    } catch (e) {
      return FailureResult(
        StorageFailure(message: 'Error al eliminar la configuración: $e'),
      );
    }
  }
}
