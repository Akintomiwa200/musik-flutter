import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/lyrics.dart';
import '../../models/track.dart';
import '../../services/audio_player_service.dart';
import '../../services/lyrics_service.dart';
import '../../theme/app_theme.dart';

Future<void> showLyricsSheet(BuildContext context, Track track) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: const Color(0xFF282828),
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
    ),
    builder: (ctx) => _LyricsSheetBody(track: track),
  );
}

class _LyricsSheetBody extends StatefulWidget {
  final Track track;

  const _LyricsSheetBody({required this.track});

  @override
  State<_LyricsSheetBody> createState() => _LyricsSheetBodyState();
}

class _LyricsSheetBodyState extends State<_LyricsSheetBody> {
  final _scrollController = ScrollController();
  TrackLyrics? _lyrics;
  int _lastScrolledIndex = -1;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  Future<void> _load() async {
    final lyrics = await context.read<LyricsService>().fetchForTrack(widget.track);
    if (mounted) setState(() => _lyrics = lyrics);
  }

  void _scrollToIndex(int index, int total) {
    if (index == _lastScrolledIndex || !_scrollController.hasClients) return;
    _lastScrolledIndex = index;
    final itemHeight = 44.0;
    final offset = (index * itemHeight) - 120;
    _scrollController.animateTo(
      offset.clamp(0.0, _scrollController.position.maxScrollExtent),
      duration: const Duration(milliseconds: 280),
      curve: Curves.easeOut,
    );
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final player = context.watch<AudioPlayerService>();
    final lyrics = _lyrics;

    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.72,
      minChildSize: 0.45,
      maxChildSize: 0.92,
      builder: (_, __) {
        return SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 12, 12, 4),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Lyrics', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700)),
                          const SizedBox(height: 4),
                          Text(
                            widget.track.title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(color: AppColors.textSecondary, fontSize: 13),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
              ),
              const Divider(color: Color(0xFF3E3E3E), height: 1),
              Expanded(
                child: lyrics == null
                    ? const Center(child: CircularProgressIndicator(color: AppColors.musikAccent))
                    : !lyrics.hasLyrics
                        ? Center(
                            child: Padding(
                              padding: const EdgeInsets.all(24),
                              child: Text(
                                lyrics.instrumental
                                    ? 'This one is instrumental.'
                                    : 'No lyrics found for this track.',
                                textAlign: TextAlign.center,
                                style: const TextStyle(color: AppColors.textSecondary),
                              ),
                            ),
                          )
                        : StreamBuilder<Duration>(
                            stream: player.positionStream,
                            builder: (context, snap) {
                              final pos = snap.data ?? player.position;
                              if (lyrics.hasSynced) {
                                final activeIdx = lyrics.indexAt(pos);
                                if (activeIdx >= 0) {
                                  WidgetsBinding.instance.addPostFrameCallback((_) {
                                    _scrollToIndex(activeIdx, lyrics.synced.length);
                                  });
                                }
                                return ListView.builder(
                                  controller: _scrollController,
                                  padding: const EdgeInsets.fromLTRB(24, 20, 24, 32),
                                  itemCount: lyrics.synced.length,
                                  itemBuilder: (_, i) {
                                    final line = lyrics.synced[i];
                                    final isActive = i == activeIdx;
                                    final isPast = i < activeIdx;
                                    return Padding(
                                      padding: const EdgeInsets.symmetric(vertical: 10),
                                      child: Text(
                                        line.text,
                                        style: TextStyle(
                                          fontSize: isActive ? 22 : 18,
                                          fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
                                          height: 1.35,
                                          color: isActive
                                              ? AppColors.musikAccent
                                              : isPast
                                                  ? Colors.white38
                                                  : Colors.white70,
                                        ),
                                      ),
                                    );
                                  },
                                );
                              }
                              return SingleChildScrollView(
                                padding: const EdgeInsets.all(24),
                                child: Text(
                                  lyrics.plain ?? '',
                                  style: const TextStyle(fontSize: 18, height: 1.6, color: Colors.white70),
                                ),
                              );
                            },
                          ),
              ),
            ],
          ),
        );
      },
    );
  }
}
