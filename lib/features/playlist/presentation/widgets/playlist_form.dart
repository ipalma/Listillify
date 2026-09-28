import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:listillify/core/theme/app_theme.dart';
import 'package:listillify/features/auth/presentation/cubit/auth_cubit.dart';
import 'package:listillify/features/auth/presentation/cubit/auth_state.dart';
import 'package:listillify/features/playlist/presentation/cubit/playlist_cubit.dart';
import 'package:listillify/features/playlist/presentation/cubit/playlist_state.dart';

/// Formulario principal para ingresar el nombre de la lista y el texto con canciones o podcasts.
class PlaylistForm extends StatefulWidget {
  const PlaylistForm({super.key});

  @override
  State<PlaylistForm> createState() => _PlaylistFormState();
}

class _PlaylistFormState extends State<PlaylistForm> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _tracksController = TextEditingController();
  bool _isPublic = false;

  @override
  void dispose() {
    _nameController.dispose();
    _tracksController.dispose();
    super.dispose();
  }

  void _insertSample() {
    _nameController.text = 'Clásicos de Rock y Éxitos';
    _tracksController.text = '''Queen - Bohemian Rhapsody
Pink Floyd - Wish You Were Here
The Beatles - Come Together
Led Zeppelin - Stairway to Heaven
Nirvana - Smells Like Teen Spirit
AC/DC - Back In Black''';
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AuthCubit, AuthState>(
      builder: (context, authState) {
        final isAuthenticated = authState is Authenticated;
        final accessToken = isAuthenticated ? authState.session.accessToken : '';

        return BlocBuilder<PlaylistCubit, PlaylistState>(
          builder: (context, state) {
            final isSearching = state is PlaylistSearching;

            return Card(
              color: AppTheme.spotifyDarkGrey,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Row(
                            children: [
                              Icon(Icons.playlist_add, color: AppTheme.spotifyGreen),
                              SizedBox(width: 8),
                              Text(
                                'Crear Nueva Playlist',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: AppTheme.spotifyWhite,
                                ),
                              ),
                            ],
                          ),
                          TextButton.icon(
                            icon: const Icon(Icons.auto_fix_high, size: 16, color: AppTheme.spotifyGreen),
                            label: const Text('Ejemplo', style: TextStyle(color: AppTheme.spotifyGreen, fontSize: 13)),
                            onPressed: isSearching ? null : _insertSample,
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _nameController,
                        enabled: !isSearching,
                        decoration: const InputDecoration(
                          labelText: 'Nombre de la playlist',
                          hintText: 'Ej. Mi Lista Favorita 2026',
                          prefixIcon: Icon(Icons.title, color: AppTheme.spotifyGreen),
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Por favor, escribe el nombre de la playlist.';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _tracksController,
                        enabled: !isSearching,
                        maxLines: 8,
                        decoration: const InputDecoration(
                          labelText: 'Canciones, podcasts o enlaces de Spotify (una por línea)',
                          hintText: 'Ejemplos:\nQueen - Bohemian Rhapsody\nhttps://open.spotify.com/track/...\n1. The Beatles - Yesterday',
                          alignLabelWithHint: true,
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Debes introducir al menos una canción o enlace.';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Checkbox(
                            value: _isPublic,
                            activeColor: AppTheme.spotifyGreen,
                            checkColor: Colors.black,
                            onChanged: isSearching
                                ? null
                                : (v) => setState(() => _isPublic = v ?? false),
                          ),
                          const Text(
                            'Hacer la playlist pública en mi perfil',
                            style: TextStyle(color: AppTheme.spotifyLightGrey, fontSize: 13),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      if (isSearching) ...[
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            LinearProgressIndicator(
                              value: state.total > 0 ? state.progress : null,
                              backgroundColor: const Color(0xFF1E1E1E),
                              valueColor: const AlwaysStoppedAnimation<Color>(AppTheme.spotifyGreen),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              state.total > 0
                                  ? 'Buscando ${state.current} de ${state.total}: "${state.currentItem}"'
                                  : state.currentItem,
                              style: const TextStyle(color: AppTheme.spotifyLightGrey, fontSize: 12),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                      ],
                      ElevatedButton.icon(
                        icon: isSearching
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black),
                              )
                            : const Icon(Icons.search, color: Colors.black),
                        label: Text(isSearching ? 'Buscando canciones...' : 'Buscar y Previsualizar'),
                        onPressed: (!isAuthenticated || isSearching)
                            ? null
                            : () {
                                if (_formKey.currentState?.validate() ?? false) {
                                  context.read<PlaylistCubit>().searchTracks(
                                        playlistName: _nameController.text,
                                        rawText: _tracksController.text,
                                        accessToken: accessToken,
                                        isPublic: _isPublic,
                                      );
                                }
                              },
                      ),
                      if (!isAuthenticated) ...[
                        const SizedBox(height: 8),
                        const Text(
                          'Debes iniciar sesión con tu cuenta de Spotify arriba para poder buscar y crear la lista.',
                          style: TextStyle(color: Colors.amberAccent, fontSize: 12),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }
}
