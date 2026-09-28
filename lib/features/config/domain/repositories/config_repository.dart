import 'package:listillify/core/result/result.dart';
import 'package:listillify/features/config/domain/entities/api_config.dart';

/// PATRÓN DE DISEÑO: Port (Arquitectura Hexagonal) / Repository Pattern
/// Define el contrato de persistencia y recuperación de configuración de API.
/// El dominio depende exclusivamente de esta abstracción (Principio de Inversión de Dependencias - SOLID D).
abstract class ConfigRepository {
  /// Obtiene la configuración guardada de la API de Spotify.
  Future<Result<ApiConfig>> getConfig();

  /// Persiste la configuración de la API de Spotify de manera segura.
  Future<Result<void>> saveConfig(ApiConfig config);

  /// Elimina la configuración guardada.
  Future<Result<void>> clearConfig();
}
