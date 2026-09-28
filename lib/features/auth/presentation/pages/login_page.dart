import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:listillify/core/theme/app_theme.dart';
import 'package:listillify/features/auth/presentation/cubit/auth_cubit.dart';
import 'package:listillify/features/auth/presentation/cubit/auth_state.dart';
import 'package:listillify/features/config/presentation/cubit/config_cubit.dart';
import 'package:listillify/features/config/presentation/cubit/config_state.dart';
import 'package:listillify/features/config/presentation/widgets/config_dialog.dart';

/// Pantalla inicial de bienvenida y autenticación con Spotify.
/// Permite al usuario configurar sus credenciales (Client ID y Client Secret)
/// e iniciar sesión de forma segura a través de Spotify OAuth 2.0 PKCE.
class LoginPage extends StatelessWidget {
  const LoginPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        actions: [
          IconButton(
            icon: const Icon(Icons.settings, color: AppTheme.spotifyLightGrey),
            tooltip: 'Configuración API',
            onPressed: () => ConfigDialog.show(context),
          ),
        ],
      ),
      body: Center(
        child: SingleChildScrollView(
          child: Container(
            constraints: const BoxConstraints(maxWidth: 480),
            padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 32.0),
            child: BlocConsumer<AuthCubit, AuthState>(
              listener: (context, state) {
                if (state is AuthError) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(state.message),
                      backgroundColor: Colors.redAccent,
                    ),
                  );
                }
              },
              builder: (context, authState) {
                final isLoading = authState is AuthLoading;

                return BlocBuilder<ConfigCubit, ConfigState>(
                  builder: (context, configState) {
                    final hasConfig = configState is ConfigLoaded && configState.config.isValid;
                    final clientId = configState is ConfigLoaded ? configState.config.clientId : '';

                    return Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Logo / Icono
                        Container(
                          width: 88,
                          height: 88,
                          decoration: BoxDecoration(
                            color: AppTheme.spotifyGreen.withValues(alpha: 0.15),
                            shape: BoxShape.circle,
                          ),
                          child: const Center(
                            child: Icon(
                              Icons.queue_music,
                              size: 52,
                              color: AppTheme.spotifyGreen,
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),
                        const Text(
                          'Bienvenido a Listillify',
                          style: TextStyle(
                            fontSize: 26,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.spotifyWhite,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'Genera listas de reproducción en Spotify en segundos a partir de tus canciones o episodios de podcast.',
                          style: TextStyle(
                            fontSize: 14,
                            color: AppTheme.spotifyLightGrey,
                            height: 1.4,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 32),

                        // Tarjeta de estado de configuración de credenciales
                        Card(
                          color: AppTheme.spotifyDarkGrey,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                            side: BorderSide(
                              color: hasConfig
                                  ? AppTheme.spotifyGreen.withValues(alpha: 0.4)
                                  : Colors.amberAccent.withValues(alpha: 0.4),
                            ),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Row(
                              children: [
                                Icon(
                                  hasConfig ? Icons.verified : Icons.warning_amber_rounded,
                                  color: hasConfig ? AppTheme.spotifyGreen : Colors.amberAccent,
                                  size: 28,
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        hasConfig
                                            ? 'API de Spotify configurada'
                                            : 'Credenciales pendientes',
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          color: AppTheme.spotifyWhite,
                                          fontSize: 14,
                                        ),
                                      ),
                                      Text(
                                        hasConfig
                                            ? 'Client ID y Client Secret registrados'
                                            : 'Configura tu Client ID y Client Secret',
                                        style: const TextStyle(
                                          color: AppTheme.spotifyLightGrey,
                                          fontSize: 12,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                TextButton(
                                  onPressed: isLoading ? null : () => ConfigDialog.show(context),
                                  child: Text(
                                    hasConfig ? 'Editar' : 'Configurar',
                                    style: const TextStyle(color: AppTheme.spotifyGreen),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),

                        // Error de autenticación si existe
                        if (authState is AuthError) ...[
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.redAccent.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.error_outline, color: Colors.redAccent, size: 20),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Text(
                                    authState.message,
                                    style: const TextStyle(color: Colors.redAccent, fontSize: 13),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 20),
                        ],

                        // Botón de Iniciar sesión con Spotify
                        ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            backgroundColor: AppTheme.spotifyGreen,
                            foregroundColor: Colors.black,
                          ),
                          icon: isLoading
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black),
                                )
                              : const Icon(Icons.login, size: 22),
                          label: Text(
                            isLoading ? authState.message : 'Iniciar sesión con Spotify',
                            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                          ),
                          onPressed: isLoading
                              ? null
                              : () {
                                  if (!hasConfig) {
                                    ConfigDialog.show(context);
                                  } else {
                                    context.read<AuthCubit>().login(clientId);
                                  }
                                },
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          'Se abrirá tu navegador para autorizar la conexión con tu cuenta de Spotify.',
                          style: TextStyle(color: AppTheme.spotifyLightGrey, fontSize: 11),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    );
                  },
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}
