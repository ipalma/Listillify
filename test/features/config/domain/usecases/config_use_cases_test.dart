import 'package:flutter_test/flutter_test.dart';
import 'package:listillify/core/errors/failures.dart';
import 'package:listillify/core/result/result.dart';
import 'package:listillify/core/usecases/usecase.dart';
import 'package:listillify/features/config/domain/entities/api_config.dart';
import 'package:listillify/features/config/domain/repositories/config_repository.dart';
import 'package:listillify/features/config/domain/usecases/get_api_config_use_case.dart';
import 'package:listillify/features/config/domain/usecases/save_api_config_use_case.dart';
import 'package:mocktail/mocktail.dart';

class MockConfigRepository extends Mock implements ConfigRepository {}

void main() {
  late MockConfigRepository mockRepository;
  late GetApiConfigUseCase getUseCase;
  late SaveApiConfigUseCase saveUseCase;

  setUp(() {
    mockRepository = MockConfigRepository();
    getUseCase = GetApiConfigUseCase(mockRepository);
    saveUseCase = SaveApiConfigUseCase(mockRepository);
  });

  group('GetApiConfigUseCase', () {
    test('should return ApiConfig from repository when successful', () async {
      const expectedConfig = ApiConfig(clientId: 'spotify_client_123', clientSecret: 'sec_123');
      when(() => mockRepository.getConfig())
          .thenAnswer((_) async => const Success(expectedConfig));

      final result = await getUseCase(const NoParams());

      expect(result, equals(const Success(expectedConfig)));
      verify(() => mockRepository.getConfig()).called(1);
      verifyNoMoreInteractions(mockRepository);
    });

    test('should propagate Failure when repository fails', () async {
      const failure = StorageFailure(message: 'Error al leer disco');
      when(() => mockRepository.getConfig())
          .thenAnswer((_) async => const FailureResult(failure));

      final result = await getUseCase(const NoParams());

      expect(result, equals(const FailureResult(failure)));
      verify(() => mockRepository.getConfig()).called(1);
    });
  });

  group('SaveApiConfigUseCase', () {
    test('should save configuration when ApiConfig is valid', () async {
      const validConfig = ApiConfig(clientId: 'valid_client_id_456', clientSecret: 'valid_secret');
      when(() => mockRepository.saveConfig(validConfig))
          .thenAnswer((_) async => const Success(null));

      final result = await saveUseCase(const SaveApiConfigParams(config: validConfig));

      expect(result, equals(const Success<void>(null)));
      verify(() => mockRepository.saveConfig(validConfig)).called(1);
    });

    test('should return ValidationFailure without calling repository when clientId or clientSecret is empty', () async {
      const invalidConfig1 = ApiConfig(clientId: '   ', clientSecret: 'secret');
      const invalidConfig2 = ApiConfig(clientId: 'id', clientSecret: '');

      final result1 = await saveUseCase(const SaveApiConfigParams(config: invalidConfig1));
      final result2 = await saveUseCase(const SaveApiConfigParams(config: invalidConfig2));

      expect(result1.isFailure, isTrue);
      expect(result1.failureOrNull, isA<ValidationFailure>());
      expect(result2.isFailure, isTrue);
      expect(result2.failureOrNull, isA<ValidationFailure>());
      verifyZeroInteractions(mockRepository);
    });
  });
}
