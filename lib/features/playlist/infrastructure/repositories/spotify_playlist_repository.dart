import 'dart:convert';
import 'dart:math';
import 'package:http/http.dart' as http;
import 'package:listillify/core/constants/spotify_constants.dart';
import 'package:listillify/core/errors/failures.dart';
import 'package:listillify/core/result/result.dart';
import 'package:listillify/features/playlist/domain/entities/track_item.dart';
import 'package:listillify/features/playlist/domain/repositories/playlist_repository.dart';

/// PATRÓN DE DISEÑO: Adapter (Arquitectura Hexagonal) / Repository
/// Implementación de [PlaylistRepository] que se comunica con los endpoints de la API Web de Spotify,
/// gestionando serialización JSON, batching de 100 canciones por petición y control de Rate Limiting.
class SpotifyPlaylistRepository implements PlaylistRepository {
  final http.Client _httpClient;

  SpotifyPlaylistRepository({http.Client? httpClient})
      : _httpClient = httpClient ?? http.Client();

  @override
  Future<Result<TrackItem?>> searchTrack({
    required String query,
    required String accessToken,
  }) async {
    try {
      final encodedQuery = Uri.encodeComponent(query);
      final searchUri = Uri.parse(
        '${SpotifyConstants.apiBaseUrl}/search?q=$encodedQuery&type=track,episode&limit=1',
      );

      final response = await _httpClient.get(
        searchUri,
        headers: {'Authorization': 'Bearer $accessToken'},
      );

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

      final response = await _httpClient.get(
        requestUri,
        headers: {'Authorization': 'Bearer $accessToken'},
      );

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
      final createUri = Uri.parse('${SpotifyConstants.apiBaseUrl}/users/$userId/playlists');
      final body = jsonEncode({
        'name': name,
        'description': description ?? 'Creado con Listillify',
        'public': isPublic,
      });

      final response = await _httpClient.post(
        createUri,
        headers: {
          'Authorization': 'Bearer $accessToken',
          'Content-Type': 'application/json',
        },
        body: body,
      );

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
      final addUri = Uri.parse('${SpotifyConstants.apiBaseUrl}/playlists/$playlistId/tracks');

      // PATRÓN DE DISEÑO: Batch Processing / Chunking
      // La API de Spotify limita la adición a un máximo de 100 canciones por petición HTTP
      for (var i = 0; i < trackUris.length; i += SpotifyConstants.maxTracksPerBatch) {
        final chunk = trackUris.sublist(
          i,
          min(i + SpotifyConstants.maxTracksPerBatch, trackUris.length),
        );

        final response = await _httpClient.post(
          addUri,
          headers: {
            'Authorization': 'Bearer $accessToken',
            'Content-Type': 'application/json',
          },
          body: jsonEncode({'uris': chunk}),
        );

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
