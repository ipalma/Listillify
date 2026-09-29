import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:listillify/core/logging/app_logger.dart';
import 'package:listillify/core/theme/app_theme.dart';

/// Diálogo modal para visualizar, copiar y limpiar los logs en tiempo real.
class LogViewerDialog extends StatefulWidget {
  const LogViewerDialog({super.key});

  static Future<void> show(BuildContext context) {
    return showDialog(
      context: context,
      builder: (context) => const LogViewerDialog(),
    );
  }

  @override
  State<LogViewerDialog> createState() => _LogViewerDialogState();
}

class _LogViewerDialogState extends State<LogViewerDialog> {
  final ScrollController _scrollController = ScrollController();

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _copyAllLogs() {
    final allLogs = AppLogger.instance.logs.join('\n');
    Clipboard.setData(ClipboardData(text: allLogs));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Logs copiados al portapapeles.'),
        backgroundColor: AppTheme.spotifyGreen,
        duration: Duration(seconds: 2),
      ),
    );
  }

  Future<void> _clearLogs() async {
    await AppLogger.instance.clearLogs();
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final logs = AppLogger.instance.logs;

    return Dialog(
      backgroundColor: AppTheme.spotifyDarkGrey,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        width: 800,
        height: 600,
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Cabecera
            Row(
              children: [
                const Icon(Icons.terminal, color: AppTheme.spotifyGreen, size: 24),
                const SizedBox(width: 10),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Registro de Actividad y Logs (HTTP)',
                        style: TextStyle(
                          color: AppTheme.spotifyWhite,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        'Peticiones, respuestas y llamadas a la API de Spotify',
                        style: TextStyle(color: AppTheme.spotifyLightGrey, fontSize: 12),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  tooltip: 'Copiar todo',
                  icon: const Icon(Icons.copy, color: AppTheme.spotifyGreen),
                  onPressed: logs.isEmpty ? null : _copyAllLogs,
                ),
                IconButton(
                  tooltip: 'Limpiar logs',
                  icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
                  onPressed: logs.isEmpty ? null : _clearLogs,
                ),
                IconButton(
                  tooltip: 'Cerrar',
                  icon: const Icon(Icons.close, color: AppTheme.spotifyLightGrey),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
            const SizedBox(height: 8),
            // Ruta del fichero en disco
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: const Color(0xFF181818),
                borderRadius: BorderRadius.circular(8),
              ),
              child: SelectableText(
                'Archivo en disco: ${AppLogger.instance.logFilePath}',
                style: const TextStyle(color: AppTheme.spotifyLightGrey, fontSize: 11, fontFamily: 'monospace'),
              ),
            ),
            const SizedBox(height: 12),
            // Visor de logs
            Expanded(
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.black,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: const Color(0xFF333333)),
                ),
                child: logs.isEmpty
                    ? const Center(
                        child: Text(
                          'No hay registros todavía. Realiza una búsqueda o crea una lista para ver el tráfico.',
                          style: TextStyle(color: AppTheme.spotifyLightGrey, fontSize: 13),
                        ),
                      )
                    : Scrollbar(
                        controller: _scrollController,
                        thumbVisibility: true,
                        child: ListView.builder(
                          controller: _scrollController,
                          itemCount: logs.length,
                          itemBuilder: (context, index) {
                            final log = logs[index];
                            Color textColor = AppTheme.spotifyWhite;
                            if (log.contains('[HTTP_ERR]') || log.contains('[ERROR]')) {
                              textColor = Colors.redAccent;
                            } else if (log.contains('[HTTP_REQ]')) {
                              textColor = Colors.lightBlueAccent;
                            } else if (log.contains('[HTTP_RES]')) {
                              textColor = AppTheme.spotifyGreen;
                            } else if (log.contains('[WARN]')) {
                              textColor = Colors.amberAccent;
                            }

                            return Padding(
                              padding: const EdgeInsets.symmetric(vertical: 2),
                              child: SelectableText(
                                log,
                                style: TextStyle(
                                  color: textColor,
                                  fontFamily: 'monospace',
                                  fontSize: 12,
                                  height: 1.3,
                                ),
                              ),
                            );
                          },
                        ),
                      ),
              ),
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '${logs.length} líneas registradas',
                  style: const TextStyle(color: AppTheme.spotifyLightGrey, fontSize: 12),
                ),
                ElevatedButton.icon(
                  icon: const Icon(Icons.copy, size: 16),
                  label: const Text('Copiar Logs'),
                  onPressed: logs.isEmpty ? null : _copyAllLogs,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
