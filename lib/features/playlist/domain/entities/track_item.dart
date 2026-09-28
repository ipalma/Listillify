import 'package:equatable/equatable.dart';

/// PATRÓN DE DISEÑO: Value Object / Entity
/// Representa una pista musical o episodio de podcast identificado en Spotify.
class TrackItem extends Equatable {
  final String id;
  final String title;
  final String artist;
  final String uri;
  final String? albumName;
  final String? albumImageUrl;
  final Duration? duration;
  final bool isFound;
  final String rawQuery;

  const TrackItem({
    required this.id,
    required this.title,
    required this.artist,
    required this.uri,
    this.albumName,
    this.albumImageUrl,
    this.duration,
    this.isFound = true,
    required this.rawQuery,
  });

  /// Crea una representación para una pista que no pudo ser encontrada en Spotify.
  factory TrackItem.notFound(String rawQuery) {
    return TrackItem(
      id: '',
      title: rawQuery,
      artist: 'No encontrado en Spotify',
      uri: '',
      isFound: false,
      rawQuery: rawQuery,
    );
  }

  /// Retorna la duración formateada en mm:ss (ej. 03:45).
  String get formattedDuration {
    if (duration == null) return '--:--';
    final minutes = duration!.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = duration!.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  TrackItem copyWith({
    String? id,
    String? title,
    String? artist,
    String? uri,
    String? albumName,
    String? albumImageUrl,
    Duration? duration,
    bool? isFound,
    String? rawQuery,
  }) {
    return TrackItem(
      id: id ?? this.id,
      title: title ?? this.title,
      artist: artist ?? this.artist,
      uri: uri ?? this.uri,
      albumName: albumName ?? this.albumName,
      albumImageUrl: albumImageUrl ?? this.albumImageUrl,
      duration: duration ?? this.duration,
      isFound: isFound ?? this.isFound,
      rawQuery: rawQuery ?? this.rawQuery,
    );
  }

  @override
  List<Object?> get props => [
        id,
        title,
        artist,
        uri,
        albumName,
        albumImageUrl,
        duration,
        isFound,
        rawQuery,
      ];
}
