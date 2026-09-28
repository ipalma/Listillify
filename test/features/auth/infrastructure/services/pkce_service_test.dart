import 'package:flutter_test/flutter_test.dart';
import 'package:listillify/features/auth/infrastructure/services/pkce_service.dart';

void main() {
  group('PkceService', () {
    late PkceService pkceService;

    setUp(() {
      pkceService = PkceService();
    });

    test('generateCodeVerifier creates URL-safe string of desired length', () {
      final verifier64 = pkceService.generateCodeVerifier(64);
      final verifier128 = pkceService.generateCodeVerifier(128);

      expect(verifier64.length, equals(64));
      expect(verifier128.length, equals(128));

      // Caracteres permitidos por RFC 7636: [A-Za-z0-9-._~]
      final validRegex = RegExp(r'^[A-Za-z0-9\-._~]+$');
      expect(validRegex.hasMatch(verifier64), isTrue);
      expect(validRegex.hasMatch(verifier128), isTrue);
    });

    test('generateCodeChallenge produces valid base64url string without padding', () {
      // Vector de prueba conocido RFC 7636:
      // verifier: dBjftJeZ4CVP-mB92K27uhbUJU1p1r_wW1gFWFOEjXk
      // challenge: E9Melhoa2OwvFrEMTJguCHaoeK1t8URWbuGJSstw-cM
      const testVerifier = 'dBjftJeZ4CVP-mB92K27uhbUJU1p1r_wW1gFWFOEjXk';
      final challenge = pkceService.generateCodeChallenge(testVerifier);

      expect(challenge, equals('E9Melhoa2OwvFrEMTJguCHaoeK1t8URWbuGJSstw-cM'));
      expect(challenge.contains('='), isFalse);
    });

    test('generateState creates non-empty random string', () {
      final state1 = pkceService.generateState(32);
      final state2 = pkceService.generateState(32);

      expect(state1.length, equals(32));
      expect(state2.length, equals(32));
      expect(state1, isNot(equals(state2)));
    });
  });
}
