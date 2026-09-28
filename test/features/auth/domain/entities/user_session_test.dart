import 'package:flutter_test/flutter_test.dart';
import 'package:listillify/features/auth/domain/entities/user_session.dart';

void main() {
  group('UserSession Entity', () {
    final now = DateTime.now();

    test('isExpired should be false when expiresAt is in the future', () {
      final session = UserSession(
        id: 'user_123',
        displayName: 'Test User',
        accessToken: 'access_token_abc',
        expiresAt: now.add(const Duration(hours: 1)),
      );

      expect(session.isExpired, isFalse);
      expect(session.isAuthenticated, isTrue);
    });

    test('isExpired should be true when expiresAt is in the past', () {
      final session = UserSession(
        id: 'user_123',
        displayName: 'Test User',
        accessToken: 'access_token_abc',
        expiresAt: now.subtract(const Duration(minutes: 5)),
      );

      expect(session.isExpired, isTrue);
      expect(session.isAuthenticated, isFalse);
    });

    test('isAuthenticated should be false when accessToken is empty', () {
      final session = UserSession(
        id: 'user_123',
        displayName: 'Test User',
        accessToken: '',
        expiresAt: now.add(const Duration(hours: 1)),
      );

      expect(session.isAuthenticated, isFalse);
    });

    test('supports value equality with Equatable', () {
      final session1 = UserSession(
        id: 'user_123',
        displayName: 'Test User',
        accessToken: 'token_1',
        expiresAt: now,
      );
      final session2 = UserSession(
        id: 'user_123',
        displayName: 'Test User',
        accessToken: 'token_1',
        expiresAt: now,
      );

      expect(session1, equals(session2));
    });

    test('copyWith modifies attributes properly', () {
      final session = UserSession(
        id: 'user_123',
        displayName: 'Old Name',
        accessToken: 'token_1',
        expiresAt: now,
      );

      final updated = session.copyWith(displayName: 'New Name');
      expect(updated.displayName, equals('New Name'));
      expect(updated.id, equals('user_123'));
    });
  });
}
