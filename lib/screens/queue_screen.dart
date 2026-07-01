import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/track.dart';
import '../services/audio_player_service.dart';
import '../theme/app_theme.dart';

class QueueScreen extends StatelessWidget {
  final String sourceLabel;

  const QueueScreen({
    super.key,
    required this.sourceLabel,
  });

  List<Track> _upcoming(AudioPlayerService player) {
    final upcoming = player.upcomingTracks;
    if (upcoming.isNotEmpty) return upcoming;
    return player.queue;
  }

  @override
  Widget build(BuildContext context) {
    final player = context.watch<AudioPlayerService>();
    final current = player.currentTrack;
    final upcoming = _upcoming(player);

    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.white),
                    onPressed: () => Navigator.pop(context),
                  ),
                  Expanded(
                    child: Text(
                      'Album radio based on $sourceLabel',
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                    ),
                  ),
                  const SizedBox(width: 48),
                ],
              ),
            ),
            if (current != null)
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      current.title,
                      style: const TextStyle(
                        color: AppColors.musikAccent,
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      current.artist,
                      style: const TextStyle(color: AppColors.textSecondary, fontSize: 13),
                    ),
                  ],
                ),
              ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Next From:',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.9),
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
            Expanded(
              child: ReorderableListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                itemCount: upcoming.length,
                onReorder: player.reorderUpcoming,
                itemBuilder: (context, i) {
                  final track = upcoming[i];
                  return _QueueRow(
                    key: ValueKey('${track.id}-$i'),
                    index: i,
                    track: track,
                    onTap: () {
                      final queue = player.queue.isNotEmpty
                          ? List<Track>.from(player.queue)
                          : List<Track>.from(upcoming);
                      final playIndex = player.queue.isNotEmpty
                          ? player.queueIndex + 1 + i
                          : i;
                      player.playTrack(track, queue: queue, index: playIndex);
                    },
                  );
                },
              ),
            ),
            _QueueControls(player: player),
          ],
        ),
      ),
    );
  }
}

class _QueueRow extends StatelessWidget {
  final int index;
  final Track track;
  final VoidCallback onTap;

  const _QueueRow({
    super.key,
    required this.index,
    required this.track,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      key: key,
      onTap: onTap,
      leading: Icon(Icons.radio_button_unchecked, color: Colors.white.withValues(alpha: 0.5), size: 22),
      title: Text(track.title, maxLines: 1, overflow: TextOverflow.ellipsis),
      subtitle: Text(track.artist, style: const TextStyle(color: AppColors.textSecondary, fontSize: 13)),
      trailing: ReorderableDragStartListener(
        index: index,
        child: const Icon(Icons.drag_handle, color: AppColors.textSecondary),
      ),
    );
  }
}

class _QueueControls extends StatelessWidget {
  final AudioPlayerService player;

  const _QueueControls({required this.player});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          IconButton(
            icon: Icon(Icons.shuffle, color: player.shuffle ? AppColors.musikAccent : Colors.white70),
            onPressed: player.toggleShuffle,
          ),
          IconButton(icon: const Icon(Icons.skip_previous, size: 32), onPressed: player.skipPrevious),
          Container(
            width: 56,
            height: 56,
            decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
            child: IconButton(
              icon: Icon(player.isPlaying ? Icons.pause : Icons.play_arrow, color: Colors.black, size: 32),
              onPressed: player.togglePlayPause,
            ),
          ),
          IconButton(icon: const Icon(Icons.skip_next, size: 32), onPressed: player.skipNext),
          IconButton(
            icon: Icon(Icons.repeat, color: player.repeat ? AppColors.musikAccent : Colors.white70),
            onPressed: player.toggleRepeat,
          ),
        ],
      ),
    );
  }
}
