import 'package:listillify/features/playlist/domain/entities/parsed_query.dart';

/// PATRÓN DE DISEÑO: Domain Service / Strategy
/// Servicio de dominio para parsear y normalizar el texto introducido por el usuario.
/// Extrae consultas de búsqueda limpias o URIs directas de Spotify eliminando viñetas y numeraciones.
class PlaylistTextParser {
  static final RegExp _numberedPrefixRegex = RegExp(r'^\s*(\d+[\.\)\-]|[\*\-\•])\s+');
  static final RegExp _spotifyUrlRegex =
      RegExp(r'https?:\/\/open\.spotify\.com\/(track|episode)\/([a-zA-Z0-9]+)');
  static final RegExp _spotifyUriRegex =
      RegExp(r'^spotify:(track|episode):([a-zA-Z0-9]+)$');

  /// Parsea un texto con múltiples líneas y produce una lista de [ParsedQuery].
  List<ParsedQuery> parse(String text) {
    final lines = text.split('\n');
    final results = <ParsedQuery>[];

    for (var i = 0; i < lines.length; i++) {
      final raw = lines[i].trim();
      if (raw.isEmpty) continue;

      // 1. Verificar si es una URI nativa de Spotify: spotify:track:xyz
      final uriMatch = _spotifyUriRegex.firstMatch(raw);
      if (uriMatch != null) {
        results.add(
          ParsedQuery(
            rawText: raw,
            query: raw,
            directUri: raw,
            lineNumber: i + 1,
          ),
        );
        continue;
      }

      // 2. Verificar si es un enlace de Spotify: https://open.spotify.com/track/xyz?si=...
      final urlMatch = _spotifyUrlRegex.firstMatch(raw);
      if (urlMatch != null) {
        final type = urlMatch.group(1); // 'track' o 'episode'
        final id = urlMatch.group(2); // ID de Spotify
        final directUri = 'spotify:$type:$id';
        results.add(
          ParsedQuery(
            rawText: raw,
            query: raw,
            directUri: directUri,
            lineNumber: i + 1,
          ),
        );
        continue;
      }

      // 3. Limpiar prefijos de listas numeradas ("1.", "1)", "- ", "* ", "• ")
      var cleaned = raw.replaceFirst(_numberedPrefixRegex, '').trim();

      if (cleaned.isNotEmpty) {
        results.add(
          ParsedQuery(
            rawText: raw,
            query: cleaned,
            directUri: null,
            lineNumber: i + 1,
          ),
        );
      }
    }

    return results;
  }
}
