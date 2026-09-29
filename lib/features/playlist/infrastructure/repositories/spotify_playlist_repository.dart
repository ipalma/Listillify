import 'dart:convert';
import 'dart:math';
import 'package:http/http.dart' as http;
import 'package:listillify/core/constants/spotify_constants.dart';
import 'package:listillify/core/errors/failures.dart';
import 'package:listillify/core/result/result.dart';
import 'package:listillify/features/config/domain/repositories/config_repository.dart';
import 'package:listillify/features/playlist/domain/entities/track_item.dart';
import 'package:listillify/features/playlist/domain/repositories/playlist_repository.dart';

/// PATRÓN DE DISEÑO: Adapter (Arquitectura Hexagonal) / Repository
/// Implementación de [PlaylistRepository] que se comunica con los endpoints de la API Web de Spotify,
/// gestionando serialización JSON, batching de 100 canciones por petición, renovación de tokens y control de Rate Limiting.
class SpotifyPlaylistRepository implements PlaylistRepository {
  final http.Client _httpClient;
  final ConfigRepository? configRepository;
  String? _cachedClientToken;
  DateTime? _cachedTokenExpiresAt;

  SpotifyPlaylistRepository({
    http.Client? httpClient,
    this.configRepository,
  }) : _httpClient = httpClient ?? http.Client();

  /// Obtiene un token válido de Spotify usando Client Credentials si el token provisto es local o inválido.
  Future<String> _resolveToken(String token) async {
    if (token.isNotEmpty && !token.startsWith('session_')) {
      return token;
    }

    if (_cachedClientToken != null &&
        _cachedTokenExpiresAt != null &&
        DateTime.now().isBefore(_cachedTokenExpiresAt!)) {
      return _cachedClientToken!;
    }

    if (configRepository != null) {
      final configResult = await configRepository!.getConfig();
      final config = configResult.dataOrNull;
      if (config != null && config.isValid) {
        try {
          final basicAuth = base64Encode(utf8.encode('${config.clientId}:${config.clientSecret}'));
          final response = await _httpClient.post(
            Uri.parse(SpotifyConstants.tokenEndpoint),
            headers: {
              'Authorization': 'Basic $basicAuth',
              'Content-Type': 'application/x-www-form-urlencoded',
            },
            body: {'grant_type': 'client_credentials'},
          );

          if (response.statusCode == 200) {
            final json = jsonDecode(response.body) as Map<String, dynamic>;
            final newToken = json['access_token'] as String;
            final expiresIn = json['expires_in'] as int? ?? 3600;
            _cachedClientToken = newToken;
            _cachedTokenExpiresAt = DateTime.now().add(Duration(seconds: expiresIn - 60));
            return newToken;
          }
        } catch (_) {
          // Si falla la petición de token, devolvemos el original
        }
      }
    }

    return token;
  }

  @override
  Future<Result<TrackItem?>> searchTrack({
    required String query,
    required String accessToken,
  }) async {
    try {
      var effectiveToken = await _resolveToken(accessToken);
      final encodedQuery = Uri.encodeComponent(query);
      final searchUri = Uri.parse(
        '${SpotifyConstants.apiBaseUrl}/search?q=$encodedQuery&type=track,episode&limit=1',
      );

      var response = await _httpClient.get(
        searchUri,
        headers: {'Authorization': 'Bearer $effectiveToken'},
      );

      // Si devuelve 401 y tenemos configuración, intentamos invalidar caché y reintentar
      if (response.statusCode == 401 && configRepository != null) {
        _cachedClientToken = null;
        effectiveToken = await _resolveToken('');
        if (effectiveToken.isNotEmpty && !effectiveToken.startsWith('session_')) {
          response = await _httpClient.get(
            searchUri,
            headers: {'Authorization': 'Bearer $effectiveToken'},
          );
        }
      }

      if (response.statusCode == 429) {
        final retryAfter = int.tryParse(response.headers['retry-after'] ?? '5') ?? 5;
        return FailureResult(
          RateLimitFailure(
            message: 'Spotify API rate limit excedido. Espera $retryAfter segundos.',
            retryAfterSeconds: retryAfter,
          ),
        );
      }

      if (response.statusCode == 401) {
        return const FailureResult(
          AuthFailure(message: 'Token de acceso expirado o inválido.', statusCode: 401),
        );
      }

      if (response.statusCode != 200) {
        return FailureResult(
          ServerFailure(
            message: 'Error en la búsqueda de Spotify (${response.statusCode}): ${response.body}',
            statusCode: response.statusCode,
          ),
        );
      }

      final json = jsonDecode(response.body) as Map<String, dynamic>;

      // Comprobamos si hay pistas musicales encontradas
      final tracks = json['tracks']?['items'] as List<dynamic>?;
      if (tracks != null && tracks.isNotEmpty) {
        final item = tracks.first as Map<String, dynamic>;
        return Success(_mapTrackItem(item, query));
      }

      // Si no hay tracks, comprobamos episodios de podcast
      final episodes = json['episodes']?['items'] as List<dynamic>?;
      if (episodes != null && episodes.isNotEmpty) {
        final item = episodes.first as Map<String, dynamic>;
        return Success(_mapEpisodeItem(item, query));
      }

      return const Success(null);
    } catch (e) {
      if (e is Failure) return FailureResult(e);
      return FailureResult(ServerFailure(message: 'Excepción durante la búsqueda: $e'));
    }
  }

