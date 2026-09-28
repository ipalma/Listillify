import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:listillify/core/errors/failures.dart';
import 'package:listillify/core/result/result.dart';
import 'package:listillify/core/usecases/usecase.dart';
import 'package:listillify/features/auth/domain/entities/user_session.dart';
import 'package:listillify/features/auth/domain/usecases/get_current_session_use_case.dart';
import 'package:listillify/features/auth/domain/usecases/login_use_case.dart';
import 'package:listillify/features/auth/domain/usecases/logout_use_case.dart';
import 'package:listillify/features/auth/presentation/cubit/auth_cubit.dart';
import 'package:listillify/features/auth/presentation/cubit/auth_state.dart';
import 'package:mocktail/mocktail.dart';

class MockLoginUseCase extends Mock implements LoginUseCase {}
class MockGetCurrentSessionUseCase extends Mock implements GetCurrentSessionUseCase {}
class MockLogoutUseCase extends Mock implements LogoutUseCase {}

void main() {
  late MockLoginUseCase mockLoginUseCase;
  late MockGetCurrentSessionUseCase mockGetSessionUseCase;
  late MockLogoutUseCase mockLogoutUseCase;
  late AuthCubit cubit;

  final tSession = UserSession(
    id: 'user_123',
    displayName: 'Juan Perez',
    accessToken: 'valid_access_token',
    expiresAt: DateTime.now().add(const Duration(hours: 1)),
  );

  setUpAll(() {
    registerFallbackValue(const NoParams());
    registerFallbackValue(const LoginParams(clientId: 'id'));
  });

  setUp(() {
    mockLoginUseCase = MockLoginUseCase();
    mockGetSessionUseCase = MockGetCurrentSessionUseCase();
    mockLogoutUseCase = MockLogoutUseCase();

    cubit = AuthCubit(
      loginUseCase: mockLoginUseCase,
      getCurrentSessionUseCase: mockGetSessionUseCase,
      logoutUseCase: mockLogoutUseCase,
    );
  });

  tearDown(() {
    cubit.close();
  });

  group('AuthCubit', () {
    test('initial state should be AuthInitial', () {
      expect(cubit.state, equals(const AuthInitial()));
    });

    blocTest<AuthCubit, AuthState>(
      'checkAuthStatus emits [AuthLoading, Authenticated] when session is valid',
      build: () {
        when(() => mockGetSessionUseCase(any()))
            .thenAnswer((_) async => Success(tSession));
        return cubit;
      },
      act: (c) => c.checkAuthStatus(),
      expect: () => [
        const AuthLoading(message: 'Verificando sesión...'),
        Authenticated(tSession),
      ],
    );

    blocTest<AuthCubit, AuthState>(
      'checkAuthStatus emits [AuthLoading, Unauthenticated] when no session found',
      build: () {
        when(() => mockGetSessionUseCase(any()))
            .thenAnswer((_) async => const Success(null));
        return cubit;
      },
      act: (c) => c.checkAuthStatus(),
      expect: () => [
        const AuthLoading(message: 'Verificando sesión...'),
        const Unauthenticated(),
      ],
    );

    blocTest<AuthCubit, AuthState>(
      'login emits [AuthLoading, Authenticated] on successful authentication',
      build: () {
        when(() => mockLoginUseCase(any()))
            .thenAnswer((_) async => Success(tSession));
        return cubit;
      },
      act: (c) => c.login('client_123'),
      expect: () => [
        const AuthLoading(message: 'Abriendo Spotify para iniciar sesión...'),
        Authenticated(tSession),
      ],
    );

    blocTest<AuthCubit, AuthState>(
      'login emits [AuthLoading, AuthError] when login fails',
      build: () {
        when(() => mockLoginUseCase(any()))
            .thenAnswer((_) async => const FailureResult(AuthFailure(message: 'Acceso denegado')));
        return cubit;
      },
      act: (c) => c.login('client_123'),
      expect: () => [
        const AuthLoading(message: 'Abriendo Spotify para iniciar sesión...'),
        const AuthError('Acceso denegado'),
      ],
    );

    blocTest<AuthCubit, AuthState>(
      'logout emits [AuthLoading, Unauthenticated] on successful logout',
      build: () {
        when(() => mockLogoutUseCase(any()))
            .thenAnswer((_) async => const Success(null));
        return cubit;
      },
      act: (c) => c.logout(),
      expect: () => [
        const AuthLoading(message: 'Cerrando sesión...'),
        const Unauthenticated(),
      ],
    );
  });
}
