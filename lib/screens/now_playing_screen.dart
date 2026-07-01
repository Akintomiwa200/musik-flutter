import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/album.dart';
import '../services/audio_player_service.dart';
import '../services/device_service.dart';
import '../theme/app_theme.dart';
import '../widgets/album_gradient_background.dart';
import '../widgets/sheets/device_picker_sheet.dart';
import '../widgets/sheets/lyrics_sheet.dart';
import '../widgets/sheets/music_sheets.dart';
import '../widgets/track_cover.dart';
import 'queue_screen.dart';
import 'share_screen.dart';

class NowPlayingScreen extends StatelessWidget {
  final Album? album;

  const NowPlayingScreen({super.key, this.album});

  String _format(Duration? d) {
    if (d == null) return '0:00';
    final m = d.inMinutes.remainder(60);
    final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  Color get _gradientTop => album?.gradientTop ?? const Color(0xFF8B0000);
  Color get _gradientBottom => album?.gradientBottom ?? const Color(0xFF0A0A0A);

  void _openShare(BuildContext context, String title, String artist) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => ShareScreen(title: title, artist: artist)),
    );
  }

  void _openQueue(BuildContext context, String sourceLabel) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => QueueScreen(sourceLabel: sourceLabel)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final player = context.watch<AudioPlayerService>();
    final devices = context.watch<DeviceService>();
    final track = player.currentTrack;

    if (track == null) {
      return Scaffold(
        backgroundColor: Colors.black,
        appBar: AppBar(backgroundColor: Colors.black),
        body: const Center(child: Text('Nothing playing')),
      );
    }

    final albumTitle = album?.title ?? track.album;

    return Scaffold(
      backgroundColor: Colors.black,
      body: AlbumGradientBackground(
        topColor: _gradientTop,
        bottomColor: _gradientBottom,
        child: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.keyboard_arrow_down, size: 32),
                      onPressed: () => Navigator.pop(context),
                    ),
                    Expanded(
                      child: Text(
                        albumTitle,
                        textAlign: TextAlign.center,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.more_horiz),
                      onPressed: () => showTrackOptionsSheet(
                        context,
                        albumTitle: albumTitle,
                        artist: track.artist,
                        trackTitle: track.title,
                        onShare: () => _openShare(context, track.title, track.artist),
                        onGoToRadio: () => _openQueue(context, albumTitle),
                      ),
                    ),
                  ],
                ),
              ),
              const Spacer(),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: AspectRatio(
                  aspectRatio: 1,
                  child: TrackCover(track: track, expand: true, borderRadius: 8),
                ),
              ),
              const SizedBox(height: 28),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            track.title,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w700),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            track.artist,
                            style: const TextStyle(fontSize: 16, color: AppColors.textSecondary),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.favorite_border, size: 28),
                      onPressed: () {},
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: StreamBuilder<Duration>(
                  stream: player.positionStream,
                  builder: (context, snap) {
                    final pos = snap.data ?? player.position;
                    final dur = player.duration ?? track.duration ?? Duration.zero;
                    final value = dur.inMilliseconds > 0
                        ? pos.inMilliseconds / dur.inMilliseconds
                        : 0.0;
                    return Column(
                      children: [
                        SliderTheme(
                          data: SliderTheme.of(context).copyWith(
                            trackHeight: 4,
                            thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
                            overlayShape: SliderComponentShape.noOverlay,
                          ),
                          child: Slider(
                            value: value.clamp(0.0, 1.0),
                            activeColor: Colors.white,
                            inactiveColor: Colors.white24,
                            onChanged: (v) {
                              final ms = (dur.inMilliseconds * v).round();
                              player.seek(Duration(milliseconds: ms));
                            },
                          ),
                        ),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(_format(pos), style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                            Text(_format(dur), style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                          ],
                        ),
                      ],
                    );
                  },
                ),
              ),
              const SizedBox(height: 8),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    IconButton(
                      icon: Icon(Icons.shuffle, color: player.shuffle ? AppColors.musikAccent : Colors.white70),
                      onPressed: player.toggleShuffle,
                    ),
                    IconButton(
                      icon: const Icon(Icons.skip_previous, size: 36),
                      onPressed: player.skipPrevious,
                    ),
                    Container(
                      width: 64,
                      height: 64,
                      decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
                      child: IconButton(
                        iconSize: 40,
                        icon: Icon(
                          player.isPlaying ? Icons.pause : Icons.play_arrow,
                          color: Colors.black,
                        ),
                        onPressed: player.togglePlayPause,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.skip_next, size: 36),
                      onPressed: player.skipNext,
                    ),
                    IconButton(
                      icon: Icon(Icons.repeat, color: player.repeat ? AppColors.musikAccent : Colors.white70),
                      onPressed: player.toggleRepeat,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    GestureDetector(
                      onTap: () => showDevicePickerSheet(context),
                      child: Row(
                        children: [
                          const Icon(Icons.speaker_group_outlined, size: 18, color: AppColors.textSecondary),
                          const SizedBox(width: 6),
                          Text(
                            devices.activeDeviceLabel.toUpperCase(),
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.white.withValues(alpha: 0.7),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Row(
                      children: [
                        IconButton(
                          icon: const Icon(Icons.ios_share, size: 22),
                          onPressed: () => _openShare(context, track.title, track.artist),
                        ),
                        IconButton(
                          icon: const Icon(Icons.playlist_add, size: 26),
                          onPressed: () {},
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                child: GestureDetector(
                  onTap: () => showLyricsSheet(context, track),
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    decoration: BoxDecoration(
                      color: const Color(0xFFE85D04),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        const Text(
                          'Lyrics',
                          style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
                        ),
                        const Spacer(),
                        TextButton(
                          onPressed: () => showLyricsSheet(context, track),
                          style: TextButton.styleFrom(
                            foregroundColor: Colors.white,
                            padding: EdgeInsets.zero,
                            minimumSize: Size.zero,
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          ),
                          child: const Text('MORE', style: TextStyle(fontWeight: FontWeight.w700, letterSpacing: 0.5)),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