  @override
  Future<Result<TrackItem?>> getTrackByUri({
    required String uri,
    required String accessToken,
  }) async {
    try {
      final parts = uri.split(':');
      if (parts.length != 3 || parts[0] != 'spotify') {
        return FailureResult(
          ValidationFailure(message: 'Formato de URI de Spotify no válido: $uri'),
        );
      }

      final type = parts[1]; // 'track' o 'episode'
      final id = parts[2];

      final endpoint = type == 'episode' ? 'episodes' : 'tracks';
      final requestUri = Uri.parse('${SpotifyConstants.apiBaseUrl}/$endpoint/$id');

      var effectiveToken = await _resolveToken(accessToken);
      var response = await _httpClient.get(
        requestUri,
        headers: {'Authorization': 'Bearer $effectiveToken'},
      );

      if (response.statusCode == 401 && configRepository != null) {
        _cachedClientToken = null;
        effectiveToken = await _resolveToken('');
        if (effectiveToken.isNotEmpty && !effectiveToken.startsWith('session_')) {
          response = await _httpClient.get(
            requestUri,
            headers: {'Authorization': 'Bearer $effectiveToken'},
          );
        }
      }

      if (response.statusCode == 429) {
        final retryAfter = int.tryParse(response.headers['retry-after'] ?? '5') ?? 5;
        return FailureResult(
          RateLimitFailure(
            message: 'Spotify API rate limit excedido. Espera $retryAfter segundos.',
            retryAfterSeconds: retryAfter,
          ),
        );
      }

      if (response.statusCode == 401) {
        return const FailureResult(
          AuthFailure(message: 'Token de acceso expirado o inválido.', statusCode: 401),
        );
      }

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body) as Map<String, dynamic>;
        if (type == 'episode') {
          return Success(_mapEpisodeItem(json, uri));
        } else {
          return Success(_mapTrackItem(json, uri));
        }
      }

