import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/track.dart';
import '../services/audio_player_service.dart';
import '../services/device_service.dart';
import '../theme/app_theme.dart';
import '../widgets/mini_player_bar.dart';
import '../widgets/sheets/device_picker_sheet.dart';
import '../widgets/sheets/music_sheets.dart';
import 'now_playing_screen.dart';

class PlaylistScreen extends StatefulWidget {
  final String title;
  final String subtitle;
  final Color gradientTop;
  final Color gradientBottom;
  final List<Track> tracks;

  const PlaylistScreen({
    super.key,
    required this.title,
    required this.subtitle,
    required this.gradientTop,
    required this.gradientBottom,
    required this.tracks,
  });

  @override
  State<PlaylistScreen> createState() => _PlaylistScreenState();
}

class _PlaylistScreenState extends State<PlaylistScreen> {
  final _searchController = TextEditingController();
  String _query = '';
  String _sort = 'Custom order';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<Track> get _filtered {
    if (_query.isEmpty) return widget.tracks;
    return widget.tracks
        .where((t) =>
            t.title.toLowerCase().contains(_query.toLowerCase()) ||
            t.artist.toLowerCase().contains(_query.toLowerCase()))
        .toList();
  }

  void _openNowPlaying(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => NowPlayingScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final player = context.watch<AudioPlayerService>();
    final filtered = _filtered;

    return Scaffold(
      backgroundColor: Colors.black,
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [widget.gradientTop, Colors.black],
            stops: const [0.0, 0.45],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back),
                      onPressed: () => Navigator.pop(context),
                    ),
                    Expanded(
                      child: TextField(
                        controller: _searchController,
                        onChanged: (v) => setState(() => _query = v),
                        style: const TextStyle(color: Colors.white, fontSize: 14),
                        decoration: InputDecoration(
                          hintText: 'Find in playlist',
                          hintStyle: const TextStyle(color: Color(0xFFB3B3B3)),
                          prefixIcon: const Icon(Icons.search, color: Color(0xFFB3B3B3), size: 22),
                          filled: true,
                          fillColor: Colors.white.withValues(alpha: 0.12),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide.none,
                          ),
                          contentPadding: const EdgeInsets.symmetric(vertical: 0),
                          isDense: true,
                        ),
                      ),
                    ),
                    TextButton(
                      onPressed: () async {
                        final picked = await showModalBottomSheet<String>(
                          context: context,
                          backgroundColor: const Color(0xFF282828),
                          builder: (ctx) => Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              for (final opt in ['Custom order', 'Title', 'Artist', 'Recently added'])
                                ListTile(
                                  title: Text(opt),
                                  trailing: _sort == opt ? const Icon(Icons.check, color: AppColors.musikAccent) : null,
                                  onTap: () => Navigator.pop(ctx, opt),
                                ),
                            ],
                          ),
                        );
                        if (picked != null) setState(() => _sort = picked);
                      },
                      child: const Text('Sort', style: TextStyle(fontWeight: FontWeight.w700)),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 8),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.title,
                            style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w900),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            widget.subtitle,
                            style: const TextStyle(color: AppColors.textSecondary, fontSize: 13),
                          ),
                        ],
                      ),
                    ),
                    GestureDetector(
                      onTap: () {
                        if (filtered.isNotEmpty) {
                          player.playTrack(filtered.first, queue: filtered, index: 0);
                        }
                      },
                      child: Container(
                        width: 56,
                        height: 56,
                        decoration: const BoxDecoration(
                          color: AppColors.musikAccent,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.play_arrow, color: Colors.black, size: 32),
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.only(top: 8),
                  itemCount: filtered.length,
                  itemBuilder: (_, i) {
                    final track = filtered[i];
                    final isPlaying = player.currentTrack?.id == track.id;
                    return ListTile(
                      title: Text(
                        track.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: isPlaying ? AppColors.musikAccent : Colors.white,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      subtitle: Text(track.artist, style: const TextStyle(color: AppColors.textSecondary)),
                      trailing: IconButton(
                        icon: const Icon(Icons.more_horiz, color: AppColors.textSecondary),
                        onPressed: () => showTrackOptionsSheet(
                          context,
                          albumTitle: widget.title,
                          artist: track.artist,
                          trackTitle: track.title,
                          onShare: () {},
                        ),
                      ),
                      onTap: () => player.playTrack(track, queue: filtered, index: i),
                    );
                  },
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
