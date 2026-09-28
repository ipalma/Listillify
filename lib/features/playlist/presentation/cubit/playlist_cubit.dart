import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:listillify/features/playlist/domain/usecases/create_spotify_playlist_use_case.dart';
import 'package:listillify/features/playlist/domain/usecases/parse_and_search_tracks_use_case.dart';
import 'package:listillify/features/playlist/presentation/cubit/playlist_state.dart';

/// PATRÓN DE DISEÑO: Observer / Presentation Controller (BLoC / Cubit)
/// Orquesta el ciclo de vida completo de la creación de una playlist:
/// validación de texto, búsqueda en Spotify, selección en vista previa interactiva y llamada de creación.
class PlaylistCubit extends Cubit<PlaylistState> {
  final ParseAndSearchTracksUseCase parseAndSearchTracksUseCase;
  final CreateSpotifyPlaylistUseCase createSpotifyPlaylistUseCase;

  PlaylistCubit({
    required this.parseAndSearchTracksUseCase,
    required this.createSpotifyPlaylistUseCase,
  }) : super(const PlaylistInitial());

  /// Procesa el texto multilínea y busca cada canción en Spotify mostrando el progreso.
  Future<void> searchTracks({
    required String playlistName,
    required String rawText,
    required String accessToken,
    String? description,
    bool isPublic = false,
  }) async {
    final trimmedName = playlistName.trim();
    if (trimmedName.isEmpty) {
      emit(const PlaylistFailureState('Por favor, indica un nombre para la playlist.'));
      return;
    }

    emit(const PlaylistSearching(current: 0, total: 0, currentItem: 'Analizando texto...'));

    final result = await parseAndSearchTracksUseCase(
      ParseAndSearchTracksParams(
        rawText: rawText,
        accessToken: accessToken,
        onProgress: (current, total, currentItem) {
          emit(PlaylistSearching(
            current: current,
            total: total,
            currentItem: currentItem,
          ));
        },
      ),
    );

    result.when(
      onSuccess: (tracks) {
        // Seleccionamos inicialmente todas las canciones encontradas con URI válido
        final initialSelected = tracks
            .where((t) => t.isFound && t.uri.isNotEmpty)
            .map((t) => t.uri)
            .toSet();

        emit(PlaylistPreviewReady(
          playlistName: trimmedName,
          description: description,
          isPublic: isPublic,
          tracks: tracks,
          selectedUris: initialSelected,
        ));
      },
      onFailure: (failure) => emit(PlaylistFailureState(failure.message)),
    );
  }

  /// Alterna la selección de una pista individual en la vista previa.
  void toggleTrackSelection(String uri) {
    final currentState = state;
    if (currentState is PlaylistPreviewReady) {
      final updatedSet = Set<String>.from(currentState.selectedUris);
      if (updatedSet.contains(uri)) {
        updatedSet.remove(uri);
      } else {
        updatedSet.add(uri);
      }
      emit(currentState.copyWith(selectedUris: updatedSet));
    }
  }

  /// Selecciona o deselecciona todas las canciones encontradas.
  void toggleSelectAll() {
    final currentState = state;
    if (currentState is PlaylistPreviewReady) {
      final allFoundUris = currentState.tracks
          .where((t) => t.isFound && t.uri.isNotEmpty)
          .map((t) => t.uri)
          .toSet();

      final areAllSelected = currentState.selectedUris.length == allFoundUris.length;

      emit(currentState.copyWith(
        selectedUris: areAllSelected ? <String>{} : allFoundUris,
      ));
    }
  }

  /// Ejecuta la creación de la playlist y el envío por lotes en Spotify.
  Future<void> confirmAndCreatePlaylist({
    required String userId,
    required String accessToken,
  }) async {
    final currentState = state;
    if (currentState is! PlaylistPreviewReady) return;

    if (currentState.selectedUris.isEmpty) {
      emit(const PlaylistFailureState('Debes seleccionar al menos una pista antes de crear la playlist.'));
      return;
    }

    emit(const PlaylistCreating(message: 'Creando playlist y agregando canciones en Spotify...'));

    final failedQueries = currentState.tracks
        .where((t) => !t.isFound)
        .map((t) => t.rawQuery)
        .toList();

    final result = await createSpotifyPlaylistUseCase(
      CreateSpotifyPlaylistParams(
        userId: userId,
        playlistName: currentState.playlistName,
        description: currentState.description,
        isPublic: currentState.isPublic,
        trackUris: currentState.selectedUris.toList(),
        accessToken: accessToken,
        failedQueries: failedQueries,
      ),
    );

    result.when(
      onSuccess: (creationResult) => emit(PlaylistCreatedSuccess(creationResult)),
      onFailure: (failure) => emit(PlaylistFailureState(failure.message)),
    );
  }

  /// Reinicia el formulario para crear una nueva lista.
  void reset() {
    emit(const PlaylistInitial());
  }
}
