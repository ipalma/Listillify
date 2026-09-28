import 'dart:async';
import 'dart:io';
import 'package:listillify/core/constants/spotify_constants.dart';
import 'package:listillify/core/errors/failures.dart';

/// PATRÓN DE DISEÑO: Adapter / Service
/// Servidor local temporal para capturar el callback de OAuth de Spotify en plataformas de escritorio (Windows).
class OAuthCallbackServer {
  HttpServer? _server;

  /// Inicia la escucha local y espera el código de autorización devuelto por Spotify.
  Future<String> waitForAuthorizationCode({
    required String expectedState,
    Duration timeout = const Duration(minutes: 3),
  }) async {
    final completer = Completer<String>();

    try {
      _server = await HttpServer.bind(
        InternetAddress.loopbackIPv4,
        SpotifyConstants.windowsLocalServerPort,
        shared: true,
      );

      _server!.listen((HttpRequest request) async {
        final uri = request.uri;

        if (uri.path == '/callback') {
          final error = uri.queryParameters['error'];
          final state = uri.queryParameters['state'];
          final code = uri.queryParameters['code'];

          if (error != null) {
            _respondHtml(
              request,
              statusCode: HttpStatus.badRequest,
              title: 'Error de Autenticación',
              message: 'Spotify denegó o canceló el acceso: $error',
              isSuccess: false,
            );
            if (!completer.isCompleted) {
              completer.completeError(AuthFailure(message: 'Acceso denegado por Spotify: $error'));
            }
            await close();
            return;
          }

          if (state != expectedState) {
            _respondHtml(
              request,
              statusCode: HttpStatus.badRequest,
              title: 'Error de Seguridad',
              message: 'El parámetro state no coincide (posible ataque CSRF).',
              isSuccess: false,
            );
            if (!completer.isCompleted) {
              completer.completeError(const AuthFailure(message: 'Validación de estado CSRF fallida.'));
            }
            await close();
            return;
          }

          if (code != null) {
            _respondHtml(
              request,
              statusCode: HttpStatus.ok,
              title: '¡Autenticación Exitosa!',
              message: 'Has iniciado sesión correctamente. Ya puedes volver a Listillify.',
              isSuccess: true,
            );
            if (!completer.isCompleted) {
              completer.complete(code);
            }
            await close();
            return;
          }
        }

        // Cualquier otra ruta
        request.response
          ..statusCode = HttpStatus.notFound
          ..write('Not Found')
          ..close();
      });

      return await completer.future.timeout(
        timeout,
        onTimeout: () {
          close();
          throw const AuthFailure(
            message: 'Tiempo de espera de autenticación agotado. Por favor, inténtalo de nuevo.',
          );
        },
      );
    } catch (e) {
      await close();
      if (e is AuthFailure) rethrow;
      throw AuthFailure(message: 'No se pudo iniciar el servidor local de autenticación: $e');
    }
  }

  void _respondHtml(
    HttpRequest request, {
    required int statusCode,
    required String title,
    required String message,
    required bool isSuccess,
  }) {
    final color = isSuccess ? '#1DB954' : '#E91429';
    final html = '''
<!DOCTYPE html>
<html lang="es">
<head>
  <meta charset="UTF-8">
  <title>$title - Listillify</title>
  <style>
    body {
      background-color: #121212;
      color: #FFFFFF;
      font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, sans-serif;
      display: flex;
      justify-content: center;
      align-items: center;
      height: 100vh;
      margin: 0;
    }
    .card {
      background-color: #282828;
      padding: 40px;
      border-radius: 12px;
      text-align: center;
      max-width: 440px;
      box-shadow: 0 8px 24px rgba(0,0,0,0.5);
    }
    h1 { color: $color; margin-top: 0; font-size: 24px; }
    p { color: #B3B3B3; font-size: 16px; line-height: 1.5; }
  </style>
</head>
<body>
  <div class="card">
    <h1>$title</h1>
    <p>$message</p>
  </div>
</body>
</html>
''';

    request.response
      ..statusCode = statusCode
      ..headers.contentType = ContentType.html
      ..write(html)
      ..close();
  }

  /// Cierra el servidor HTTP local si está activo.
  Future<void> close() async {
    try {
      await _server?.close(force: true);
    } catch (_) {}
    _server = null;
  }
}
