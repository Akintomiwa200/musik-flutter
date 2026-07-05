import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../models/album.dart';
import '../../models/track.dart';
import '../../services/audio_player_service.dart';
import '../../services/download_service.dart';
import '../../services/library_service.dart';
import '../../theme/app_theme.dart';

Future<void> showAlbumOptionsSheet(
  BuildContext context, {
  required Album album,
  VoidCallback? onShare,
  VoidCallback? onViewArtist,
  VoidCallback? onGoToRadio,
}) {
  return showModalBottomSheet<void>(
    context: context,
    backgroundColor: const Color(0xFF282828),
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
    ),
    builder: (ctx) {
      final actions = [
        _SheetRow(
          icon: Icons.favorite_border,
          label: 'Like',
          onTap: () => context.read<LibraryService>().likeAll(album.tracks.take(1)),
        ),
        _SheetRow(icon: Icons.person_outline, label: 'View artist', onTap: onViewArtist),
        _SheetRow(icon: Icons.ios_share, label: 'Share', onTap: onShare),
        _SheetRow(
          icon: Icons.favorite,
          label: 'Like all songs',
          onTap: () => context.read<LibraryService>().likeAll(album.tracks),
        ),
        _SheetRow(
          icon: Icons.playlist_add,
          label: 'Add to playlist',
          onTap: () async {
            for (final track in album.tracks) {
              await context.read<LibraryService>().addToPlaylist(track, playlistName: album.title);
            }
          },
        ),
        _SheetRow(
          icon: Icons.queue_music,
          label: 'Add to queue',
          onTap: () {
            if (album.tracks.isNotEmpty) {
              context.read<AudioPlayerService>().playTrack(album.tracks.first, queue: album.tracks, index: 0);
            }
          },
        ),
        _SheetRow(icon: Icons.sensors, label: 'Go to radio', onTap: onGoToRadio),
      ];

      return SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 12),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(album.title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                  Text(album.artist, style: TextStyle(color: context.textSecondary, fontSize: 13)),
                ],
              ),
            ),
            const SizedBox(height: 8),
            ...actions.map((a) => ListTile(
                  leading: Icon(a.icon, color: Colors.white),
                  title: Text(a.label),
                  onTap: () {
                    Navigator.pop(ctx);
                    a.onTap?.call();
                  },
                )),
            ListTile(
              title: const Center(
                child: Text('Close', style: TextStyle(fontWeight: FontWeight.w700)),
              ),
              onTap: () => Navigator.pop(ctx),
            ),
          ],
        ),
      );
    },
  );
}

class _SheetRow {
  final IconData icon;
  final String label;
  final FutureOr<void> Function()? onTap;

  const _SheetRow({required this.icon, required this.label, this.onTap});
}

