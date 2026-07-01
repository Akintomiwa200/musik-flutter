import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/album.dart';
import '../models/track.dart';
import '../services/audio_player_service.dart';
import '../services/device_service.dart';
import '../theme/app_theme.dart';
import '../widgets/album_gradient_background.dart';
import '../widgets/mini_player_bar.dart';
import '../widgets/sheets/device_picker_sheet.dart';
import '../widgets/sheets/music_sheets.dart';
import 'now_playing_screen.dart';
import 'queue_screen.dart';
import 'share_screen.dart';

class AlbumScreen extends StatelessWidget {
  final Album album;

  const AlbumScreen({super.key, required this.album});

  void _openShare(BuildContext context, String title) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ShareScreen(title: title, artist: album.artist),
      ),
    );
  }

  void _openQueue(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => QueueScreen(sourceLabel: album.title)),
    );
  }

  void _openNowPlaying(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => NowPlayingScreen(album: album)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final player = context.watch<AudioPlayerService>();
    final currentId = player.currentTrack?.id;

    return Scaffold(
      backgroundColor: Colors.black,
      body: AlbumGradientBackground(
        topColor: album.gradientTop,
        bottomColor: album.gradientBottom,
        child: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back, color: Colors.white),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: CustomScrollView(
                  slivers: [
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 24),
                        child: Column(
                          children: [
                            const SizedBox(height: 8),
                            Text(
                              album.title,
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                fontSize: 28,
                                fontWeight: FontWeight.w900,
                                height: 1.1,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              album.artist,
                              style: const TextStyle(fontSize: 15, color: AppColors.textSecondary),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              album.subtitle,
                              style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
                            ),
                            const SizedBox(height: 20),
                            Row(
                              children: [
                                IconButton(
                                  icon: const Icon(Icons.favorite_border),
                                  onPressed: () {},
                                ),
                                IconButton(
                                  icon: const Icon(Icons.download_outlined),
                                  onPressed: () {},
                                ),
                                IconButton(
                                  icon: const Icon(Icons.more_horiz),
                                  onPressed: () => showAlbumOptionsSheet(
                                    context,
                                    album: album,
                                    onShare: () => _openShare(context, album.title),
                                    onGoToRadio: () => _openQueue(context),
                                  ),
                                ),
                                const Spacer(),
                                GestureDetector(
                                  onTap: () {
                                    final first = album.tracks.first;
                                    player.playTrack(first, queue: album.tracks, index: 0);
                                  },
                                  child: Container(
                                    width: 56,
                                    height: 56,
                                    decoration: const BoxDecoration(
                                      color: AppColors.musikAccent,
                                      shape: BoxShape.circle,
                                    ),
                                    child: Icon(
                                      player.isPlaying && album.tracks.any((t) => t.id == currentId)
                                          ? Icons.pause
                                          : Icons.play_arrow,
                                      color: Colors.black,
                                      size: 32,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                    SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (context, i) {
                          final track = album.tracks[i];
                          final isPlaying = currentId == track.id;
                          return _AlbumTrackRow(
                            index: i + 1,
                            track: track,
                            isPlaying: isPlaying,
                            onTap: () => player.playTrack(track, queue: album.tracks, index: i),
                            onMore: () => showTrackOptionsSheet(
                              context,
                              albumTitle: album.title,
                              artist: album.artist,
                              trackTitle: track.title,
                              onShare: () => _openShare(context, track.title),
                              onViewAlbum: () {},
                              onGoToRadio: () => _openQueue(context),
                            ),
                          );
                        },
                        childCount: album.tracks.length,
                      ),
                    ),
                    const SliverPadding(padding: EdgeInsets.only(bottom: 16)),
                  ],
                ),
              ),
              if (player.currentTrack != null)
                StreamBuilder<Duration>(
                  stream: player.positionStream,
                  builder: (context, snap) {
                    final pos = snap.data ?? player.position;
                    final dur = player.duration;
                    final progress = dur != null && dur.inMilliseconds > 0
                        ? pos.inMilliseconds / dur.inMilliseconds
                        : 0.0;
                    final device = context.watch<DeviceService>();
                    return MiniPlayerBar(
                      title: player.currentTrack!.title,
                      artist: player.currentTrack!.artist,
                      track: player.currentTrack,
                      deviceLabel: device.activeDeviceLabel,
                      isPlaying: player.isPlaying,
                      progress: progress,
                      onTap: () => _openNowPlaying(context),
                      onPlayPause: player.togglePlayPause,
                      onCast: () => showDevicePickerSheet(context),
                    );
                  },
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AlbumTrackRow extends StatelessWidget {
  final int index;
  final Track track;
  final bool isPlaying;
  final VoidCallback onTap;
  final VoidCallback onMore;

  const _AlbumTrackRow({
    required this.index,
    required this.track,
    required this.isPlaying,
    required this.onTap,
    required this.onMore,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      onLongPress: onMore,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        child: Row(
          children: [
            SizedBox(
              width: 24,
              child: isPlaying
                  ? const Icon(Icons.graphic_eq, color: AppColors.musikAccent, size: 20)
                  : Text('$index', style: const TextStyle(color: AppColors.textSecondary)),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                track.title,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: isPlaying ? FontWeight.w600 : FontWeight.w400,
                  color: isPlaying ? AppColors.musikAccent : Colors.white,
                ),
              ),
            ),
            IconButton(
              icon: const Icon(Icons.more_horiz, color: AppColors.textSecondary),
              onPressed: onMore,
            ),
          ],
        ),
      ),
    );
  }
}
