import 'package:listillify/core/result/result.dart';
import 'package:listillify/features/auth/domain/entities/user_session.dart';

/// PATRÓN DE DISEÑO: Port (Arquitectura Hexagonal) / Repository Pattern
/// Define el contrato abstracto para la autenticación y gestión de sesiones de Spotify.
/// El dominio desacopla los detalles de OAuth 2.0 PKCE y llamadas HTTP (SOLID D).
abstract class AuthRepository {
  /// Inicia el flujo de autenticación OAuth 2.0 PKCE con el [clientId] configurado.
  Future<Result<UserSession>> login(String clientId);

  /// Recupera la sesión persistida actualmente, si existe.
  Future<Result<UserSession?>> getCurrentSession();

  /// Obtiene un token de acceso válido, refrescándolo automáticamente si ha expirado.
  Future<Result<String>> getValidAccessToken(String clientId);

  /// Cierra la sesión activa y elimina las credenciales almacenadas localmente.
  Future<Result<void>> logout();
}
