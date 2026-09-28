import 'package:flutter_test/flutter_test.dart';
import 'package:listillify/features/config/domain/entities/api_config.dart';

void main() {
  group('ApiConfig Entity', () {
    test('should properly validate when clientId is valid and not empty', () {
      const config = ApiConfig(clientId: 'abc123xyz');
      expect(config.isValid, isTrue);
      expect(config.clientId, equals('abc123xyz'));
    });

    test('should invalidate when clientId is empty or blank', () {
      const config1 = ApiConfig(clientId: '');
      const config2 = ApiConfig(clientId: '   ');
      const emptyConfig = ApiConfig.empty();

      expect(config1.isValid, isFalse);
      expect(config2.isValid, isFalse);
      expect(emptyConfig.isValid, isFalse);
    });

    test('should support value equality via Equatable', () {
      const config1 = ApiConfig(clientId: 'test_client_id');
      const config2 = ApiConfig(clientId: 'test_client_id');
      const config3 = ApiConfig(clientId: 'different_client_id');

      expect(config1, equals(config2));
      expect(config1 == config3, isFalse);
    });

    test('copyWith should create a modified clone', () {
      const config = ApiConfig(clientId: 'original_id', customRedirectUri: 'uri1');
      final updated = config.copyWith(clientId: 'updated_id');

      expect(updated.clientId, equals('updated_id'));
      expect(updated.customRedirectUri, equals('uri1'));
    });
  });
}
