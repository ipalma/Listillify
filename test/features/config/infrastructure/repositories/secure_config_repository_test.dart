import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:listillify/core/constants/spotify_constants.dart';
import 'package:listillify/core/errors/failures.dart';
import 'package:listillify/features/config/domain/entities/api_config.dart';
import 'package:listillify/features/config/infrastructure/repositories/secure_config_repository.dart';
import 'package:mocktail/mocktail.dart';

class MockFlutterSecureStorage extends Mock implements FlutterSecureStorage {}

void main() {
  late MockFlutterSecureStorage mockStorage;
  late SecureConfigRepository repository;

  setUp(() {
    mockStorage = MockFlutterSecureStorage();
    repository = SecureConfigRepository(storage: mockStorage);
  });

  group('SecureConfigRepository', () {
    test('getConfig should return stored ApiConfig when client id and secret exist', () async {
      when(() => mockStorage.read(key: SpotifyConstants.secureStorageClientIdKey))
          .thenAnswer((_) async => 'stored_client_123');
      when(() => mockStorage.read(key: SpotifyConstants.secureStorageClientSecretKey))
          .thenAnswer((_) async => 'stored_secret_456');

      final result = await repository.getConfig();

      expect(result.isSuccess, isTrue);
      expect(result.dataOrNull?.clientId, equals('stored_client_123'));
      expect(result.dataOrNull?.clientSecret, equals('stored_secret_456'));
      verify(() => mockStorage.read(key: SpotifyConstants.secureStorageClientIdKey)).called(1);
      verify(() => mockStorage.read(key: SpotifyConstants.secureStorageClientSecretKey)).called(1);
    });

    test('getConfig should return empty ApiConfig when key does not exist', () async {
      when(() => mockStorage.read(key: SpotifyConstants.secureStorageClientIdKey))
          .thenAnswer((_) async => null);
      when(() => mockStorage.read(key: SpotifyConstants.secureStorageClientSecretKey))
          .thenAnswer((_) async => null);

      final result = await repository.getConfig();

      expect(result.isSuccess, isTrue);
      expect(result.dataOrNull?.isValid, isFalse);
    });

    test('getConfig should return StorageFailure when exception occurs', () async {
      when(() => mockStorage.read(key: any(named: 'key')))
          .thenThrow(Exception('Storage error'));

      final result = await repository.getConfig();

      expect(result.isFailure, isTrue);
      expect(result.failureOrNull, isA<StorageFailure>());
    });

    test('saveConfig should write client id and client secret to secure storage', () async {
      when(() => mockStorage.write(
            key: any(named: 'key'),
            value: any(named: 'value'),
          )).thenAnswer((_) async => Future.value());

      final result = await repository.saveConfig(
        const ApiConfig(clientId: 'new_client_id', clientSecret: 'new_secret'),
      );

      expect(result.isSuccess, isTrue);
      verify(() => mockStorage.write(
            key: SpotifyConstants.secureStorageClientIdKey,
            value: 'new_client_id',
          )).called(1);
      verify(() => mockStorage.write(
            key: SpotifyConstants.secureStorageClientSecretKey,
            value: 'new_secret',
          )).called(1);
    });

    test('clearConfig should delete client id and secret from secure storage', () async {
      when(() => mockStorage.delete(key: any(named: 'key')))
          .thenAnswer((_) async => Future.value());

      final result = await repository.clearConfig();

      expect(result.isSuccess, isTrue);
      verify(() => mockStorage.delete(key: SpotifyConstants.secureStorageClientIdKey)).called(1);
      verify(() => mockStorage.delete(key: SpotifyConstants.secureStorageClientSecretKey)).called(1);
    });
  });
}
