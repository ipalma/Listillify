import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:listillify/core/theme/app_theme.dart';
import 'package:listillify/features/config/presentation/cubit/config_cubit.dart';
import 'package:listillify/features/config/presentation/widgets/config_dialog.dart';
import 'package:listillify/injection.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  DependencyInjection.init();
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
      ],
      child: MaterialApp(
        title: 'Listillify',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.darkTheme,
        home: const HomePage(),
      ),
    );
  }
}

/// Pantalla principal provisional de Listillify con acceso a configuración y estado.
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
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.library_music,
                size: 72,
                color: AppTheme.spotifyGreen,
              ),
              const SizedBox(height: 16),
              const Text(
                'Generador de Playlists para Spotify',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              const Text(
                'Configura tus credenciales de Spotify para comenzar a sincronizar listas.',
                style: TextStyle(color: AppTheme.spotifyLightGrey),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                icon: const Icon(Icons.key, color: Colors.black),
                label: const Text('Configurar API'),
                onPressed: () => ConfigDialog.show(context),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
