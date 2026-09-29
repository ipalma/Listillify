import 'dart:developer' as developer;
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';

/// PATRÓN DE DISEÑO: Singleton / Logger Service
/// Servicio centralizado de registro de eventos (Logging) para Listillify.
/// Escribe en memoria, en la consola de depuración y en un fichero físico persistente `listillify.log`.
class AppLogger {
  AppLogger._internal();
  static final AppLogger instance = AppLogger._internal();

  final List<String> _inMemoryLogs = [];
  File? _logFile;
  bool _isInitialized = false;

  /// Inicializa el archivo de log en el directorio accesible de la aplicación.
  Future<void> init() async {
    if (_isInitialized) return;
    try {
      Directory dir;
      if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
        dir = await getApplicationDocumentsDirectory();
      } else {
        dir = await getApplicationSupportDirectory();
      }
      _logFile = File('${dir.path}${Platform.pathSeparator}listillify.log');
      _isInitialized = true;
      logInfo('Logger inicializado. Fichero de log: ${_logFile?.path}');
    } catch (e) {
      developer.log('Error al inicializar AppLogger: $e', name: 'AppLogger');
    }
  }

  /// Devuelve la ruta absoluta al fichero de log.
  String get logFilePath => _logFile?.path ?? 'Iniciando...';

  /// Obtiene los logs en memoria formateados.
  List<String> get logs => List.unmodifiable(_inMemoryLogs);

  /// Limpia los logs en memoria y en el fichero.
  Future<void> clearLogs() async {
    _inMemoryLogs.clear();
    try {
      if (_logFile != null && await _logFile!.exists()) {
        await _logFile!.writeAsString('');
      }
    } catch (_) {}
  }

  void logInfo(String message) => _write('INFO', message);
  void logWarning(String message) => _write('WARN', message);
  void logError(String message, [Object? error, StackTrace? stackTrace]) {
    final buffer = StringBuffer(message);
    if (error != null) buffer.write('\nError: $error');
    if (stackTrace != null) buffer.write('\nStackTrace:\n$stackTrace');
    _write('ERROR', buffer.toString());
  }

  void logHttp({
    required String method,
    required Uri uri,
    int? statusCode,
    Map<String, String>? headers,
    String? body,
    String? responseBody,
    Duration? duration,
  }) {
    final buffer = StringBuffer();
    if (statusCode == null) {
      buffer.writeln('--> HTTP $method $uri');
      if (headers != null && headers.isNotEmpty) {
        final sanitizedHeaders = _sanitizeHeaders(headers);
        buffer.writeln('    Headers: $sanitizedHeaders');
      }
      if (body != null && body.isNotEmpty) {
        buffer.writeln('    Body: $body');
      }
    } else {
      final elapsed = duration != null ? ' (${duration.inMilliseconds}ms)' : '';
      buffer.writeln('<-- HTTP $statusCode $method $uri$elapsed');
      if (responseBody != null && responseBody.isNotEmpty) {
        final truncatedBody = responseBody.length > 2000
            ? '${responseBody.substring(0, 2000)}... [TRUNCADO, total ${responseBody.length} bytes]'
            : responseBody;
        buffer.writeln('    Response: $truncatedBody');
      }
    }
    _write(statusCode == null ? 'HTTP_REQ' : (statusCode >= 400 ? 'HTTP_ERR' : 'HTTP_RES'), buffer.toString().trim());
  }

  void _write(String level, String message) {
    final timestamp = DateTime.now().toIso8601String().substring(11, 23);
    final logLine = '[$timestamp] [$level] $message';

    _inMemoryLogs.add(logLine);
    if (_inMemoryLogs.length > 500) {
      _inMemoryLogs.removeAt(0);
    }

    if (kDebugMode) {
      developer.log(logLine, name: 'Listillify');
    }

    // Escritura asíncrona no bloqueante en disco
    if (_logFile != null) {
      _logFile!.writeAsString('$logLine\n', mode: FileMode.append, flush: true).catchError((_) {
        return _logFile!;
      });
    }
  }

  Map<String, String> _sanitizeHeaders(Map<String, String> headers) {
    return headers.map((key, value) {
      if (key.toLowerCase() == 'authorization') {
        if (value.startsWith('Bearer ')) {
          final token = value.substring(7);
          final masked = token.length > 12
              ? '${token.substring(0, 6)}...${token.substring(token.length - 4)}'
              : '***';
          return MapEntry(key, 'Bearer $masked');
        }
        if (value.startsWith('Basic ')) {
          return MapEntry(key, 'Basic ***');
        }
        return MapEntry(key, '***');
      }
      return MapEntry(key, value);
    });
  }
}
