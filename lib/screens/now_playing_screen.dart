import 'dart:math';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/album.dart';
import '../models/track.dart';
import '../services/audio_player_service.dart';
import '../services/download_service.dart';
import '../services/library_service.dart';
import '../widgets/sheets/device_picker_sheet.dart';
import '../widgets/sheets/lyrics_sheet.dart';
import '../widgets/track_cover.dart';
import 'share_screen.dart';

// Reference palette pulled from the design.
const _kBg = Color(0xFFFAF9FC);
const _kPurple = Color(0xFF8B5CF6);
const _kInk = Color(0xFF1A1A1F);
const _kSubInk = Color(0xFF9A97A6);
const _kBarInactive = Color(0xFFE7E4EE);

class NowPlayingScreen extends StatelessWidget {
  final Album? album;

  const NowPlayingScreen({super.key, this.album});

  String _format(Duration? d) {
    if (d == null) return '0:00';
    final m = d.inMinutes.remainder(60);
    final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  void _openShare(BuildContext context, String title, String artist) {
    Navigator.of(context).push(
      MaterialPageRoute(
          builder: (_) => ShareScreen(title: title, artist: artist)),
    );
  }

  void _openOverflowMenu(
    BuildContext context, {
    required bool liked,
    required Track track,
    required VoidCallback onToggleLike,
    required VoidCallback onShare,
  }) {
    final downloadService = context.read<DownloadService>();
    final task = downloadService.taskFor(track.id);
    final isDownloaded = task?.status == DownloadStatus.completed;
    final isDownloading = task?.status == DownloadStatus.downloading;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetContext) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 8),
              Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: _kBarInactive,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              ListTile(
                leading: Icon(
                  liked ? Icons.favorite : Icons.favorite_border,
                  color: liked ? _kPurple : _kInk,
                ),
                title: Text(liked ? 'Remove like' : 'Like'),
                onTap: () {
                  Navigator.pop(sheetContext);
                  onToggleLike();
                },
              ),
              ListTile(
                leading: Icon(
                  isDownloaded
                      ? Icons.download_done
                      : isDownloading
                          ? Icons.downloading
                          : Icons.download,
                  color: isDownloaded ? _kPurple : _kInk,
                ),
                title: Text(
                  isDownloaded
                      ? 'Downloaded'
                      : isDownloading
                          ? 'Downloading...'
                          : 'Download',
                ),
                onTap: isDownloaded || isDownloading
                    ? null
                    : () {
                        Navigator.pop(sheetContext);
                        downloadService.download(track);
                      },
              ),
              ListTile(
                leading: const Icon(Icons.speaker_group_outlined, color: _kInk),
                title: const Text('Devices'),
                onTap: () {
                  Navigator.pop(sheetContext);
                  showDevicePickerSheet(context);
                },
              ),
              ListTile(
                leading: const Icon(Icons.ios_share, color: _kInk),
                title: const Text('Share'),
                onTap: () {
                  Navigator.pop(sheetContext);
                  onShare();
                },
              ),
              const SizedBox(height: 8),
            ],
          ),
        );
      },
    );
  }

  /// Deterministic pseudo-waveform so the same track always renders the same
  /// bar pattern, and it stays stable across rebuilds while playing.
  List<double> _waveformHeights(int count, int seed) {
    final rnd = Random(seed);
    const minH = 5.0;
    const maxH = 30.0;
    double last = minH + rnd.nextDouble() * (maxH - minH);
    final heights = <double>[];
    for (var i = 0; i < count; i++) {
      final delta = (rnd.nextDouble() - 0.5) * 18;
      last = (last + delta).clamp(minH, maxH);
      heights.add(last);
    }
    return heights;
  }

  Widget _buildWaveform({
    required BuildContext context,
    required Duration position,
    required Duration duration,
    required int seed,
    required void Function(double fraction) onSeek,
  }) {
    final progress = duration.inMilliseconds > 0
        ? (position.inMilliseconds / duration.inMilliseconds).clamp(0.0, 1.0)
        : 0.0;

    return LayoutBuilder(
      builder: (context, constraints) {
        const barWidth = 3.0;
        const gap = 3.0;
        final barCount =
            ((constraints.maxWidth + gap) / (barWidth + gap)).floor().clamp(10, 200);
        final heights = _waveformHeights(barCount, seed);

        void handleSeek(Offset localPosition) {
          final fraction =
              (localPosition.dx / constraints.maxWidth).clamp(0.0, 1.0);
          onSeek(fraction);
        }

        return GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTapDown: (d) => handleSeek(d.localPosition),
          onHorizontalDragUpdate: (d) => handleSeek(d.localPosition),
          child: SizedBox(
            height: 32,
            width: double.infinity,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: List.generate(barCount, (i) {
                final isActive = i / barCount <= progress;
                return Container(
                  width: barWidth,
                  height: heights[i],
                  margin:
                      EdgeInsets.only(right: i == barCount - 1 ? 0 : gap),
                  decoration: BoxDecoration(
                    color: isActive ? _kPurple : _kBarInactive,
                    borderRadius: BorderRadius.circular(2),
                  ),
                );
              }),
            ),
          ),
        );
      },
    );
  }

  Widget _skipButton({
    required IconData icon,
    required String label,
    required bool mirror,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: SizedBox(
        width: 34,
        height: 34,
        child: Stack(
          alignment: Alignment.center,
          children: [
            Transform.flip(
              flipX: mirror,
              child: Icon(icon, size: 30, color: _kInk),
            ),
            Padding(
              padding: const EdgeInsets.only(top: 2),
              child: Text(
                label,
                style: const TextStyle(
                  fontSize: 9,
                  fontWeight: FontWeight.w800,
                  color: _kInk,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final player = context.watch<AudioPlayerService>();
    final library = context.watch<LibraryService>();
    final track = player.currentTrack;

    if (track == null) {
      return const Scaffold(
        backgroundColor: _kBg,
        body: Center(
          child: Text('Nothing playing', style: TextStyle(color: _kInk)),
        ),
      );
    }

    final liked = library.isLiked(track.id);

    return Scaffold(
      backgroundColor: _kBg,
      body: SafeArea(
        child: Column(
          children: [
            // Top bar
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back, size: 20, color: _kInk),
                    onPressed: () => Navigator.pop(context),
                  ),
                  const Expanded(
                    child: Text(
                      'Music Player',
                      textAlign: TextAlign.center,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 15,
                        color: _kInk,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.more_vert, size: 20, color: _kInk),
                    onPressed: () => _openOverflowMenu(
                      context,
                      liked: liked,
                      track: track,
                      onToggleLike: () => library.toggleLike(track),
                      onShare: () =>
                          _openShare(context, track.title, track.artist),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),

            // Album art with soft purple glow
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 40),
              child: AspectRatio(
                aspectRatio: 1,
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(
                        color: _kPurple.withOpacity(0.35),
                        blurRadius: 36,
                        spreadRadius: 4,
                        offset: const Offset(0, 16),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(24),
                    child: TrackCover(track: track, expand: true, borderRadius: 24),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 28),

            // Track info, centered
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Column(
                children: [
                  Text(
                    track.title,
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 19,
                      color: _kInk,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Flexible(
                        child: Text(
                          track.artist,
                          textAlign: TextAlign.center,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 13,
                            color: _kPurple,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      const SizedBox(width: 4),
                      const Icon(Icons.verified, size: 14, color: _kPurple),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Waveform progress
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: StreamBuilder<Duration>(
                stream: player.positionStream,
                builder: (context, snap) {
                  final pos = snap.data ?? player.position;
                  final dur = player.duration ?? track.duration ?? Duration.zero;

                  void seekToFraction(double fraction) {
                    if (dur.inMilliseconds <= 0) return;
                    player.seek(
                      Duration(
                        milliseconds: (dur.inMilliseconds * fraction).round(),
                      ),
                    );
                  }

                  void seekBy(Duration delta) {
                    if (dur.inMilliseconds <= 0) return;
                    final target = pos + delta;
                    final clamped = target < Duration.zero
                        ? Duration.zero
                        : (target > dur ? dur : target);
                    player.seek(clamped);
                  }

                  return Column(
                    children: [
                      _buildWaveform(
                        context: context,
                        position: pos,
                        duration: dur,
                        seed: track.id.hashCode,
                        onSeek: seekToFraction,
                      ),
                      const SizedBox(height: 6),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(_format(pos),
                              style: const TextStyle(fontSize: 11, color: _kSubInk)),
                          Text(_format(dur),
                              style: const TextStyle(fontSize: 11, color: _kSubInk)),
                        ],
                      ),
                      const SizedBox(height: 20),

                      // Playback controls
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          IconButton(
                            icon: Icon(
                              Icons.shuffle,
                              size: 22,
                              color: player.shuffle ? _kPurple : _kInk.withOpacity(0.4),
                            ),
                            onPressed: player.toggleShuffle,
                          ),
                          _skipButton(
                            icon: Icons.replay,
                            label: '15',
                            mirror: false,
                            onTap: () => seekBy(const Duration(seconds: -15)),
                          ),
                          Container(
                            width: 62,
                            height: 62,
                            decoration: const BoxDecoration(
                              color: _kPurple,
                              shape: BoxShape.circle,
                            ),
                            child: IconButton(
                              iconSize: 30,
                              icon: Icon(
                                player.isPlaying ? Icons.pause : Icons.play_arrow,
                                color: Colors.white,
                              ),
                              onPressed: player.togglePlayPause,
                            ),
                          ),
                          _skipButton(
                            icon: Icons.replay,
                            label: '15',
                            mirror: true,
                            onTap: () => seekBy(const Duration(seconds: 15)),
                          ),
                          IconButton(
                            icon: Icon(
                              player.repeatMode == RepeatSetting.one
                                  ? Icons.repeat_one
                                  : Icons.repeat,
                              size: 22,
                              color: player.repeat ? _kPurple : _kInk.withOpacity(0.4),
                            ),
                            onPressed: player.toggleRepeat,
                          ),
                        ],
                      ),
                    ],
                  );
                },
              ),
            ),

            const Spacer(),

            // Lyrics preview section
            GestureDetector(
              onTap: () => showLyricsSheet(context, track),
              behavior: HitTestBehavior.opaque,
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 20),
                decoration: const BoxDecoration(
                  border: Border(top: BorderSide(color: _kBarInactive, width: 1)),
                ),
                child: Column(
                  children: [
                    const Text(
                      'Lyrics',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: _kInk,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Tap to view the full lyrics for “${track.title}”.',
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 12, color: _kSubInk),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
