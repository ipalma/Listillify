import 'dart:convert';
import 'dart:io';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'package:listillify/core/constants/spotify_constants.dart';
import 'package:listillify/core/errors/failures.dart';
import 'package:listillify/core/result/result.dart';
import 'package:listillify/features/auth/domain/entities/user_session.dart';
import 'package:listillify/features/auth/domain/repositories/auth_repository.dart';
import 'package:listillify/features/auth/infrastructure/services/oauth_callback_server.dart';
import 'package:listillify/features/auth/infrastructure/services/pkce_service.dart';
import 'package:url_launcher/url_launcher.dart';

/// PATRÓN DE DISEÑO: Adapter (Arquitectura Hexagonal) / Repository
/// Implementación concreta del puerto [AuthRepository] que maneja el ciclo de vida de OAuth 2.0 PKCE,
/// llamadas a la API de Spotify y persistencia de credenciales en almacenamiento seguro.
class SpotifyAuthRepository implements AuthRepository {
  final http.Client _httpClient;
  final FlutterSecureStorage _storage;
  final PkceService _pkceService;
  final OAuthCallbackServer _callbackServer;
  final Future<bool> Function(Uri url) _urlLauncher;

  SpotifyAuthRepository({
    http.Client? httpClient,
    FlutterSecureStorage? storage,
    PkceService? pkceService,
    OAuthCallbackServer? callbackServer,
    Future<bool> Function(Uri url)? urlLauncher,
  })  : _httpClient = httpClient ?? http.Client(),
        _storage = storage ?? const FlutterSecureStorage(),
        _pkceService = pkceService ?? PkceService(),
        _callbackServer = callbackServer ?? OAuthCallbackServer(),
        _urlLauncher = urlLauncher ?? launchUrl;

  @override
  Future<Result<UserSession>> login(String clientId) async {
    try {
      final codeVerifier = _pkceService.generateCodeVerifier();
      final codeChallenge = _pkceService.generateCodeChallenge(codeVerifier);
      final state = _pkceService.generateState();

      // Determinamos el redirect_uri adecuado según plataforma
      final redirectUri = Platform.isAndroid
          ? SpotifyConstants.androidRedirectUri
          : SpotifyConstants.windowsRedirectUri;

      final authUri = Uri.parse(SpotifyConstants.authorizeEndpoint).replace(
        queryParameters: {
          'client_id': clientId,
          'response_type': 'code',
          'redirect_uri': redirectUri,
          'code_challenge_method': 'S256',
          'code_challenge': codeChallenge,
          'state': state,
          'scope': SpotifyConstants.scopesJoined,
        },
      );

      // Lanzamos navegador del sistema
      final launched = await _urlLauncher(authUri);
      if (!launched) {
        return const FailureResult(
          AuthFailure(message: 'No se pudo abrir el navegador para autenticar en Spotify.'),
        );
      }

      // Esperamos el código de autorización
      final authCode = await _callbackServer.waitForAuthorizationCode(expectedState: state);

      // Intercambiamos authorization_code por tokens
      final tokenResponse = await _httpClient.post(
        Uri.parse(SpotifyConstants.tokenEndpoint),
        headers: {'Content-Type': 'application/x-www-form-urlencoded'},
        body: {
          'client_id': clientId,
          'grant_type': 'authorization_code',
          'code': authCode,
          'redirect_uri': redirectUri,
          'code_verifier': codeVerifier,
        },
      );

      if (tokenResponse.statusCode != 200) {
        return FailureResult(
          AuthFailure(
            message: 'Error al intercambiar el código por tokens: ${tokenResponse.body}',
            statusCode: tokenResponse.statusCode,
          ),
        );
      }

      final tokenJson = jsonDecode(tokenResponse.body) as Map<String, dynamic>;
      final accessToken = tokenJson['access_token'] as String;
      final refreshToken = tokenJson['refresh_token'] as String?;
      final expiresIn = tokenJson['expires_in'] as int? ?? 3600;
      final expiresAt = DateTime.now().add(Duration(seconds: expiresIn));

      // Obtenemos los datos del perfil del usuario
      final profileResponse = await _httpClient.get(
        Uri.parse('${SpotifyConstants.apiBaseUrl}/me'),
        headers: {'Authorization': 'Bearer $accessToken'},
      );

      if (profileResponse.statusCode != 200) {
        return FailureResult(
          AuthFailure(
            message: 'Error al obtener perfil del usuario: ${profileResponse.body}',
            statusCode: profileResponse.statusCode,
          ),
        );
      }

      final profileJson = jsonDecode(profileResponse.body) as Map<String, dynamic>;
      final userId = profileJson['id'] as String;
      final displayName = profileJson['display_name'] as String? ?? userId;
      final email = profileJson['email'] as String?;

      String? avatarUrl;
      final images = profileJson['images'] as List<dynamic>?;
      if (images != null && images.isNotEmpty) {
        avatarUrl = images.first['url'] as String?;
      }

      final session = UserSession(
        id: userId,
        displayName: displayName,
        email: email,
        avatarUrl: avatarUrl,
        accessToken: accessToken,
        refreshToken: refreshToken,
        expiresAt: expiresAt,
      );

      // Guardamos la sesión en el almacenamiento seguro
      await _persistSession(session);

      return Success(session);
    } catch (e) {
      if (e is Failure) return FailureResult(e);
      return FailureResult(AuthFailure(message: 'Error durante el login con Spotify: $e'));
    }
  }

