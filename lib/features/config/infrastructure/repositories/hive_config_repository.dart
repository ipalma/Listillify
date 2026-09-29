import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:hive/hive.dart';
import 'package:listillify/core/constants/spotify_constants.dart';
import 'package:listillify/core/errors/failures.dart';
import 'package:listillify/core/result/result.dart';
import 'package:listillify/features/config/domain/entities/api_config.dart';
import 'package:listillify/features/config/domain/repositories/config_repository.dart';

/// PATRÓN DE DISEÑO: Adapter (Arquitectura Hexagonal)
/// Implementa el puerto [ConfigRepository] utilizando Hive como motor de persistencia local en fichero NoSQL,
/// con sincronización y fallback automático hacia [FlutterSecureStorage].
class HiveConfigRepository implements ConfigRepository {
  final Box<dynamic>? _injectedBox;
  final FlutterSecureStorage _storage;

  HiveConfigRepository({
    Box<dynamic>? box,
    FlutterSecureStorage? storage,
  })  : _injectedBox = box,
        _storage = storage ?? const FlutterSecureStorage();

  Box<dynamic> get _box {
    if (_injectedBox != null) return _injectedBox;
    if (Hive.isBoxOpen(SpotifyConstants.hiveConfigBox)) {
      return Hive.box(SpotifyConstants.hiveConfigBox);
    }
    throw StateError('La caja de Hive "${SpotifyConstants.hiveConfigBox}" no está abierta.');
  }

  @override
  Future<Result<ApiConfig>> getConfig() async {
    try {
      final box = _box;
      String? clientId = box.get(SpotifyConstants.hiveClientIdKey) as String?;
      String? clientSecret = box.get(SpotifyConstants.hiveClientSecretKey) as String?;

      // Fallback a almacenamiento seguro si Hive aún está vacío
      if (clientId == null || clientId.trim().isEmpty) {
        clientId = await _storage.read(key: SpotifyConstants.secureStorageClientIdKey);
        clientSecret = await _storage.read(key: SpotifyConstants.secureStorageClientSecretKey);

        if (clientId != null && clientId.trim().isNotEmpty) {
          // Sincronizamos hacia Hive
          await box.put(SpotifyConstants.hiveClientIdKey, clientId.trim());
          await box.put(SpotifyConstants.hiveClientSecretKey, clientSecret?.trim() ?? '');
          await box.flush();
        }
      }

      if (clientId == null || clientId.trim().isEmpty) {
        return const Success(ApiConfig.empty());
      }

      return Success(
        ApiConfig(
          clientId: clientId.trim(),
          clientSecret: clientSecret?.trim() ?? '',
        ),
      );
    } catch (e) {
      return FailureResult(
        StorageFailure(message: 'Error al leer la configuración desde Hive: $e'),
      );
    }
  }

  @override
  Future<Result<void>> saveConfig(ApiConfig config) async {
    try {
      final box = _box;
      final cleanId = config.clientId.trim();
      final cleanSecret = config.clientSecret.trim();

      await box.put(SpotifyConstants.hiveClientIdKey, cleanId);
      await box.put(SpotifyConstants.hiveClientSecretKey, cleanSecret);
      await box.flush();

      // Sincronizamos en segundo plano hacia secure storage
      await _storage.write(key: SpotifyConstants.secureStorageClientIdKey, value: cleanId);
      await _storage.write(key: SpotifyConstants.secureStorageClientSecretKey, value: cleanSecret);

      return const Success(null);
    } catch (e) {
      return FailureResult(
        StorageFailure(message: 'Error al persistir la configuración en Hive: $e'),
      );
    }
  }

  @override
  Future<Result<void>> clearConfig() async {
    try {
      final box = _box;
      await box.delete(SpotifyConstants.hiveClientIdKey);
      await box.delete(SpotifyConstants.hiveClientSecretKey);
      await box.flush();

      await _storage.delete(key: SpotifyConstants.secureStorageClientIdKey);
      await _storage.delete(key: SpotifyConstants.secureStorageClientSecretKey);

      return const Success(null);
    } catch (e) {
      return FailureResult(
        StorageFailure(message: 'Error al limpiar la configuración de Hive: $e'),
      );
    }
  }
}
