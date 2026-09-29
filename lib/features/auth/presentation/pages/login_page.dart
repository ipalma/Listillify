import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:listillify/core/theme/app_theme.dart';
import 'package:listillify/features/auth/presentation/cubit/auth_cubit.dart';
import 'package:listillify/features/auth/presentation/cubit/auth_state.dart';
import 'package:listillify/features/config/presentation/cubit/config_cubit.dart';
import 'package:listillify/features/config/presentation/cubit/config_state.dart';
import 'package:listillify/features/config/presentation/widgets/config_dialog.dart';
import 'package:listillify/features/logging/presentation/widgets/log_viewer_dialog.dart';

/// PATRÓN DE DISEÑO: Presentation Page (Clean Architecture / Presentation Layer)
/// Pantalla inicial de autenticación de Listillify.
/// Dispone de:
/// 1. Formulario de acceso con Usuario y Contraseña para inicio de sesión en la aplicación.
/// 2. Panel de persistencia local en fichero Hive para Client ID y Client Secret de la API de Spotify.
/// 3. Acceso alternativo mediante flujo OAuth 2.0 PKCE con Spotify.
class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isPasswordObscured = true;

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _onLoginPressed() {
    if (_formKey.currentState?.validate() ?? false) {
      context.read<AuthCubit>().loginWithCredentials(
            username: _usernameController.text,
            password: _passwordController.text,
          );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Listillify'),
        actions: [
          IconButton(
            icon: const Icon(Icons.terminal, color: AppTheme.spotifyGreen),
            tooltip: 'Ver Logs HTTP',
            onPressed: () => LogViewerDialog.show(context),
          ),
          IconButton(
            key: const Key('config_api_button'),
            icon: const Icon(Icons.settings, color: AppTheme.spotifyLightGrey),
            tooltip: 'Configuración API (Hive)',
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
                        Center(
                          child: Container(
                            width: 80,
                            height: 80,
                            decoration: BoxDecoration(
                              color: AppTheme.spotifyGreen.withValues(alpha: 0.15),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.queue_music,
                              size: 48,
                              color: AppTheme.spotifyGreen,
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),
                        const Text(
                          'Bienvenido a Listillify',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.spotifyWhite,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'Introduce tu usuario y contraseña para acceder a la aplicación.',
                          style: TextStyle(
                            fontSize: 14,
                            color: AppTheme.spotifyLightGrey,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 28),

                        // Formulario de Usuario y Contraseña
                        Form(
                          key: _formKey,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              // Campo Usuario
                              TextFormField(
                                key: const Key('username_field'),
                                controller: _usernameController,
                                enabled: !isLoading,
                                decoration: const InputDecoration(
                                  labelText: 'Usuario / Email',
                                  hintText: 'Introduce tu usuario o correo',
                                  prefixIcon: Icon(Icons.person_outline, color: AppTheme.spotifyLightGrey),
                                ),
                                validator: (value) {
                                  if (value == null || value.trim().isEmpty) {
                                    return 'Por favor, introduce tu usuario';
                                  }
                                  return null;
                                },
                              ),
                              const SizedBox(height: 16),

                              // Campo Contraseña
                              TextFormField(
                                key: const Key('password_field'),
                                controller: _passwordController,
                                obscureText: _isPasswordObscured,
                                enabled: !isLoading,
                                decoration: InputDecoration(
                                  labelText: 'Contraseña',
                                  hintText: 'Introduce tu contraseña',
                                  prefixIcon: const Icon(Icons.lock_outline, color: AppTheme.spotifyLightGrey),
                                  suffixIcon: IconButton(
                                    icon: Icon(
                                      _isPasswordObscured ? Icons.visibility : Icons.visibility_off,
                                      color: AppTheme.spotifyLightGrey,
                                    ),
                                    onPressed: () {
                                      setState(() {
                                        _isPasswordObscured = !_isPasswordObscured;
                                      });
                                    },
                                  ),
                                ),
                                validator: (value) {
                                  if (value == null || value.trim().isEmpty) {
                                    return 'Por favor, introduce tu contraseña';
                                  }
                                  return null;
                                },
                              ),
                              const SizedBox(height: 24),

                              // Botón de Iniciar Sesión con Usuario y Contraseña
                              ElevatedButton.icon(
                                key: const Key('login_button'),
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
                                  isLoading ? authState.message : 'Iniciar Sesión',
                                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                                ),
                                onPressed: isLoading ? null : _onLoginPressed,
                              ),
                            ],
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

                        // Separador visual
                        const Row(
                          children: [
                            Expanded(child: Divider(color: AppTheme.spotifyDarkGrey)),
                            Padding(
                              padding: EdgeInsets.symmetric(horizontal: 16.0),
                              child: Text(
                                'CONFIGURACIÓN API SPOTIFY (HIVE)',
                                style: TextStyle(
                                  color: AppTheme.spotifyLightGrey,
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 1.0,
                                ),
                              ),
                            ),
                            Expanded(child: Divider(color: AppTheme.spotifyDarkGrey)),
                          ],
                        ),
                        const SizedBox(height: 16),

                        // Tarjeta de estado de configuración persistente en Hive
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
                                  hasConfig ? Icons.save_as_outlined : Icons.inventory_2_outlined,
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
                                            ? 'Guardado en Hive: Credenciales activas'
                                            : 'Persistencia Hive: Credenciales pendientes',
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          color: AppTheme.spotifyWhite,
                                          fontSize: 13,
                                        ),
                                      ),
                                      Text(
                                        hasConfig
                                            ? 'Client ID y Client Secret persistidos en archivo local.'
                                            : 'Configura Client ID y Secret para conectividad Spotify.',
                                        style: const TextStyle(
                                          color: AppTheme.spotifyLightGrey,
                                          fontSize: 11,
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
                        const SizedBox(height: 16),

                        // Opción alternativa: Login directo con Spotify OAuth
                        OutlinedButton.icon(
                          key: const Key('spotify_oauth_button'),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            side: BorderSide(color: AppTheme.spotifyLightGrey.withValues(alpha: 0.5)),
                          ),
                          icon: const Icon(Icons.music_note, color: AppTheme.spotifyGreen, size: 20),
                          label: const Text(
                            'O conectar con Spotify OAuth en navegador',
                            style: TextStyle(color: AppTheme.spotifyWhite, fontSize: 13),
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
