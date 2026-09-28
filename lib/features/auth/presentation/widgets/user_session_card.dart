import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:listillify/core/theme/app_theme.dart';
import 'package:listillify/features/auth/presentation/cubit/auth_cubit.dart';
import 'package:listillify/features/auth/presentation/cubit/auth_state.dart';
import 'package:listillify/features/config/presentation/cubit/config_cubit.dart';
import 'package:listillify/features/config/presentation/cubit/config_state.dart';
import 'package:listillify/features/config/presentation/widgets/config_dialog.dart';

/// Tarjeta de sesión de usuario que visualiza el estado actual de autenticación con Spotify.
class UserSessionCard extends StatelessWidget {
  const UserSessionCard({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AuthCubit, AuthState>(
      builder: (context, authState) {
        return BlocBuilder<ConfigCubit, ConfigState>(
          builder: (context, configState) {
            final hasConfig = configState is ConfigLoaded && configState.config.isValid;
            final clientId = configState is ConfigLoaded ? configState.config.clientId : '';

            return Card(
              color: AppTheme.spotifyDarkGrey,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: BorderSide(
                  color: authState is Authenticated
                      ? AppTheme.spotifyGreen.withValues(alpha: 0.5)
                      : Colors.transparent,
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: _buildContent(context, authState, hasConfig, clientId),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildContent(
    BuildContext context,
    AuthState authState,
    bool hasConfig,
    String clientId,
  ) {
    if (authState is AuthLoading) {
      return Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(strokeWidth: 2, color: AppTheme.spotifyGreen),
          ),
          const SizedBox(width: 12),
          Text(authState.message, style: const TextStyle(color: AppTheme.spotifyLightGrey)),
        ],
      );
    }

    if (authState is Authenticated) {
      final session = authState.session;
      return Row(
        children: [
          CircleAvatar(
            backgroundColor: AppTheme.spotifyBlack,
            backgroundImage: session.avatarUrl != null ? NetworkImage(session.avatarUrl!) : null,
            child: session.avatarUrl == null
                ? const Icon(Icons.person, color: AppTheme.spotifyGreen)
                : null,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  session.displayName,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: AppTheme.spotifyWhite,
                  ),
                ),
                Text(
                  session.email ?? 'ID: ${session.id}',
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppTheme.spotifyLightGrey,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          TextButton.icon(
            icon: const Icon(Icons.logout, size: 18, color: Colors.redAccent),
            label: const Text('Salir', style: TextStyle(color: Colors.redAccent)),
            onPressed: () => context.read<AuthCubit>().logout(),
          ),
        ],
      );
    }

    // Unauthenticated o AuthError
    return Column(
      children: [
        if (authState is AuthError) ...[
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            margin: const EdgeInsets.only(bottom: 12),
            decoration: BoxDecoration(
              color: Colors.redAccent.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                const Icon(Icons.error_outline, color: Colors.redAccent, size: 18),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    authState.message,
                    style: const TextStyle(color: Colors.redAccent, fontSize: 12),
                  ),
                ),
              ],
            ),
          ),
        ],
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'No has iniciado sesión',
                    style: TextStyle(fontWeight: FontWeight.bold, color: AppTheme.spotifyWhite),
                  ),
                  Text(
                    'Conecta tu cuenta para enviar listas a Spotify.',
                    style: TextStyle(fontSize: 12, color: AppTheme.spotifyLightGrey),
                  ),
                ],
              ),
            ),
            ElevatedButton.icon(
              icon: const Icon(Icons.login, color: Colors.black, size: 18),
              label: const Text('Conectar'),
              onPressed: () {
                if (!hasConfig) {
                  ConfigDialog.show(context);
                } else {
                  context.read<AuthCubit>().login(clientId);
                }
              },
            ),
          ],
        ),
      ],
    );
  }
}
