import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:listillify/core/errors/failures.dart';
import 'package:listillify/features/playlist/infrastructure/repositories/spotify_playlist_repository.dart';
import 'package:mocktail/mocktail.dart';

class MockHttpClient extends Mock implements http.Client {}

void main() {
  late MockHttpClient mockClient;
  late SpotifyPlaylistRepository repository;

  setUpAll(() {
    registerFallbackValue(Uri.parse('https://example.com'));
  });

  setUp(() {
    mockClient = MockHttpClient();
    repository = SpotifyPlaylistRepository(httpClient: mockClient);
  });

  group('SpotifyPlaylistRepository', () {
    test('searchTrack parses track from JSON correctly', () async {
      final jsonResponse = jsonEncode({
        'tracks': {
          'items': [
            {
              'id': 'track_abc',
              'name': 'Wish You Were Here',
              'uri': 'spotify:track:track_abc',
              'duration_ms': 334000,
              'artists': [
                {'name': 'Pink Floyd'}
              ],
              'album': {
                'name': 'Wish You Were Here',
                'images': [
                  {'url': 'https://image.spotify.com/album.jpg'}
                ],
              },
            }
          ]
        }
      });

      when(() => mockClient.get(any(), headers: any(named: 'headers')))
          .thenAnswer((_) async => http.Response(jsonResponse, 200));

      final result = await repository.searchTrack(
        query: 'Pink Floyd - Wish You Were Here',
        accessToken: 'valid_token',
      );

      expect(result.isSuccess, isTrue);
      final track = result.dataOrNull!;
      expect(track.id, equals('track_abc'));
      expect(track.title, equals('Wish You Were Here'));
      expect(track.artist, equals('Pink Floyd'));
      expect(track.albumName, equals('Wish You Were Here'));
      expect(track.isFound, isTrue);
    });

    test('searchTrack handles 429 RateLimitFailure with retry-after header', () async {
      when(() => mockClient.get(any(), headers: any(named: 'headers'))).thenAnswer(
        (_) async => http.Response('Rate limited', 429, headers: {'retry-after': '12'}),
      );

      final result = await repository.searchTrack(
        query: 'Song',
        accessToken: 'token',
      );

      expect(result.isFailure, isTrue);
      expect(result.failureOrNull, isA<RateLimitFailure>());
      final rateLimit = result.failureOrNull as RateLimitFailure;
      expect(rateLimit.retryAfterSeconds, equals(12));
    });

    test('createPlaylist sends POST and returns playlist ID', () async {
      final createJson = jsonEncode({'id': 'new_playlist_id_789'});
      when(() => mockClient.post(
            any(),
            headers: any(named: 'headers'),
            body: any(named: 'body'),
          )).thenAnswer((_) async => http.Response(createJson, 201));

      final result = await repository.createPlaylist(
        userId: 'user_xyz',
        name: 'My Custom List',
        accessToken: 'token_abc',
      );

      expect(result.isSuccess, isTrue);
      expect(result.dataOrNull, equals('new_playlist_id_789'));
    });

    test('addTracksToPlaylist batches tracks in chunks of 100 max', () async {
      // Creamos 150 URIs para forzar 2 lotes (100 + 50)
      final trackUris = List.generate(150, (i) => 'spotify:track:track_$i');

      when(() => mockClient.post(
            any(),
            headers: any(named: 'headers'),
            body: any(named: 'body'),
          )).thenAnswer((_) async => http.Response('{"snapshot_id": "snap"}', 201));

      final result = await repository.addTracksToPlaylist(
        playlistId: 'playlist_123',
        trackUris: trackUris,
        accessToken: 'token_abc',
      );

      expect(result.isSuccess, isTrue);
      expect(result.dataOrNull, equals(150));
      // Verificamos que se hayan realizado exactamente 2 llamadas por lotes
      verify(() => mockClient.post(
            any(),
            headers: any(named: 'headers'),
            body: any(named: 'body'),
          )).called(2);
    });
  });
}
