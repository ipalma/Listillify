import 'package:hive/hive.dart';
import 'package:listillify/core/constants/spotify_constants.dart';
import 'package:listillify/core/errors/failures.dart';
import 'package:listillify/core/result/result.dart';
import 'package:listillify/features/config/domain/entities/api_config.dart';
import 'package:listillify/features/config/domain/repositories/config_repository.dart';

/// PATRÓN DE DISEÑO: Adapter (Arquitectura Hexagonal)
/// Implementa el puerto [ConfigRepository] utilizando Hive como motor de persistencia local en fichero NoSQL.
/// Guarda de manera persistente en disco el Client ID y el Client Secret de Spotify.
class HiveConfigRepository implements ConfigRepository {
  final Box<dynamic>? _injectedBox;

  HiveConfigRepository({Box<dynamic>? box}) : _injectedBox = box;

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
      final clientId = box.get(SpotifyConstants.hiveClientIdKey) as String?;
      final clientSecret = box.get(SpotifyConstants.hiveClientSecretKey) as String?;

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
      await box.put(SpotifyConstants.hiveClientIdKey, config.clientId.trim());
      await box.put(SpotifyConstants.hiveClientSecretKey, config.clientSecret.trim());
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
      return const Success(null);
    } catch (e) {
      return FailureResult(
        StorageFailure(message: 'Error al limpiar la configuración de Hive: $e'),
      );
    }
  }
}
