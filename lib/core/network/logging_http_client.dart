import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:listillify/core/logging/app_logger.dart';

/// PATRÓN DE DISEÑO: Decorator / Proxy
/// Intercepta todas las peticiones y respuestas HTTP de la aplicación, registrándolas en [AppLogger].
class LoggingHttpClient extends http.BaseClient {
  final http.Client _inner;

  LoggingHttpClient({http.Client? inner}) : _inner = inner ?? http.Client();

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    final startTime = DateTime.now();
    String? requestBody;

    if (request is http.Request) {
      requestBody = request.body;
    }

    AppLogger.instance.logHttp(
      method: request.method,
      uri: request.url,
      headers: request.headers,
      body: requestBody,
    );

    try {
      final streamedResponse = await _inner.send(request);
      final duration = DateTime.now().difference(startTime);

      // Leemos el stream para registrar el cuerpo de la respuesta sin romper el consumo posterior
      final bytes = await streamedResponse.stream.toBytes();
      final responseBody = utf8.decode(bytes, allowMalformed: true);

      AppLogger.instance.logHttp(
        method: request.method,
        uri: request.url,
        statusCode: streamedResponse.statusCode,
        responseBody: responseBody,
        duration: duration,
      );

      // Reconstruimos el StreamedResponse para los consumidores de la llamada
      return http.StreamedResponse(
        Stream.value(bytes),
        streamedResponse.statusCode,
        contentLength: bytes.length,
        request: streamedResponse.request,
        headers: streamedResponse.headers,
        isRedirect: streamedResponse.isRedirect,
        persistentConnection: streamedResponse.persistentConnection,
        reasonPhrase: streamedResponse.reasonPhrase,
      );
    } catch (e, stack) {
      final duration = DateTime.now().difference(startTime);
      AppLogger.instance.logError(
        'Error de red en ${request.method} ${request.url} (${duration.inMilliseconds}ms)',
        e,
        stack,
      );
      rethrow;
    }
  }

  @override
  void close() {
    _inner.close();
    super.close();
  }
}
