import 'package:listillify/core/result/result.dart';
import 'package:listillify/features/playlist/domain/entities/track_item.dart';

/// PATRÓN DE DISEÑO: Port (Arquitectura Hexagonal) / Repository Pattern
/// Define el contrato abstracto para la búsqueda de canciones, creación de playlists
/// y adición de pistas en la API Web de Spotify.
abstract class PlaylistRepository {
  /// Busca una canción o episodio en Spotify a partir de una consulta de texto.
  Future<Result<TrackItem?>> searchTrack({
    required String query,
    required String accessToken,
  });

  /// Obtiene los metadatos de una canción o episodio a partir de su URI directa de Spotify.
  Future<Result<TrackItem?>> getTrackByUri({
    required String uri,
    required String accessToken,
  });

  /// Crea una nueva playlist en la cuenta del usuario especificado.
  Future<Result<String>> createPlaylist({
    required String userId,
    required String name,
    required String accessToken,
    String? description,
    bool isPublic = false,
  });

  /// Añade una lista de URIs de canciones o episodios a la playlist especificada.
  /// Maneja la paginación interna en lotes de hasta 100 pistas.
  Future<Result<int>> addTracksToPlaylist({
    required String playlistId,
    required List<String> trackUris,
    required String accessToken,
  });
}
