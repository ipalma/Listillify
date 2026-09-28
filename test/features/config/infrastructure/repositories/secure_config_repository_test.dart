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
    test('getConfig should return stored ApiConfig when client id exists', () async {
      when(() => mockStorage.read(key: SpotifyConstants.secureStorageClientIdKey))
          .thenAnswer((_) async => 'stored_client_123');

      final result = await repository.getConfig();

      expect(result.isSuccess, isTrue);
      expect(result.dataOrNull?.clientId, equals('stored_client_123'));
      verify(() => mockStorage.read(key: SpotifyConstants.secureStorageClientIdKey)).called(1);
    });

    test('getConfig should return empty ApiConfig when key does not exist', () async {
      when(() => mockStorage.read(key: SpotifyConstants.secureStorageClientIdKey))
          .thenAnswer((_) async => null);

      final result = await repository.getConfig();

      expect(result.isSuccess, isTrue);
      expect(result.dataOrNull?.isValid, isFalse);
    });

    test('getConfig should return StorageFailure when exception occurs', () async {
      when(() => mockStorage.read(key: SpotifyConstants.secureStorageClientIdKey))
          .thenThrow(Exception('Storage error'));

      final result = await repository.getConfig();

      expect(result.isFailure, isTrue);
      expect(result.failureOrNull, isA<StorageFailure>());
    });

    test('saveConfig should write client id to secure storage', () async {
      when(() => mockStorage.write(
            key: SpotifyConstants.secureStorageClientIdKey,
            value: 'new_client_id',
          )).thenAnswer((_) async => Future.value());

      final result = await repository.saveConfig(const ApiConfig(clientId: 'new_client_id'));

      expect(result.isSuccess, isTrue);
      verify(() => mockStorage.write(
            key: SpotifyConstants.secureStorageClientIdKey,
            value: 'new_client_id',
          )).called(1);
    });

    test('clearConfig should delete client id from secure storage', () async {
      when(() => mockStorage.delete(key: SpotifyConstants.secureStorageClientIdKey))
          .thenAnswer((_) async => Future.value());

      final result = await repository.clearConfig();

      expect(result.isSuccess, isTrue);
      verify(() => mockStorage.delete(key: SpotifyConstants.secureStorageClientIdKey)).called(1);
    });
  });
}
