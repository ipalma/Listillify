import 'package:equatable/equatable.dart';
import 'package:listillify/core/errors/failures.dart';
import 'package:listillify/core/result/result.dart';
import 'package:listillify/core/usecases/usecase.dart';
import 'package:listillify/features/playlist/domain/entities/playlist_creation_result.dart';
import 'package:listillify/features/playlist/domain/repositories/playlist_repository.dart';

/// Parámetros de entrada para [CreateSpotifyPlaylistUseCase].
class CreateSpotifyPlaylistParams extends Equatable {
  final String userId;
  final String playlistName;
  final String? description;
  final bool isPublic;
  final List<String> trackUris;
  final String accessToken;
  final List<String> failedQueries;

  const CreateSpotifyPlaylistParams({
    required this.userId,
    required this.playlistName,
    this.description,
    this.isPublic = false,
    required this.trackUris,
    required this.accessToken,
    this.failedQueries = const [],
  });

  @override
  List<Object?> get props => [
        userId,
        playlistName,
        description,
        isPublic,
        trackUris,
        accessToken,
        failedQueries,
      ];
}

/// PATRÓN DE DISEÑO: Command Pattern / Use Case Interactor
/// Caso de uso que crea la playlist en la cuenta de Spotify del usuario y agrega las pistas seleccionadas.
class CreateSpotifyPlaylistUseCase
    implements UseCase<PlaylistCreationResult, CreateSpotifyPlaylistParams> {
  final PlaylistRepository playlistRepository;

  CreateSpotifyPlaylistUseCase({required this.playlistRepository});

  @override
  Future<Result<PlaylistCreationResult>> call(CreateSpotifyPlaylistParams params) async {
    final trimmedName = params.playlistName.trim();
    if (trimmedName.isEmpty) {
      return const FailureResult(
        ValidationFailure(message: 'El nombre de la playlist no puede estar vacío.'),
      );
    }

    if (params.trackUris.isEmpty) {
      return const FailureResult(
        ValidationFailure(message: 'Debes seleccionar al menos una canción para la playlist.'),
      );
    }

    // 1. Crear la playlist en Spotify
    final createResult = await playlistRepository.createPlaylist(
      userId: params.userId,
      name: trimmedName,
      accessToken: params.accessToken,
      description: params.description ?? 'Playlist generada automáticamente con Listillify',
      isPublic: params.isPublic,
    );

    if (createResult.isFailure) {
      return FailureResult(createResult.failureOrNull!);
    }

    final playlistId = createResult.dataOrNull!;

    // 2. Añadir las pistas a la playlist recién creada
    final addResult = await playlistRepository.addTracksToPlaylist(
      playlistId: playlistId,
      trackUris: params.trackUris,
      accessToken: params.accessToken,
    );

    if (addResult.isFailure) {
      return FailureResult(addResult.failureOrNull!);
    }

    final totalAdded = addResult.dataOrNull ?? 0;
    final playlistUrl = 'https://open.spotify.com/playlist/$playlistId';

    return Success(
      PlaylistCreationResult(
        playlistId: playlistId,
        playlistName: trimmedName,
        playlistUrl: playlistUrl,
        totalTracksAdded: totalAdded,
        failedQueries: params.failedQueries,
      ),
    );
  }
}
