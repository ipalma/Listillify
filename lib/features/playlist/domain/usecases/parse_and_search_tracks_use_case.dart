import 'package:equatable/equatable.dart';
import 'package:listillify/core/errors/failures.dart';
import 'package:listillify/core/result/result.dart';
import 'package:listillify/core/usecases/usecase.dart';
import 'package:listillify/features/playlist/domain/entities/track_item.dart';
import 'package:listillify/features/playlist/domain/repositories/playlist_repository.dart';
import 'package:listillify/features/playlist/domain/services/playlist_text_parser.dart';

/// Parámetros para el caso de uso [ParseAndSearchTracksUseCase].
class ParseAndSearchTracksParams extends Equatable {
  final String rawText;
  final String accessToken;
  final void Function(int current, int total, String currentItem)? onProgress;

  const ParseAndSearchTracksParams({
    required this.rawText,
    required this.accessToken,
    this.onProgress,
  });

  @override
  List<Object?> get props => [rawText, accessToken];
}

/// PATRÓN DE DISEÑO: Command Pattern / Use Case Interactor
/// Caso de uso que procesa el texto multilínea, extrae canciones o enlaces de Spotify
/// y realiza la búsqueda en la API para obtener los metadatos correspondientes.
class ParseAndSearchTracksUseCase
    implements UseCase<List<TrackItem>, ParseAndSearchTracksParams> {
  final PlaylistRepository playlistRepository;
  final PlaylistTextParser textParser;

  ParseAndSearchTracksUseCase({
    required this.playlistRepository,
    PlaylistTextParser? textParser,
  }) : textParser = textParser ?? PlaylistTextParser();

  @override
  Future<Result<List<TrackItem>>> call(ParseAndSearchTracksParams params) async {
    if (params.rawText.trim().isEmpty) {
      return const FailureResult(
        ValidationFailure(message: 'Debes introducir al menos una canción o enlace.'),
      );
    }

    if (params.accessToken.trim().isEmpty) {
      return const FailureResult(
        AuthFailure(message: 'Sesión no válida o token de acceso ausente.'),
      );
    }

    final parsedQueries = textParser.parse(params.rawText);
    if (parsedQueries.isEmpty) {
      return const FailureResult(
        ValidationFailure(message: 'No se encontraron líneas válidas con nombres de canciones.'),
      );
    }

    final tracks = <TrackItem>[];
    final total = parsedQueries.length;

    for (var i = 0; i < total; i++) {
      final item = parsedQueries[i];
      params.onProgress?.call(i + 1, total, item.query);

      Result<TrackItem?> searchResult;

      if (item.isDirectUri && item.directUri != null) {
        searchResult = await playlistRepository.getTrackByUri(
          uri: item.directUri!,
          accessToken: params.accessToken,
        );
      } else {
        searchResult = await playlistRepository.searchTrack(
          query: item.query,
          accessToken: params.accessToken,
        );
      }

      searchResult.when(
        onSuccess: (track) {
          if (track != null) {
            tracks.add(track);
          } else {
            tracks.add(TrackItem.notFound(item.query));
          }
        },
        onFailure: (failure) {
          // Si una pista falla en búsqueda, la marcamos como no encontrada para continuar con el resto
          tracks.add(TrackItem.notFound(item.query));
        },
      );
    }

    return Success(tracks);
  }
}
