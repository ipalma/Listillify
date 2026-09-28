import 'package:flutter_test/flutter_test.dart';
import 'package:listillify/core/errors/failures.dart';
import 'package:listillify/core/result/result.dart';
import 'package:listillify/core/usecases/usecase.dart';
import 'package:listillify/features/auth/domain/entities/user_session.dart';
import 'package:listillify/features/auth/domain/repositories/auth_repository.dart';
import 'package:listillify/features/auth/domain/usecases/get_current_session_use_case.dart';
import 'package:listillify/features/auth/domain/usecases/login_use_case.dart';
import 'package:listillify/features/auth/domain/usecases/logout_use_case.dart';
import 'package:mocktail/mocktail.dart';

class MockAuthRepository extends Mock implements AuthRepository {}

void main() {
  late MockAuthRepository mockRepository;
  late LoginUseCase loginUseCase;
  late GetCurrentSessionUseCase getSessionUseCase;
  late LogoutUseCase logoutUseCase;

  setUp(() {
    mockRepository = MockAuthRepository();
    loginUseCase = LoginUseCase(mockRepository);
    getSessionUseCase = GetCurrentSessionUseCase(mockRepository);
    logoutUseCase = LogoutUseCase(mockRepository);
  });

  group('LoginUseCase', () {
    final tSession = UserSession(
      id: 'user_test',
      displayName: 'Test User',
      accessToken: 'token_123',
      expiresAt: DateTime.now().add(const Duration(hours: 1)),
    );

    test('should return UserSession when repository login succeeds', () async {
      when(() => mockRepository.login('valid_client_id'))
          .thenAnswer((_) async => Success(tSession));

      final result = await loginUseCase(const LoginParams(clientId: 'valid_client_id'));

      expect(result, equals(Success(tSession)));
      verify(() => mockRepository.login('valid_client_id')).called(1);
    });

    test('should return ValidationFailure when clientId is empty', () async {
      final result = await loginUseCase(const LoginParams(clientId: '  '));

      expect(result.isFailure, isTrue);
      expect(result.failureOrNull, isA<ValidationFailure>());
      verifyZeroInteractions(mockRepository);
    });

    test('should propagate AuthFailure when repository login fails', () async {
      const failure = AuthFailure(message: 'Login rechazado');
      when(() => mockRepository.login('valid_client_id'))
          .thenAnswer((_) async => const FailureResult(failure));

      final result = await loginUseCase(const LoginParams(clientId: 'valid_client_id'));

      expect(result, equals(const FailureResult<UserSession>(failure)));
    });
  });

  group('GetCurrentSessionUseCase', () {
    test('should return current session from repository', () async {
      final tSession = UserSession(
        id: 'u1',
        displayName: 'User 1',
        accessToken: 'tok',
        expiresAt: DateTime.now().add(const Duration(hours: 1)),
      );
      when(() => mockRepository.getCurrentSession())
          .thenAnswer((_) async => Success(tSession));

      final result = await getSessionUseCase(const NoParams());

      expect(result, equals(Success(tSession)));
      verify(() => mockRepository.getCurrentSession()).called(1);
    });
  });

  group('LogoutUseCase', () {
    test('should call repository logout successfully', () async {
      when(() => mockRepository.logout())
          .thenAnswer((_) async => const Success(null));

      final result = await logoutUseCase(const NoParams());

      expect(result, equals(const Success<void>(null)));
      verify(() => mockRepository.logout()).called(1);
    });
  });
}
