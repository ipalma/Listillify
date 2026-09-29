import 'package:flutter_test/flutter_test.dart';
import 'package:listillify/core/errors/failures.dart';
import 'package:listillify/core/result/result.dart';
import 'package:listillify/features/playlist/domain/entities/track_item.dart';
import 'package:listillify/features/playlist/domain/repositories/playlist_repository.dart';
import 'package:listillify/features/playlist/domain/services/playlist_text_parser.dart';
import 'package:listillify/features/playlist/domain/usecases/create_spotify_playlist_use_case.dart';
import 'package:listillify/features/playlist/domain/usecases/parse_and_search_tracks_use_case.dart';
import 'package:mocktail/mocktail.dart';

class MockPlaylistRepository extends Mock implements PlaylistRepository {}
class MockPlaylistTextParser extends Mock implements PlaylistTextParser {}

void main() {
  late MockPlaylistRepository mockRepository;
  late ParseAndSearchTracksUseCase searchUseCase;
  late CreateSpotifyPlaylistUseCase createUseCase;

  const tTrack = TrackItem(
    id: 'track_1',
    title: 'Bohemian Rhapsody',
    artist: 'Queen',
    uri: 'spotify:track:track_1',
    rawQuery: 'Queen - Bohemian Rhapsody',
  );

  setUp(() {
    mockRepository = MockPlaylistRepository();
    searchUseCase = ParseAndSearchTracksUseCase(
      playlistRepository: mockRepository,
      textParser: PlaylistTextParser(),
    );
    createUseCase = CreateSpotifyPlaylistUseCase(playlistRepository: mockRepository);
  });

  group('ParseAndSearchTracksUseCase', () {
    test('returns list of TrackItem when search succeeds', () async {
      when(() => mockRepository.searchTrack(
            query: 'Queen - Bohemian Rhapsody',
            accessToken: 'token_123',
          )).thenAnswer((_) async => const Success(tTrack));

      final result = await searchUseCase(
        const ParseAndSearchTracksParams(
          rawText: 'Queen - Bohemian Rhapsody',
          accessToken: 'token_123',
        ),
      );

      expect(result.isSuccess, isTrue);
      final tracks = result.dataOrNull!;
      expect(tracks.length, equals(1));
      expect(tracks.first.title, equals('Bohemian Rhapsody'));
    });

    test('marks item as notFound when search returns null', () async {
      when(() => mockRepository.searchTrack(
            query: 'Cancion Rara 999',
            accessToken: 'token_123',
          )).thenAnswer((_) async => const Success(null));

      final result = await searchUseCase(
        const ParseAndSearchTracksParams(
          rawText: 'Cancion Rara 999',
          accessToken: 'token_123',
        ),
      );

      expect(result.isSuccess, isTrue);
      final tracks = result.dataOrNull!;
      expect(tracks.first.isFound, isFalse);
    });

    test('returns AuthFailure immediately when search fails with AuthFailure', () async {
      when(() => mockRepository.searchTrack(
            query: any(named: 'query'),
            accessToken: any(named: 'accessToken'),
          )).thenAnswer((_) async => const FailureResult(AuthFailure(message: 'Unauthorized', statusCode: 401)));

      final result = await searchUseCase(
        const ParseAndSearchTracksParams(
          rawText: 'Queen - Bohemian Rhapsody',
          accessToken: 'token_123',
        ),
      );

      expect(result.isFailure, isTrue);
      expect(result.failureOrNull, isA<AuthFailure>());
    });

    test('returns ValidationFailure when input text is empty', () async {
      final result = await searchUseCase(
        const ParseAndSearchTracksParams(
          rawText: '   ',
          accessToken: 'token_123',
        ),
      );

      expect(result.isFailure, isTrue);
      expect(result.failureOrNull, isA<ValidationFailure>());
    });
  });

  group('CreateSpotifyPlaylistUseCase', () {
    test('creates playlist and adds tracks returning PlaylistCreationResult', () async {
      when(() => mockRepository.createPlaylist(
            userId: 'user_1',
            name: 'Mi Playlist',
            accessToken: 'token_123',
            description: any(named: 'description'),
            isPublic: false,
          )).thenAnswer((_) async => const Success('created_playlist_id'));

      when(() => mockRepository.addTracksToPlaylist(
            playlistId: 'created_playlist_id',
            trackUris: ['spotify:track:track_1'],
            accessToken: 'token_123',
          )).thenAnswer((_) async => const Success(1));

      final result = await createUseCase(
        const CreateSpotifyPlaylistParams(
          userId: 'user_1',
          playlistName: 'Mi Playlist',
          trackUris: ['spotify:track:track_1'],
          accessToken: 'token_123',
        ),
      );

      expect(result.isSuccess, isTrue);
      final creationResult = result.dataOrNull!;
      expect(creationResult.playlistId, equals('created_playlist_id'));
      expect(creationResult.totalTracksAdded, equals(1));
      expect(creationResult.playlistUrl, contains('created_playlist_id'));
    });

    test('returns ValidationFailure when name is empty', () async {
      final result = await createUseCase(
        const CreateSpotifyPlaylistParams(
          userId: 'user_1',
          playlistName: '  ',
          trackUris: ['spotify:track:1'],
          accessToken: 'tok',
        ),
      );

      expect(result.isFailure, isTrue);
      expect(result.failureOrNull, isA<ValidationFailure>());
    });

    test('returns ValidationFailure when trackUris list is empty', () async {
      final result = await createUseCase(
        const CreateSpotifyPlaylistParams(
          userId: 'user_1',
          playlistName: 'Playlist Sin Canciones',
          trackUris: [],
          accessToken: 'tok',
        ),
      );

      expect(result.isFailure, isTrue);
      expect(result.failureOrNull, isA<ValidationFailure>());
    });
  });
}
