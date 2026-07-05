import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../navigation/app_routes.dart';
import '../services/audio_player_service.dart';
import '../theme/app_theme.dart';
import '../widgets/track_cover.dart';

class RecentsScreen extends StatelessWidget {
  const RecentsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final player = context.watch<AudioPlayerService>();
    final history = player.playHistory;

    return Scaffold(
      backgroundColor: context.background,
      appBar: AppBar(
        title: const Text('Recents', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700)),
      ),
      body: history.isEmpty
          ? Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.history, size: 64, color: context.textMuted),
                  const SizedBox(height: 16),
                  Text('No recently played tracks',
                      style: TextStyle(color: context.textSecondary, fontSize: 15)),
                ],
              ),
            )
          : ListView.separated(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: history.length,
              separatorBuilder: (_, __) => Divider(color: context.surfaceHighlight, height: 1, indent: 56),
              itemBuilder: (_, i) {
                final track = history[i];
                return ListTile(
                  leading: TrackCover(track: track, size: 44, borderRadius: 6),
                  title: Text(track.title, maxLines: 1, overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                  subtitle: Text(track.artist, maxLines: 1, overflow: TextOverflow.ellipsis,
                      style: TextStyle(fontSize: 12, color: context.textSecondary)),
                  onTap: () {
                    player.playTrack(track, queue: history, index: i);
                    AppRoutes.nowPlaying(context);
                  },
                );
              },
            ),
    );
  }
}


