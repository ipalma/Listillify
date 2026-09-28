import 'package:equatable/equatable.dart';

/// PATRÓN DE DISEÑO: Value Object / Result Data
/// Encapsula los detalles y estadísticas resultantes de la creación de una playlist en Spotify.
class PlaylistCreationResult extends Equatable {
  final String playlistId;
  final String playlistName;
  final String playlistUrl;
  final int totalTracksAdded;
  final List<String> failedQueries;

  const PlaylistCreationResult({
    required this.playlistId,
    required this.playlistName,
    required this.playlistUrl,
    required this.totalTracksAdded,
    this.failedQueries = const [],
  });

  @override
  List<Object?> get props => [
        playlistId,
        playlistName,
        playlistUrl,
        totalTracksAdded,
        failedQueries,
      ];
}
