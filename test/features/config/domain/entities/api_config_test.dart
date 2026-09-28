import 'package:flutter_test/flutter_test.dart';
import 'package:listillify/features/config/domain/entities/api_config.dart';

void main() {
  group('ApiConfig Entity', () {
    test('should properly validate when clientId and clientSecret are valid', () {
      const config = ApiConfig(clientId: 'abc123xyz', clientSecret: 'secret_456');
      expect(config.isValid, isTrue);
      expect(config.clientId, equals('abc123xyz'));
      expect(config.clientSecret, equals('secret_456'));
    });

    test('should invalidate when clientId or clientSecret is empty or blank', () {
      const config1 = ApiConfig(clientId: '', clientSecret: 'secret');
      const config2 = ApiConfig(clientId: 'id', clientSecret: '   ');
      const emptyConfig = ApiConfig.empty();

      expect(config1.isValid, isFalse);
      expect(config2.isValid, isFalse);
      expect(emptyConfig.isValid, isFalse);
    });

    test('should support value equality via Equatable', () {
      const config1 = ApiConfig(clientId: 'id', clientSecret: 'sec');
      const config2 = ApiConfig(clientId: 'id', clientSecret: 'sec');
      const config3 = ApiConfig(clientId: 'id', clientSecret: 'other_sec');

      expect(config1, equals(config2));
      expect(config1 == config3, isFalse);
    });

    test('copyWith should create a modified clone', () {
      const config = ApiConfig(clientId: 'id', clientSecret: 'sec');
      final updated = config.copyWith(clientSecret: 'new_sec');

      expect(updated.clientId, equals('id'));
      expect(updated.clientSecret, equals('new_sec'));
    });
  });
}
