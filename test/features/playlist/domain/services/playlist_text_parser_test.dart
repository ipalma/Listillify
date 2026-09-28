import 'package:flutter_test/flutter_test.dart';
import 'package:listillify/features/playlist/domain/services/playlist_text_parser.dart';

void main() {
  group('PlaylistTextParser', () {
    late PlaylistTextParser parser;

    setUp(() {
      parser = PlaylistTextParser();
    });

    test('should parse artist and song format lines correctly', () {
      const input = '''
Queen - Bohemian Rhapsody
Pink Floyd - Time
AC/DC - Highway to Hell
''';
      final results = parser.parse(input);

      expect(results.length, equals(3));
      expect(results[0].query, equals('Queen - Bohemian Rhapsody'));
      expect(results[1].query, equals('Pink Floyd - Time'));
      expect(results[2].query, equals('AC/DC - Highway to Hell'));
      expect(results[0].isDirectUri, isFalse);
    });

    test('should clean numbered lists and bullet points', () {
      const input = '''
1. Queen - Don't Stop Me Now
2) The Beatles - Hey Jude
- Nirvana - Come As You Are
* Led Zeppelin - Kashmir
• David Bowie - Heroes
''';
      final results = parser.parse(input);

      expect(results.length, equals(5));
      expect(results[0].query, equals("Queen - Don't Stop Me Now"));
      expect(results[1].query, equals('The Beatles - Hey Jude'));
      expect(results[2].query, equals('Nirvana - Come As You Are'));
      expect(results[3].query, equals('Led Zeppelin - Kashmir'));
      expect(results[4].query, equals('David Bowie - Heroes'));
    });

    test('should recognize and extract Spotify web URLs', () {
      const input = '''
https://open.spotify.com/track/4cOdK2wGLETKBW3PvgPWqT?si=abc123xyz
https://open.spotify.com/episode/5V7Y8d7X4F6L1w2z3a4b5c
''';
      final results = parser.parse(input);

      expect(results.length, equals(2));
      expect(results[0].isDirectUri, isTrue);
      expect(results[0].directUri, equals('spotify:track:4cOdK2wGLETKBW3PvgPWqT'));
      expect(results[1].isDirectUri, isTrue);
      expect(results[1].directUri, equals('spotify:episode:5V7Y8d7X4F6L1w2z3a4b5c'));
    });

    test('should recognize native Spotify URIs', () {
      const input = '''
spotify:track:11dFghVXANMlKmJXsNCbNl
spotify:episode:34ghVXANMlKmJXsNCbNl
''';
      final results = parser.parse(input);

      expect(results.length, equals(2));
      expect(results[0].isDirectUri, isTrue);
      expect(results[0].directUri, equals('spotify:track:11dFghVXANMlKmJXsNCbNl'));
      expect(results[1].isDirectUri, isTrue);
      expect(results[1].directUri, equals('spotify:episode:34ghVXANMlKmJXsNCbNl'));
    });

    test('should ignore blank lines and whitespace', () {
      const input = '''

   
Queen - Radio Ga Ga

   
Metallica - Enter Sandman
   
''';
      final results = parser.parse(input);

      expect(results.length, equals(2));
      expect(results[0].query, equals('Queen - Radio Ga Ga'));
      expect(results[1].query, equals('Metallica - Enter Sandman'));
    });
  });
}