Future<void> showTrackOptionsSheet(
  BuildContext context, {
  Track? track,
  required String albumTitle,
  required String artist,
  required String trackTitle,
  VoidCallback? onShare,
  VoidCallback? onViewAlbum,
  VoidCallback? onViewArtist,
  VoidCallback? onGoToRadio,
}) {
  return showModalBottomSheet<void>(
    context: context,
    backgroundColor: const Color(0xFF282828),
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
    ),
    builder: (ctx) {
      final library = ctx.watch<LibraryService>();
      final downloadService = ctx.watch<DownloadService>();
      final isLiked = track != null && library.isLiked(track.id);
      final dlTask = track != null ? downloadService.taskFor(track.id) : null;
      final isDownloaded = dlTask?.status == DownloadStatus.completed;
      final isDownloading = dlTask?.status == DownloadStatus.downloading;
      final actions = [
        _SheetRow(
          icon: isLiked ? Icons.favorite : Icons.favorite_border,
          label: isLiked ? 'Remove like' : 'Like',
          onTap: track == null ? null : () => context.read<LibraryService>().toggleLike(track),
        ),
        _SheetRow(
          icon: isDownloaded
              ? Icons.download_done
              : isDownloading
                  ? Icons.downloading
                  : Icons.download,
          label: isDownloaded
              ? 'Downloaded'
              : isDownloading
                  ? 'Downloading...'
                  : 'Download',
          onTap: track == null || isDownloaded || isDownloading
              ? null
              : () => context.read<DownloadService>().download(track),
        ),
        _SheetRow(
          icon: Icons.block,
          label: 'Hide song',
          onTap: track == null ? null : () => context.read<LibraryService>().hideTrack(track),
        ),
        _SheetRow(
          icon: Icons.playlist_add,
          label: 'Add to playlist',
          onTap: track == null ? null : () => context.read<LibraryService>().addToPlaylist(track),
        ),
        _SheetRow(
          icon: Icons.queue_music,
          label: 'Add to queue',
          onTap: track == null ? null : () => context.read<AudioPlayerService>().addToQueue(track),
        ),
        _SheetRow(icon: Icons.ios_share, label: 'Share', onTap: onShare),
        _SheetRow(icon: Icons.sensors, label: 'Go to radio', onTap: onGoToRadio),
        _SheetRow(icon: Icons.album_outlined, label: 'View album', onTap: onViewAlbum),
        _SheetRow(icon: Icons.person_outline, label: 'View artist', onTap: onViewArtist),
        _SheetRow(
          icon: Icons.info_outline,
          label: 'Song credits',
          onTap: () => _showSongCredits(context, title: trackTitle, artist: artist, album: albumTitle),
        ),
        _SheetRow(
          icon: Icons.bedtime_outlined,
          label: 'Sleep timer',
          onTap: () => _showSleepTimer(context),
        ),
      ];

      return SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 12),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(albumTitle, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                  Text(artist, style: TextStyle(color: context.textSecondary, fontSize: 13)),
                ],
              ),
            ),
            const SizedBox(height: 4),
            Flexible(
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    ...actions.map((a) => ListTile(
                          leading: Icon(a.icon, color: Colors.white, size: 22),
                          title: Text(a.label, style: const TextStyle(fontSize: 15)),
                          onTap: () async {
                            Navigator.pop(ctx);
                            await a.onTap?.call();
                            if (a.onTap != null && a.label != 'Share') {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text('${a.label} updated')),
                              );
                            }
                          },
                        )),
                  ],
                ),
              ),
            ),
            ListTile(
              title: const Center(
                child: Text('Close', style: TextStyle(fontWeight: FontWeight.w700)),
              ),
              onTap: () => Navigator.pop(ctx),
            ),
          ],
        ),
      );
    },
  );
}

void copyTrackLink(BuildContext context, String trackTitle) {
  Clipboard.setData(ClipboardData(text: musikShareUrl('track', trackTitle)));
  ScaffoldMessenger.of(context).showSnackBar(
    const SnackBar(content: Text('Link copied'), duration: Duration(seconds: 2)),
  );
}

String musikShareUrl(String type, String title) =>
    'https://musik.app/$type/${Uri.encodeComponent(title.toLowerCase().replaceAll(RegExp(r'\s+'), '-'))}';

Future<void> _showSongCredits(
  BuildContext context, {
  required String title,
  required String artist,
  required String album,
}) {
  return showDialog<void>(
    context: context,
    builder: (ctx) => AlertDialog(
      backgroundColor: context.surfaceElevated,
      title: const Text('Song credits'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontWeight: FontWeight.w700)),
          const SizedBox(height: 8),
          Text('Artist: $artist'),
          Text('Album: $album'),
          const SizedBox(height: 8),
          const Text('Credits are based on the current catalog metadata.'),
        ],
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Close')),
      ],
    ),
  );
}

Future<void> _showSleepTimer(BuildContext context) {
  final player = context.read<AudioPlayerService>();
  return showModalBottomSheet<void>(
    context: context,
    backgroundColor: const Color(0xFF282828),
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
    ),
    builder: (ctx) => SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const ListTile(title: Text('Sleep timer', style: TextStyle(fontWeight: FontWeight.w700))),
          for (final minutes in [15, 30, 45, 60])
            ListTile(
              title: Text('$minutes minutes'),
              onTap: () {
                player.setSleepTimer(Duration(minutes: minutes));
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Sleep timer set for $minutes minutes')),
                );
              },
            ),
          ListTile(
            title: const Text('Turn off timer'),
            onTap: () {
              player.cancelSleepTimer();
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Sleep timer turned off')),
              );
            },
          ),
        ],
      ),
    ),
  );
}


