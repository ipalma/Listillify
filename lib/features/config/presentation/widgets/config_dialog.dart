import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:listillify/core/constants/spotify_constants.dart';
import 'package:listillify/core/theme/app_theme.dart';
import 'package:listillify/features/config/presentation/cubit/config_cubit.dart';
import 'package:listillify/features/config/presentation/cubit/config_state.dart';

/// Diálogo modal interactivo para configurar el Client ID de Spotify.
/// Permite al usuario introducir y guardar su credencial de la API de Spotify.
class ConfigDialog extends StatefulWidget {
  const ConfigDialog({super.key});

  /// Método estático de conveniencia para mostrar el diálogo.
  static Future<void> show(BuildContext context) {
    final cubit = context.read<ConfigCubit>();
    cubit.loadConfig();

    return showDialog<void>(
      context: context,
      barrierDismissible: true,
      builder: (dialogContext) => BlocProvider.value(
        value: cubit,
        child: const ConfigDialog(),
      ),
    );
  }

  @override
  State<ConfigDialog> createState() => _ConfigDialogState();
}

class _ConfigDialogState extends State<ConfigDialog> {
  final TextEditingController _clientIdController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  @override
  void dispose() {
    _clientIdController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<ConfigCubit, ConfigState>(
      listener: (context, state) {
        if (state is ConfigLoaded) {
          _clientIdController.text = state.config.clientId;
        } else if (state is ConfigSavedSuccess) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Configuración de Spotify guardada correctamente.'),
              backgroundColor: AppTheme.spotifyGreen,
            ),
          );
          Navigator.of(context).pop();
        } else if (state is ConfigError) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.message),
              backgroundColor: Colors.redAccent,
            ),
          );
        }
      },
      builder: (context, state) {
        final isLoading = state is ConfigLoading;

        return AlertDialog(
          backgroundColor: AppTheme.spotifyDarkGrey,
          title: const Row(
            children: [
              Icon(Icons.settings, color: AppTheme.spotifyGreen),
              SizedBox(width: 10),
              Text(
                'Configuración de Spotify API',
                style: TextStyle(color: AppTheme.spotifyWhite, fontSize: 18),
              ),
            ],
          ),
          content: SingleChildScrollView(
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Para utilizar Listillify, introduce el Client ID de tu aplicación creada en el Spotify Developer Dashboard.',
                    style: TextStyle(color: AppTheme.spotifyLightGrey, fontSize: 13),
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _clientIdController,
                    enabled: !isLoading,
                    decoration: const InputDecoration(
                      labelText: 'Spotify Client ID',
                      hintText: 'Ej. 3f1a2b4c5d6e7f8a9b0c...',
                      prefixIcon: Icon(Icons.key, color: AppTheme.spotifyGreen),
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Por favor, ingresa el Client ID.';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1E1E1E),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: const Color(0xFF333333)),
                    ),
                    child: const Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Redirect URIs requeridos en Spotify Dashboard:',
                          style: TextStyle(
                            color: AppTheme.spotifyWhite,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                        SizedBox(height: 6),
                        Text(
                          '• Windows: ${SpotifyConstants.windowsRedirectUri}',
                          style: TextStyle(color: AppTheme.spotifyLightGrey, fontSize: 11),
                        ),
                        Text(
                          '• Android: ${SpotifyConstants.androidRedirectUri}',
                          style: TextStyle(color: AppTheme.spotifyLightGrey, fontSize: 11),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: isLoading ? null : () => Navigator.of(context).pop(),
              child: const Text('Cancelar', style: TextStyle(color: AppTheme.spotifyLightGrey)),
            ),
            ElevatedButton(
              onPressed: isLoading
                  ? null
                  : () {
                      if (_formKey.currentState?.validate() ?? false) {
                        context.read<ConfigCubit>().saveConfig(_clientIdController.text);
                      }
                    },
              child: isLoading
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black),
                    )
                  : const Text('Guardar'),
            ),
          ],
        );
      },
    );
  }
}
