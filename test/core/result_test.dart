import 'package:flutter_test/flutter_test.dart';
import 'package:listillify/core/errors/failures.dart';
import 'package:listillify/core/result/result.dart';

void main() {
  group('Result Pattern Tests', () {
    test('Success should identify as success and hold data', () {
      const result = Success<String>('playlist_123');

      expect(result.isSuccess, isTrue);
      expect(result.isFailure, isFalse);
      expect(result.dataOrNull, equals('playlist_123'));
      expect(result.failureOrNull, isNull);

      final mapped = result.when(
        onSuccess: (data) => 'Valor: $data',
        onFailure: (failure) => 'Error: ${failure.message}',
      );
      expect(mapped, equals('Valor: playlist_123'));
    });

    test('FailureResult should identify as failure and hold Failure', () {
      const failure = ServerFailure(message: 'Error de servidor 500', statusCode: 500);
      const result = FailureResult<String>(failure);

      expect(result.isSuccess, isFalse);
      expect(result.isFailure, isTrue);
      expect(result.dataOrNull, isNull);
      expect(result.failureOrNull, equals(failure));

      final mapped = result.when(
        onSuccess: (data) => 'Valor: $data',
        onFailure: (f) => 'Error: ${f.message}',
      );
      expect(mapped, equals('Error: Error de servidor 500'));
    });

    test('Equatable equality should work correctly for Result and Failure', () {
      const failure1 = AuthFailure(message: 'Token expirado', statusCode: 401);
      const failure2 = AuthFailure(message: 'Token expirado', statusCode: 401);
      const failure3 = AuthFailure(message: 'Distinto mensaje', statusCode: 401);

      expect(failure1, equals(failure2));
      expect(failure1 == failure3, isFalse);

      const res1 = FailureResult<int>(failure1);
      const res2 = FailureResult<int>(failure2);
      expect(res1, equals(res2));
    });

    test('RateLimitFailure should contain retryAfterSeconds and equality check', () {
      const rateLimit1 = RateLimitFailure(message: 'Too many requests', retryAfterSeconds: 30);
      const rateLimit2 = RateLimitFailure(message: 'Too many requests', retryAfterSeconds: 30);
      const rateLimit3 = RateLimitFailure(message: 'Too many requests', retryAfterSeconds: 15);

      expect(rateLimit1.statusCode, equals(429));
      expect(rateLimit1.retryAfterSeconds, equals(30));
      expect(rateLimit1, equals(rateLimit2));
      expect(rateLimit1 == rateLimit3, isFalse);
    });
  });
}
