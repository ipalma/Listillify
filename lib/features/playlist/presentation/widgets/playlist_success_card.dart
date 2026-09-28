import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:listillify/core/theme/app_theme.dart';
import 'package:listillify/features/playlist/domain/entities/playlist_creation_result.dart';
import 'package:listillify/features/playlist/presentation/cubit/playlist_cubit.dart';
import 'package:url_launcher/url_launcher.dart';

/// Tarjeta de éxito visualizada cuando la playlist se ha creado satisfactoriamente en Spotify.
class PlaylistSuccessCard extends StatelessWidget {
  final PlaylistCreationResult result;

  const PlaylistSuccessCard({super.key, required this.result});

  @override
  Widget build(BuildContext context) {
    return Card(
      color: AppTheme.spotifyDarkGrey,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppTheme.spotifyGreen.withValues(alpha: 0.15),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.check_circle,
                size: 56,
                color: AppTheme.spotifyGreen,
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              '¡Playlist Creada con Éxito!',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: AppTheme.spotifyWhite,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'Se han añadido ${result.totalTracksAdded} canciones a "${result.playlistName}".',
              style: const TextStyle(color: AppTheme.spotifyLightGrey, fontSize: 14),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ElevatedButton.icon(
                  icon: const Icon(Icons.open_in_new, color: Colors.black, size: 18),
                  label: const Text('Abrir en Spotify'),
                  onPressed: () => launchUrl(Uri.parse(result.playlistUrl)),
                ),
                const SizedBox(width: 12),
                OutlinedButton.icon(
                  icon: const Icon(Icons.add, size: 18),
                  label: const Text('Crear otra'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppTheme.spotifyLightGrey,
                    side: const BorderSide(color: Color(0xFF444444)),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  ),
                  onPressed: () => context.read<PlaylistCubit>().reset(),
                ),
              ],
            ),
            if (result.failedQueries.isNotEmpty) ...[
              const SizedBox(height: 20),
              ExpansionTile(
                title: Text(
                  '${result.failedQueries.length} canciones no pudieron ser añadidas',
                  style: const TextStyle(color: Colors.amberAccent, fontSize: 13),
                ),
                children: result.failedQueries
                    .map(
                      (q) => ListTile(
                        dense: true,
                        leading: const Icon(Icons.close, color: Colors.redAccent, size: 16),
                        title: Text(q, style: const TextStyle(color: AppTheme.spotifyLightGrey, fontSize: 12)),
                      ),
                    )
                    .toList(),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
