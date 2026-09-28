import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:listillify/core/result/result.dart';
import 'package:listillify/features/playlist/domain/entities/playlist_creation_result.dart';
import 'package:listillify/features/playlist/domain/entities/track_item.dart';
import 'package:listillify/features/playlist/domain/usecases/create_spotify_playlist_use_case.dart';
import 'package:listillify/features/playlist/domain/usecases/parse_and_search_tracks_use_case.dart';
import 'package:listillify/features/playlist/presentation/cubit/playlist_cubit.dart';
import 'package:listillify/features/playlist/presentation/cubit/playlist_state.dart';
import 'package:mocktail/mocktail.dart';

class MockParseAndSearchTracksUseCase extends Mock implements ParseAndSearchTracksUseCase {}
class MockCreateSpotifyPlaylistUseCase extends Mock implements CreateSpotifyPlaylistUseCase {}

void main() {
  late MockParseAndSearchTracksUseCase mockSearchUseCase;
  late MockCreateSpotifyPlaylistUseCase mockCreateUseCase;
  late PlaylistCubit cubit;

  const tTrack = TrackItem(
    id: 't1',
    title: 'Song 1',
    artist: 'Artist 1',
    uri: 'spotify:track:t1',
    rawQuery: 'Song 1',
  );

  setUpAll(() {
    registerFallbackValue(const ParseAndSearchTracksParams(rawText: '', accessToken: ''));
    registerFallbackValue(const CreateSpotifyPlaylistParams(
      userId: 'u',
      playlistName: 'p',
      trackUris: [],
      accessToken: 'a',
    ));
  });

  setUp(() {
    mockSearchUseCase = MockParseAndSearchTracksUseCase();
    mockCreateUseCase = MockCreateSpotifyPlaylistUseCase();
    cubit = PlaylistCubit(
      parseAndSearchTracksUseCase: mockSearchUseCase,
      createSpotifyPlaylistUseCase: mockCreateUseCase,
    );
  });

  tearDown(() {
    cubit.close();
  });

  group('PlaylistCubit', () {
    test('initial state is PlaylistInitial', () {
      expect(cubit.state, equals(const PlaylistInitial()));
    });

    blocTest<PlaylistCubit, PlaylistState>(
      'searchTracks emits [PlaylistSearching, PlaylistPreviewReady] when search succeeds',
      build: () {
        when(() => mockSearchUseCase(any()))
            .thenAnswer((_) async => const Success([tTrack]));
        return cubit;
      },
      act: (c) => c.searchTracks(
        playlistName: 'Rock Classics',
        rawText: 'Song 1',
        accessToken: 'token_123',
      ),
      expect: () => [
        const PlaylistSearching(current: 0, total: 0, currentItem: 'Analizando texto...'),
        const PlaylistPreviewReady(
          playlistName: 'Rock Classics',
          description: null,
          isPublic: false,
          tracks: [tTrack],
          selectedUris: {'spotify:track:t1'},
        ),
      ],
    );

    blocTest<PlaylistCubit, PlaylistState>(
      'toggleTrackSelection modifies selectedUris set',
      build: () => cubit,
      seed: () => const PlaylistPreviewReady(
        playlistName: 'Rock Classics',
        tracks: [tTrack],
        selectedUris: {'spotify:track:t1'},
      ),
      act: (c) => c.toggleTrackSelection('spotify:track:t1'),
      expect: () => [
        const PlaylistPreviewReady(
          playlistName: 'Rock Classics',
          tracks: [tTrack],
          selectedUris: {},
        ),
      ],
    );

    blocTest<PlaylistCubit, PlaylistState>(
      'confirmAndCreatePlaylist emits [PlaylistCreating, PlaylistCreatedSuccess] on success',
      build: () {
        when(() => mockCreateUseCase(any())).thenAnswer(
          (_) async => const Success(
            PlaylistCreationResult(
              playlistId: 'pl_1',
              playlistName: 'Rock',
              playlistUrl: 'https://open.spotify.com/playlist/pl_1',
              totalTracksAdded: 1,
            ),
          ),
        );
        return cubit;
      },
      seed: () => const PlaylistPreviewReady(
        playlistName: 'Rock',
        tracks: [tTrack],
        selectedUris: {'spotify:track:t1'},
      ),
      act: (c) => c.confirmAndCreatePlaylist(userId: 'user_1', accessToken: 'tok'),
      expect: () => [
        const PlaylistCreating(message: 'Creando playlist y agregando canciones en Spotify...'),
        const PlaylistCreatedSuccess(
          PlaylistCreationResult(
            playlistId: 'pl_1',
            playlistName: 'Rock',
            playlistUrl: 'https://open.spotify.com/playlist/pl_1',
            totalTracksAdded: 1,
          ),
        ),
      ],
    );

    blocTest<PlaylistCubit, PlaylistState>(
      'reset returns state to PlaylistInitial',
      build: () => cubit,
      seed: () => const PlaylistCreatedSuccess(
        PlaylistCreationResult(
          playlistId: 'pl_1',
          playlistName: 'Rock',
          playlistUrl: '',
          totalTracksAdded: 1,
        ),
      ),
      act: (c) => c.reset(),
      expect: () => [
        const PlaylistInitial(),
      ],
    );
  });
}
