import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../models/album.dart';
import '../../theme/app_theme.dart';

Future<void> showAlbumOptionsSheet(
  BuildContext context, {
  required Album album,
  VoidCallback? onShare,
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
        _SheetRow(icon: Icons.favorite_border, label: 'Like'),
        _SheetRow(icon: Icons.person_outline, label: 'View artist'),
        _SheetRow(icon: Icons.ios_share, label: 'Share', onTap: onShare),
        _SheetRow(icon: Icons.favorite, label: 'Like all songs'),
        _SheetRow(icon: Icons.playlist_add, label: 'Add to playlist'),
        _SheetRow(icon: Icons.queue_music, label: 'Add to queue'),
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
                  Text(album.artist, style: const TextStyle(color: AppColors.textSecondary, fontSize: 13)),
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
  final VoidCallback? onTap;

  const _SheetRow({required this.icon, required this.label, this.onTap});
}

Future<void> showTrackOptionsSheet(
  BuildContext context, {
  required String albumTitle,
  required String artist,
  required String trackTitle,
  VoidCallback? onShare,
  VoidCallback? onViewAlbum,
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
        _SheetRow(icon: Icons.favorite_border, label: 'Like'),
        _SheetRow(icon: Icons.block, label: 'Hide song'),
        _SheetRow(icon: Icons.playlist_add, label: 'Add to playlist'),
        _SheetRow(icon: Icons.queue_music, label: 'Add to queue'),
        _SheetRow(icon: Icons.ios_share, label: 'Share', onTap: onShare),
        _SheetRow(icon: Icons.sensors, label: 'Go to radio', onTap: onGoToRadio),
        _SheetRow(icon: Icons.album_outlined, label: 'View album', onTap: onViewAlbum),
        _SheetRow(icon: Icons.person_outline, label: 'View artist'),
        _SheetRow(icon: Icons.info_outline, label: 'Song credits'),
        _SheetRow(icon: Icons.bedtime_outlined, label: 'Sleep timer'),
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
                  Text(artist, style: const TextStyle(color: AppColors.textSecondary, fontSize: 13)),
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
                          onTap: () {
                            Navigator.pop(ctx);
                            a.onTap?.call();
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
  Clipboard.setData(ClipboardData(text: 'https://musik.app/track/${Uri.encodeComponent(trackTitle)}'));
  ScaffoldMessenger.of(context).showSnackBar(
    const SnackBar(content: Text('Link copied'), duration: Duration(seconds: 2)),
  );
}
