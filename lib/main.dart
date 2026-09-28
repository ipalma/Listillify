import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:listillify/core/theme/app_theme.dart';
import 'package:listillify/features/auth/presentation/cubit/auth_cubit.dart';
import 'package:listillify/features/auth/presentation/cubit/auth_state.dart';
import 'package:listillify/features/auth/presentation/pages/login_page.dart';
import 'package:listillify/features/auth/presentation/widgets/user_session_card.dart';
import 'package:listillify/features/config/presentation/cubit/config_cubit.dart';
import 'package:listillify/features/config/presentation/widgets/config_dialog.dart';
import 'package:listillify/features/playlist/presentation/cubit/playlist_cubit.dart';
import 'package:listillify/features/playlist/presentation/cubit/playlist_state.dart';
import 'package:listillify/features/playlist/presentation/widgets/playlist_form.dart';
import 'package:listillify/features/playlist/presentation/widgets/playlist_preview_view.dart';
import 'package:listillify/features/playlist/presentation/widgets/playlist_success_card.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:listillify/core/constants/spotify_constants.dart';
import 'package:listillify/injection.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Hive.initFlutter();
  final configBox = await Hive.openBox<dynamic>(SpotifyConstants.hiveConfigBox);
  final authBox = await Hive.openBox<dynamic>(SpotifyConstants.hiveAuthBox);
  DependencyInjection.init(
    injectedConfigBox: configBox,
    injectedAuthBox: authBox,
  );
  runApp(const ListillifyApp());
}

/// Punto de entrada de la aplicación Flutter Listillify.
class ListillifyApp extends StatelessWidget {
  const ListillifyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider<ConfigCubit>(
          create: (_) => DependencyInjection.createConfigCubit()..loadConfig(),
        ),
        BlocProvider<AuthCubit>(
          create: (_) => DependencyInjection.createAuthCubit()..checkAuthStatus(),
        ),
        BlocProvider<PlaylistCubit>(
          create: (_) => DependencyInjection.createPlaylistCubit(),
        ),
      ],
      child: MaterialApp(
        title: 'Listillify',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.darkTheme,
        home: BlocBuilder<AuthCubit, AuthState>(
          builder: (context, authState) {
            if (authState is Authenticated) {
              return const HomePage();
            }
            return const LoginPage();
          },
        ),
      ),
    );
  }
}

/// Pantalla principal de Listillify con sesión de usuario, formulario de playlist y previsualización.
class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Row(
          children: [
            Icon(Icons.queue_music, color: AppTheme.spotifyGreen),
            SizedBox(width: 8),
            Text(
              'Listillify',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings, color: AppTheme.spotifyLightGrey),
            tooltip: 'Configuración Spotify API',
            onPressed: () => ConfigDialog.show(context),
          ),
        ],
      ),
      body: BlocConsumer<PlaylistCubit, PlaylistState>(
        listener: (context, state) {
          if (state is PlaylistFailureState) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: Colors.redAccent,
              ),
            );
          }
        },
        builder: (context, playlistState) {
          return SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Tarjeta de estado de autenticación y sesión
                  const UserSessionCard(),
                  const SizedBox(height: 24),
                  // Flujo dinámico según el estado de la playlist
                  switch (playlistState) {
                    PlaylistPreviewReady() => PlaylistPreviewView(state: playlistState),
                    PlaylistCreatedSuccess() => PlaylistSuccessCard(result: playlistState.result),
                    _ => const PlaylistForm(),
                  },
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
