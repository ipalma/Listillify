import 'package:equatable/equatable.dart';
import 'package:listillify/features/playlist/domain/entities/playlist_creation_result.dart';
import 'package:listillify/features/playlist/domain/entities/track_item.dart';

/// PATRÓN DE DISEÑO: State Pattern
/// Modela los estados del flujo de creación de playlists (formulario, búsqueda, previsualización, creación, éxito).
sealed class PlaylistState extends Equatable {
  const PlaylistState();

  @override
  List<Object?> get props => [];
}

/// Estado inicial: formulario vacío listo para introducir datos.
final class PlaylistInitial extends PlaylistState {
  const PlaylistInitial();
}

/// Estado de procesamiento: buscando pistas en Spotify con información de progreso.
final class PlaylistSearching extends PlaylistState {
  final int current;
  final int total;
  final String currentItem;

  const PlaylistSearching({
    required this.current,
    required this.total,
    required this.currentItem,
  });

  double get progress => total > 0 ? current / total : 0.0;

  @override
  List<Object?> get props => [current, total, currentItem];
}

/// Estado de previsualización: las canciones han sido resueltas y el usuario puede revisar/desmarcar antes de crear.
final class PlaylistPreviewReady extends PlaylistState {
  final String playlistName;
  final String? description;
  final bool isPublic;
  final List<TrackItem> tracks;
  final Set<String> selectedUris;

  const PlaylistPreviewReady({
    required this.playlistName,
    this.description,
    this.isPublic = false,
    required this.tracks,
    required this.selectedUris,
  });

  int get foundCount => tracks.where((t) => t.isFound).length;
  int get notFoundCount => tracks.where((t) => !t.isFound).length;
  int get selectedCount => selectedUris.length;

  PlaylistPreviewReady copyWith({
    String? playlistName,
    String? description,
    bool? isPublic,
    List<TrackItem>? tracks,
    Set<String>? selectedUris,
  }) {
    return PlaylistPreviewReady(
      playlistName: playlistName ?? this.playlistName,
      description: description ?? this.description,
      isPublic: isPublic ?? this.isPublic,
      tracks: tracks ?? this.tracks,
      selectedUris: selectedUris ?? this.selectedUris,
    );
  }

  @override
  List<Object?> get props => [
        playlistName,
        description,
        isPublic,
        tracks,
        selectedUris,
      ];
}

/// Estado de creación en curso en la API de Spotify.
final class PlaylistCreating extends PlaylistState {
  final String message;

  const PlaylistCreating({this.message = 'Creando playlist en Spotify...'});

  @override
  List<Object?> get props => [message];
}

/// Estado de éxito: la playlist fue creada y las pistas añadidas.
final class PlaylistCreatedSuccess extends PlaylistState {
  final PlaylistCreationResult result;

  const PlaylistCreatedSuccess(this.result);

  @override
  List<Object?> get props => [result];
}

/// Estado de fallo al buscar o crear la playlist.
final class PlaylistFailureState extends PlaylistState {
  final String message;

  const PlaylistFailureState(this.message);

  @override
  List<Object?> get props => [message];
}
