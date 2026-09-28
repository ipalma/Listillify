import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:listillify/core/constants/spotify_constants.dart';
import 'package:listillify/core/errors/failures.dart';
import 'package:listillify/features/auth/infrastructure/repositories/spotify_auth_repository.dart';
import 'package:listillify/features/auth/infrastructure/services/oauth_callback_server.dart';
import 'package:listillify/features/auth/infrastructure/services/pkce_service.dart';
import 'package:mocktail/mocktail.dart';

class MockHttpClient extends Mock implements http.Client {}
class MockFlutterSecureStorage extends Mock implements FlutterSecureStorage {}
class MockPkceService extends Mock implements PkceService {}
class MockOAuthCallbackServer extends Mock implements OAuthCallbackServer {}

void main() {
  late MockHttpClient mockHttpClient;
  late MockFlutterSecureStorage mockStorage;
  late MockPkceService mockPkceService;
  late MockOAuthCallbackServer mockCallbackServer;
  late SpotifyAuthRepository repository;

  setUpAll(() {
    registerFallbackValue(Uri.parse('https://example.com'));
  });

  setUp(() {
    mockHttpClient = MockHttpClient();
    mockStorage = MockFlutterSecureStorage();
    mockPkceService = MockPkceService();
    mockCallbackServer = MockOAuthCallbackServer();

    repository = SpotifyAuthRepository(
      httpClient: mockHttpClient,
      storage: mockStorage,
      pkceService: mockPkceService,
      callbackServer: mockCallbackServer,
      urlLauncher: (uri) async => true,
    );
  });

  group('SpotifyAuthRepository', () {
    test('login flow should authenticate, exchange tokens and return UserSession', () async {
      when(() => mockPkceService.generateCodeVerifier()).thenReturn('test_verifier');
      when(() => mockPkceService.generateCodeChallenge('test_verifier')).thenReturn('test_challenge');
      when(() => mockPkceService.generateState()).thenReturn('test_state');

      when(() => mockCallbackServer.waitForAuthorizationCode(expectedState: 'test_state'))
          .thenAnswer((_) async => 'auth_code_123');

      // Token response
      final tokenJson = jsonEncode({
        'access_token': 'spotify_access_123',
        'refresh_token': 'spotify_refresh_456',
        'expires_in': 3600,
      });
      when(() => mockHttpClient.post(
            Uri.parse(SpotifyConstants.tokenEndpoint),
            headers: any(named: 'headers'),
            body: any(named: 'body'),
          )).thenAnswer((_) async => http.Response(tokenJson, 200));

      // Profile response
      final profileJson = jsonEncode({
        'id': 'spotify_user_001',
        'display_name': 'Test Display',
        'email': 'test@spotify.com',
        'images': [
          {'url': 'https://image.spotify.com/avatar.jpg'}
        ],
      });
      when(() => mockHttpClient.get(
            Uri.parse('${SpotifyConstants.apiBaseUrl}/me'),
            headers: any(named: 'headers'),
          )).thenAnswer((_) async => http.Response(profileJson, 200));

      // Storage writes
      when(() => mockStorage.write(key: any(named: 'key'), value: any(named: 'value')))
          .thenAnswer((_) async => Future.value());

      final result = await repository.login('client_id_abc');

      expect(result.isSuccess, isTrue);
      final session = result.dataOrNull!;
      expect(session.id, equals('spotify_user_001'));
      expect(session.displayName, equals('Test Display'));
      expect(session.accessToken, equals('spotify_access_123'));
      expect(session.refreshToken, equals('spotify_refresh_456'));
      expect(session.avatarUrl, equals('https://image.spotify.com/avatar.jpg'));
    });

    test('getCurrentSession returns UserSession when storage has token and user id', () async {
      when(() => mockStorage.read(key: SpotifyConstants.secureStorageAccessTokenKey))
          .thenAnswer((_) async => 'saved_access_token');
      when(() => mockStorage.read(key: SpotifyConstants.secureStorageUserIdKey))
          .thenAnswer((_) async => 'saved_user_id');
      when(() => mockStorage.read(key: SpotifyConstants.secureStorageUserDisplayNameKey))
          .thenAnswer((_) async => 'Saved Name');
      when(() => mockStorage.read(key: SpotifyConstants.secureStorageRefreshTokenKey))
          .thenAnswer((_) async => 'saved_refresh_token');
      when(() => mockStorage.read(key: SpotifyConstants.secureStorageTokenExpiresAtKey))
          .thenAnswer((_) async => DateTime.now().add(const Duration(hours: 1)).toIso8601String());

      final result = await repository.getCurrentSession();

      expect(result.isSuccess, isTrue);
      expect(result.dataOrNull?.id, equals('saved_user_id'));
      expect(result.dataOrNull?.accessToken, equals('saved_access_token'));
    });

    test('logout deletes stored tokens', () async {
      when(() => mockStorage.delete(key: any(named: 'key')))
          .thenAnswer((_) async => Future.value());

      final result = await repository.logout();

      expect(result.isSuccess, isTrue);
      verify(() => mockStorage.delete(key: SpotifyConstants.secureStorageAccessTokenKey)).called(1);
      verify(() => mockStorage.delete(key: SpotifyConstants.secureStorageRefreshTokenKey)).called(1);
    });

    test('login returns AuthFailure when token exchange returns HTTP 400', () async {
      when(() => mockPkceService.generateCodeVerifier()).thenReturn('test_verifier');
      when(() => mockPkceService.generateCodeChallenge('test_verifier')).thenReturn('test_challenge');
      when(() => mockPkceService.generateState()).thenReturn('test_state');
      when(() => mockCallbackServer.waitForAuthorizationCode(expectedState: 'test_state'))
          .thenAnswer((_) async => 'bad_auth_code');

      when(() => mockHttpClient.post(
            Uri.parse(SpotifyConstants.tokenEndpoint),
            headers: any(named: 'headers'),
            body: any(named: 'body'),
          )).thenAnswer((_) async => http.Response('Invalid authorization code', 400));

      final result = await repository.login('client_id_abc');

      expect(result.isFailure, isTrue);
      expect(result.failureOrNull, isA<AuthFailure>());
    });
  });
}
