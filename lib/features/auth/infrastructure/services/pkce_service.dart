import 'dart:convert';
import 'dart:math';
import 'package:crypto/crypto.dart';

/// PATRÓN DE DISEÑO: Service / Factory
/// Servicio utilitario para generar parámetros criptográficos según la especificación
/// RFC 7636 para OAuth 2.0 PKCE (Proof Key for Code Exchange).
class PkceService {
  static const String _charset =
      'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789-._~';

  final Random _random;

  PkceService({Random? random}) : _random = random ?? Random.secure();

  /// Genera un [code_verifier] seguro y aleatorio con la longitud especificada (por defecto 64 caracteres).
  String generateCodeVerifier([int length = 64]) {
    assert(length >= 43 && length <= 128, 'code_verifier length must be between 43 and 128');
    return List.generate(length, (_) => _charset[_random.nextInt(_charset.length)]).join();
  }

  /// Calcula el [code_challenge] aplicando SHA-256 sobre el [verifier] y codificándolo en Base64URL sin padding.
  String generateCodeChallenge(String verifier) {
    final bytes = utf8.encode(verifier);
    final digest = sha256.convert(bytes);
    // Base64Url sin padding '='
    return base64Url.encode(digest.bytes).replaceAll('=', '');
  }

  /// Genera una cadena aleatoria para el parámetro `state` anti-CSRF.
  String generateState([int length = 32]) {
    return List.generate(length, (_) => _charset[_random.nextInt(_charset.length)]).join();
  }
}