  @override
  Future<Result<UserSession?>> getCurrentSession() async {
    try {
      final accessToken = await _storage.read(key: SpotifyConstants.secureStorageAccessTokenKey);
      final userId = await _storage.read(key: SpotifyConstants.secureStorageUserIdKey);
      final displayName = await _storage.read(key: SpotifyConstants.secureStorageUserDisplayNameKey);
      final refreshToken = await _storage.read(key: SpotifyConstants.secureStorageRefreshTokenKey);
      final expiresAtStr = await _storage.read(key: SpotifyConstants.secureStorageTokenExpiresAtKey);

      if (accessToken == null || userId == null) {
        return const Success(null);
      }

      final expiresAt = expiresAtStr != null
          ? DateTime.tryParse(expiresAtStr) ?? DateTime.now()
          : DateTime.now();

      final session = UserSession(
        id: userId,
        displayName: displayName ?? userId,
        accessToken: accessToken,
        refreshToken: refreshToken,
        expiresAt: expiresAt,
      );

      return Success(session);
    } catch (e) {
      return FailureResult(StorageFailure(message: 'Error al leer la sesión actual: $e'));
    }
  }

  @override
  Future<Result<String>> getValidAccessToken(String clientId) async {
    final sessionResult = await getCurrentSession();
    if (sessionResult.isFailure) return FailureResult(sessionResult.failureOrNull!);

    final session = sessionResult.dataOrNull;
    if (session == null) {
      return const FailureResult(AuthFailure(message: 'No existe sesión activa.'));
    }

    // Si aún no ha expirado, devolvemos el token actual
    if (!session.isExpired) {
      return Success(session.accessToken);
    }

    // Si ha expirado pero tenemos refresh_token, lo refrescamos
    if (session.refreshToken == null) {
      return const FailureResult(AuthFailure(message: 'Token expirado y no hay token de refresco.'));
    }

    return await _refreshAccessToken(clientId: clientId, refreshToken: session.refreshToken!);
  }

  Future<Result<String>> _refreshAccessToken({
    required String clientId,
    required String refreshToken,
  }) async {
    try {
      final response = await _httpClient.post(
        Uri.parse(SpotifyConstants.tokenEndpoint),
        headers: {'Content-Type': 'application/x-www-form-urlencoded'},
        body: {
          'grant_type': 'refresh_token',
          'refresh_token': refreshToken,
          'client_id': clientId,
        },
      );

      if (response.statusCode != 200) {
        return FailureResult(
          AuthFailure(
            message: 'Error al refrescar el token de Spotify: ${response.body}',
            statusCode: response.statusCode,
          ),
        );
      }

      final json = jsonDecode(response.body) as Map<String, dynamic>;
      final newAccessToken = json['access_token'] as String;
      final newRefreshToken = json['refresh_token'] as String? ?? refreshToken;
      final expiresIn = json['expires_in'] as int? ?? 3600;
      final expiresAt = DateTime.now().add(Duration(seconds: expiresIn));

      await _storage.write(key: SpotifyConstants.secureStorageAccessTokenKey, value: newAccessToken);
      await _storage.write(key: SpotifyConstants.secureStorageRefreshTokenKey, value: newRefreshToken);
      await _storage.write(
        key: SpotifyConstants.secureStorageTokenExpiresAtKey,
        value: expiresAt.toIso8601String(),
      );

      return Success(newAccessToken);
    } catch (e) {
      return FailureResult(AuthFailure(message: 'Fallo al refrescar token: $e'));
    }
  }

  @override
  Future<Result<void>> logout() async {
    try {
      await _storage.delete(key: SpotifyConstants.secureStorageAccessTokenKey);
      await _storage.delete(key: SpotifyConstants.secureStorageRefreshTokenKey);
      await _storage.delete(key: SpotifyConstants.secureStorageTokenExpiresAtKey);
      await _storage.delete(key: SpotifyConstants.secureStorageUserIdKey);
      await _storage.delete(key: SpotifyConstants.secureStorageUserDisplayNameKey);
      return const Success(null);
    } catch (e) {
      return FailureResult(StorageFailure(message: 'Error al cerrar sesión: $e'));
    }
  }

  Future<void> _persistSession(UserSession session) async {
    await _storage.write(key: SpotifyConstants.secureStorageAccessTokenKey, value: session.accessToken);
    if (session.refreshToken != null) {
      await _storage.write(key: SpotifyConstants.secureStorageRefreshTokenKey, value: session.refreshToken);
    }
    await _storage.write(
      key: SpotifyConstants.secureStorageTokenExpiresAtKey,
      value: session.expiresAt.toIso8601String(),
    );
    await _storage.write(key: SpotifyConstants.secureStorageUserIdKey, value: session.id);
    await _storage.write(key: SpotifyConstants.secureStorageUserDisplayNameKey, value: session.displayName);
  }
}