      return const Success(null);
    } catch (e) {
      return FailureResult(ServerFailure(message: 'Error al resolver URI de Spotify: $e'));
    }
  }

  @override
  Future<Result<String>> createPlaylist({
    required String userId,
    required String name,
    required String accessToken,
    String? description,
    bool isPublic = false,
  }) async {
    try {
      // Usamos el endpoint estándar /me/playlists (no depende del formato del ID de usuario ni de emails)
      final createUri = Uri.parse('${SpotifyConstants.apiBaseUrl}/me/playlists');
      final body = jsonEncode({
        'name': name,
        'description': description ?? 'Creado con Listillify',
        'public': isPublic,
      });

      var response = await _httpClient.post(
        createUri,
        headers: {
          'Authorization': 'Bearer $accessToken',
          'Content-Type': 'application/json',
        },
        body: body,
      );

      // Si falla y tenemos un userId alfanumérico sin caracteres especiales ni arroba, intentamos fallback
      if (response.statusCode != 200 &&
          response.statusCode != 201 &&
          userId.isNotEmpty &&
          !userId.contains('@')) {
        final fallbackUri = Uri.parse('${SpotifyConstants.apiBaseUrl}/users/$userId/playlists');
        response = await _httpClient.post(
          fallbackUri,
          headers: {
            'Authorization': 'Bearer $accessToken',
            'Content-Type': 'application/json',
          },
          body: body,
        );
      }

      if (response.statusCode == 200 || response.statusCode == 201) {
        final json = jsonDecode(response.body) as Map<String, dynamic>;
        final playlistId = json['id'] as String;
        return Success(playlistId);
      }

      return FailureResult(
        ServerFailure(
          message: 'Error al crear la playlist en Spotify (${response.statusCode}): ${response.body}',
          statusCode: response.statusCode,
        ),
      );
    } catch (e) {
      return FailureResult(ServerFailure(message: 'Excepción al crear la playlist: $e'));
    }
  }

  @override
  Future<Result<int>> addTracksToPlaylist({
    required String playlistId,
    required List<String> trackUris,
    required String accessToken,
  }) async {
    try {
      int totalAdded = 0;
      final itemsUri = Uri.parse('${SpotifyConstants.apiBaseUrl}/playlists/$playlistId/items');
      final tracksUri = Uri.parse('${SpotifyConstants.apiBaseUrl}/playlists/$playlistId/tracks');

      // PATRÓN DE DISEÑO: Batch Processing / Chunking
      // La API de Spotify limita la adición a un máximo de 100 canciones por petición HTTP
      for (var i = 0; i < trackUris.length; i += SpotifyConstants.maxTracksPerBatch) {
        final chunk = trackUris.sublist(
          i,
          min(i + SpotifyConstants.maxTracksPerBatch, trackUris.length),
        );

        // Spotify Web API migró /tracks a /items. Usamos /items con fallback a /tracks
        var response = await _httpClient.post(
          itemsUri,
          headers: {
            'Authorization': 'Bearer $accessToken',
            'Content-Type': 'application/json',
          },
          body: jsonEncode({'uris': chunk}),
        );

        if (response.statusCode == 404) {
          response = await _httpClient.post(
            tracksUri,
            headers: {
              'Authorization': 'Bearer $accessToken',
              'Content-Type': 'application/json',
            },
            body: jsonEncode({'uris': chunk}),
          );
        }

        if (response.statusCode == 201 || response.statusCode == 200) {
          totalAdded += chunk.length;
        } else {
          return FailureResult(
            ServerFailure(
              message: 'Error al agregar lote de pistas a Spotify: ${response.body}',
              statusCode: response.statusCode,
            ),
          );
        }
      }

      return Success(totalAdded);
    } catch (e) {
      return FailureResult(ServerFailure(message: 'Excepción al agregar pistas: $e'));
    }
  }

  TrackItem _mapTrackItem(Map<String, dynamic> item, String rawQuery) {
    final artists = item['artists'] as List<dynamic>?;
    final artistName = (artists != null && artists.isNotEmpty)
        ? artists.map((a) => a['name'] as String).join(', ')
        : 'Artista desconocido';

    final album = item['album'] as Map<String, dynamic>?;
    final albumName = album?['name'] as String?;
    final images = album?['images'] as List<dynamic>?;
    final albumImageUrl = (images != null && images.isNotEmpty)
        ? images.first['url'] as String?
        : null;

    final durationMs = item['duration_ms'] as int? ?? 0;

    return TrackItem(
      id: item['id'] as String? ?? '',
      title: item['name'] as String? ?? 'Sin título',
      artist: artistName,
      uri: item['uri'] as String? ?? '',
      albumName: albumName,
      albumImageUrl: albumImageUrl,
      duration: Duration(milliseconds: durationMs),
      isFound: true,
      rawQuery: rawQuery,
    );
  }

  TrackItem _mapEpisodeItem(Map<String, dynamic> item, String rawQuery) {
    final images = item['images'] as List<dynamic>?;
    final imageUrl = (images != null && images.isNotEmpty)
        ? images.first['url'] as String?
        : null;

    final durationMs = item['duration_ms'] as int? ?? 0;

    return TrackItem(
      id: item['id'] as String? ?? '',
      title: item['name'] as String? ?? 'Episodio sin título',
      artist: 'Podcast',
      uri: item['uri'] as String? ?? '',
      albumName: item['description'] as String?,
      albumImageUrl: imageUrl,
      duration: Duration(milliseconds: durationMs),
      isFound: true,
      rawQuery: rawQuery,
    );
  }
}
