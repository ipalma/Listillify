import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:listillify/core/theme/app_theme.dart';
import 'package:listillify/features/auth/presentation/cubit/auth_cubit.dart';
import 'package:listillify/features/auth/presentation/cubit/auth_state.dart';
import 'package:listillify/features/playlist/domain/entities/track_item.dart';
import 'package:listillify/features/playlist/presentation/cubit/playlist_cubit.dart';
import 'package:listillify/features/playlist/presentation/cubit/playlist_state.dart';

/// Vista interactiva para revisar y seleccionar las canciones antes de crearlas en Spotify.
class PlaylistPreviewView extends StatelessWidget {
  final PlaylistPreviewReady state;

  const PlaylistPreviewView({super.key, required this.state});

  @override
  Widget build(BuildContext context) {
    return Card(
      color: AppTheme.spotifyDarkGrey,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Cabecera con título y estadísticas
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        state.playlistName,
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.spotifyWhite,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${state.foundCount} encontradas • ${state.notFoundCount} no encontradas • ${state.selectedCount} seleccionadas',
                        style: const TextStyle(color: AppTheme.spotifyLightGrey, fontSize: 13),
                      ),
                    ],
                  ),
                ),
                TextButton.icon(
                  icon: Icon(
                    state.selectedCount == state.foundCount
                        ? Icons.deselect
                        : Icons.select_all,
                    color: AppTheme.spotifyGreen,
                    size: 18,
                  ),
                  label: Text(
                    state.selectedCount == state.foundCount ? 'Deseleccionar' : 'Todos',
                    style: const TextStyle(color: AppTheme.spotifyGreen),
                  ),
                  onPressed: () => context.read<PlaylistCubit>().toggleSelectAll(),
                ),
              ],
            ),
            const Divider(color: Color(0xFF383838), height: 24),
            // Lista de canciones
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: state.tracks.length,
              separatorBuilder: (context, index) => const Divider(color: Color(0xFF222222), height: 1),
              itemBuilder: (context, index) {
                final track = state.tracks[index];
                return _buildTrackTile(context, track);
              },
            ),
            const SizedBox(height: 24),
            // Botones de acción
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppTheme.spotifyLightGrey,
                      side: const BorderSide(color: Color(0xFF444444)),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    onPressed: () => context.read<PlaylistCubit>().reset(),
                    child: const Text('Volver a editar'),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: BlocBuilder<AuthCubit, AuthState>(
                    builder: (context, authState) {
                      final authSession = authState is Authenticated ? authState.session : null;

                      return ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                        onPressed: (authSession == null || state.selectedCount == 0)
                            ? null
                            : () {
                                context.read<PlaylistCubit>().confirmAndCreatePlaylist(
                                      userId: authSession.id,
                                      accessToken: authSession.accessToken,
                                    );
                              },
                        child: Text('Crear (${state.selectedCount}) en Spotify'),
                      );
                    },
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTrackTile(BuildContext context, TrackItem track) {
    final isSelected = state.selectedUris.contains(track.uri);

    if (!track.isFound) {
      return ListTile(
        contentPadding: EdgeInsets.zero,
        leading: Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: Colors.redAccent.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(6),
          ),
          child: const Icon(Icons.music_off, color: Colors.redAccent, size: 20),
        ),
        title: Text(
          track.title,
          style: const TextStyle(
            color: AppTheme.spotifyLightGrey,
            decoration: TextDecoration.lineThrough,
          ),
        ),
        subtitle: const Text(
          'No encontrada en Spotify',
          style: TextStyle(color: Colors.redAccent, fontSize: 11),
        ),
      );
    }

    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: ClipRRect(
        borderRadius: BorderRadius.circular(6),
        child: track.albumImageUrl != null
            ? Image.network(
                track.albumImageUrl!,
                width: 44,
                height: 44,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => _fallbackCover(),
              )
            : _fallbackCover(),
      ),
      title: Text(
        track.title,
        style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.spotifyWhite),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      subtitle: Text(
        '${track.artist} ${track.albumName != null ? '• ${track.albumName}' : ''}',
        style: const TextStyle(color: AppTheme.spotifyLightGrey, fontSize: 12),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            track.formattedDuration,
            style: const TextStyle(color: AppTheme.spotifyLightGrey, fontSize: 12),
          ),
          Checkbox(
            value: isSelected,
            activeColor: AppTheme.spotifyGreen,
            checkColor: Colors.black,
            onChanged: (_) => context.read<PlaylistCubit>().toggleTrackSelection(track.uri),
          ),
        ],
      ),
      onTap: () => context.read<PlaylistCubit>().toggleTrackSelection(track.uri),
    );
  }

  Widget _fallbackCover() {
    return Container(
      width: 44,
      height: 44,
      color: const Color(0xFF1E1E1E),
      child: const Icon(Icons.music_note, color: AppTheme.spotifyGreen, size: 20),
    );
  }
}
