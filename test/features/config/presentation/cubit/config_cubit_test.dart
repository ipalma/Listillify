import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:listillify/core/errors/failures.dart';
import 'package:listillify/core/result/result.dart';
import 'package:listillify/core/usecases/usecase.dart';
import 'package:listillify/features/config/domain/entities/api_config.dart';
import 'package:listillify/features/config/domain/usecases/get_api_config_use_case.dart';
import 'package:listillify/features/config/domain/usecases/save_api_config_use_case.dart';
import 'package:listillify/features/config/presentation/cubit/config_cubit.dart';
import 'package:listillify/features/config/presentation/cubit/config_state.dart';
import 'package:mocktail/mocktail.dart';

class MockGetApiConfigUseCase extends Mock implements GetApiConfigUseCase {}
class MockSaveApiConfigUseCase extends Mock implements SaveApiConfigUseCase {}

void main() {
  late MockGetApiConfigUseCase mockGetUseCase;
  late MockSaveApiConfigUseCase mockSaveUseCase;
  late ConfigCubit cubit;

  setUpAll(() {
    registerFallbackValue(const NoParams());
    registerFallbackValue(const SaveApiConfigParams(config: ApiConfig.empty()));
  });

  setUp(() {
    mockGetUseCase = MockGetApiConfigUseCase();
    mockSaveUseCase = MockSaveApiConfigUseCase();
    cubit = ConfigCubit(
      getApiConfigUseCase: mockGetUseCase,
      saveApiConfigUseCase: mockSaveUseCase,
    );
  });

  tearDown(() {
    cubit.close();
  });

  group('ConfigCubit', () {
    test('initial state should be ConfigInitial', () {
      expect(cubit.state, equals(const ConfigInitial()));
    });

    blocTest<ConfigCubit, ConfigState>(
      'emits [ConfigLoading, ConfigLoaded] when loadConfig succeeds',
      build: () {
        when(() => mockGetUseCase(any()))
            .thenAnswer((_) async => const Success(ApiConfig(clientId: 'id_123')));
        return cubit;
      },
      act: (c) => c.loadConfig(),
      expect: () => [
        const ConfigLoading(),
        const ConfigLoaded(ApiConfig(clientId: 'id_123')),
      ],
    );

    blocTest<ConfigCubit, ConfigState>(
      'emits [ConfigLoading, ConfigError] when loadConfig fails',
      build: () {
        when(() => mockGetUseCase(any()))
            .thenAnswer((_) async => const FailureResult(StorageFailure(message: 'Storage error')));
        return cubit;
      },
      act: (c) => c.loadConfig(),
      expect: () => [
        const ConfigLoading(),
        const ConfigError('Storage error'),
      ],
    );

    blocTest<ConfigCubit, ConfigState>(
      'emits [ConfigLoading, ConfigSavedSuccess] when saveConfig succeeds',
      build: () {
        when(() => mockSaveUseCase(any()))
            .thenAnswer((_) async => const Success(null));
        return cubit;
      },
      act: (c) => c.saveConfig('valid_id'),
      expect: () => [
        const ConfigLoading(),
        const ConfigSavedSuccess(ApiConfig(clientId: 'valid_id')),
      ],
    );

    blocTest<ConfigCubit, ConfigState>(
      'emits [ConfigLoading, ConfigError] when saveConfig fails with ValidationFailure',
      build: () {
        when(() => mockSaveUseCase(any()))
            .thenAnswer((_) async => const FailureResult(ValidationFailure(message: 'ID no válido')));
        return cubit;
      },
      act: (c) => c.saveConfig(''),
      expect: () => [
        const ConfigLoading(),
        const ConfigError('ID no válido'),
      ],
    );
  });
}
