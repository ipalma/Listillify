import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:listillify/core/constants/spotify_constants.dart';
import 'package:listillify/core/errors/failures.dart';
import 'package:listillify/features/config/domain/entities/api_config.dart';
import 'package:listillify/features/config/infrastructure/repositories/hive_config_repository.dart';
import 'package:mocktail/mocktail.dart';

class MockBox extends Mock implements Box<dynamic> {}
class MockFlutterSecureStorage extends Mock implements FlutterSecureStorage {}

void main() {
  late MockBox mockBox;
  late MockFlutterSecureStorage mockStorage;
  late HiveConfigRepository repository;

  setUp(() {
    mockBox = MockBox();
    mockStorage = MockFlutterSecureStorage();
    repository = HiveConfigRepository(box: mockBox, storage: mockStorage);

    when(() => mockBox.flush()).thenAnswer((_) async {});
    when(() => mockStorage.read(key: any(named: 'key'))).thenAnswer((_) async => null);
    when(() => mockStorage.write(key: any(named: 'key'), value: any(named: 'value')))
        .thenAnswer((_) async {});
    when(() => mockStorage.delete(key: any(named: 'key'))).thenAnswer((_) async {});
  });

  group('HiveConfigRepository', () {
    test('getConfig should return stored ApiConfig when client id and secret exist', () async {
      when(() => mockBox.get(SpotifyConstants.hiveClientIdKey)).thenReturn('test_client_id');
      when(() => mockBox.get(SpotifyConstants.hiveClientSecretKey)).thenReturn('test_client_secret');

      final result = await repository.getConfig();

      expect(result.isSuccess, isTrue);
      expect(result.dataOrNull?.clientId, 'test_client_id');
      expect(result.dataOrNull?.clientSecret, 'test_client_secret');
    });

    test('getConfig should return empty ApiConfig when clientId is null or empty', () async {
      when(() => mockBox.get(SpotifyConstants.hiveClientIdKey)).thenReturn(null);
      when(() => mockBox.get(SpotifyConstants.hiveClientSecretKey)).thenReturn(null);

      final result = await repository.getConfig();

      expect(result.isSuccess, isTrue);
      expect(result.dataOrNull?.isValid, isFalse);
    });

    test('getConfig should return StorageFailure when box throws exception', () async {
      when(() => mockBox.get(any())).thenThrow(Exception('Hive read error'));

      final result = await repository.getConfig();

      expect(result.isFailure, isTrue);
      expect(result.failureOrNull, isA<StorageFailure>());
    });

    test('saveConfig should write client id and client secret to Hive box', () async {
      when(() => mockBox.put(any(), any())).thenAnswer((_) async {});

      const config = ApiConfig(clientId: 'my_id', clientSecret: 'my_secret');
      final result = await repository.saveConfig(config);

      expect(result.isSuccess, isTrue);
      verify(() => mockBox.put(SpotifyConstants.hiveClientIdKey, 'my_id')).called(1);
      verify(() => mockBox.put(SpotifyConstants.hiveClientSecretKey, 'my_secret')).called(1);
      verify(() => mockBox.flush()).called(1);
    });

    test('clearConfig should delete client id and secret from Hive box', () async {
      when(() => mockBox.delete(any())).thenAnswer((_) async {});

      final result = await repository.clearConfig();

      expect(result.isSuccess, isTrue);
      verify(() => mockBox.delete(SpotifyConstants.hiveClientIdKey)).called(1);
      verify(() => mockBox.delete(SpotifyConstants.hiveClientSecretKey)).called(1);
      verify(() => mockBox.flush()).called(1);
    });
  });
}
