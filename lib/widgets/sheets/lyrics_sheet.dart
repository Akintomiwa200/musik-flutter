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
    backgroundColor: Colors.white,
    barrierColor: Colors.black.withValues(alpha: 0.28),
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
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
    final lyrics =
        await context.read<LyricsService>().fetchForTrack(widget.track);
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
      initialChildSize: 0.78,
      minChildSize: 0.45,
      maxChildSize: 0.94,
      builder: (_, __) {
        return SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 42,
                  height: 4,
                  margin: const EdgeInsets.only(top: 10),
                  decoration: BoxDecoration(
                    color: context.surfaceHighlight,
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 14, 12, 8),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Lyrics',
                              style: TextStyle(
                                  fontSize: 22,
                                  color: context.textPrimary,
                                  fontWeight: FontWeight.w900)),
                          const SizedBox(height: 4),
                          Text(
                            widget.track.title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                                color: context.textSecondary, fontSize: 13),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon:
                          Icon(Icons.close, color: context.textPrimary),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
              ),
              Divider(color: context.surfaceHighlight, height: 1),
              Expanded(
                child: lyrics == null
                    ? const Center(
                        child: CircularProgressIndicator(
                            color: AppColors.musikAccent))
                    : !lyrics.hasLyrics
                        ? Center(
                            child: Padding(
                              padding: const EdgeInsets.all(24),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    lyrics.instrumental
                                        ? 'This one is instrumental.'
                                        : 'No lyrics found for this track.',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                        color: context.textSecondary),
                                  ),
                                  const SizedBox(height: 16),
                                  FilledButton.icon(
                                    onPressed: () {
                                      setState(() => _lyrics = null);
                                      _load();
                                    },
                                    icon: const Icon(Icons.refresh, size: 18),
                                    label: const Text('Retry'),
                                  ),
                                ],
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
                                  WidgetsBinding.instance
                                      .addPostFrameCallback((_) {
                                    _scrollToIndex(
                                        activeIdx, lyrics.synced.length);
                                  });
                                }
                                return ListView.builder(
                                  controller: _scrollController,
                                  padding:
                                      const EdgeInsets.fromLTRB(24, 20, 24, 32),
                                  itemCount: lyrics.synced.length,
                                  itemBuilder: (_, i) {
                                    final line = lyrics.synced[i];
                                    final isActive = i == activeIdx;
                                    final isPast = i < activeIdx;
                                    return _KaraokeLine(
                                      line: line,
                                      position: pos,
                                      isActive: isActive,
                                      isPast: isPast,
                                    );
                                  },
                                );
                              }
                              return SingleChildScrollView(
                                padding: const EdgeInsets.all(24),
                                child: Text(
                                  lyrics.plain ?? '',
                                  style: TextStyle(
                                      fontSize: 18,
                                      height: 1.6,
                                      color: context.textPrimary),
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

class _KaraokeLine extends StatelessWidget {
  final LyricsLine line;
  final Duration position;
  final bool isActive;
  final bool isPast;

  const _KaraokeLine({
    required this.line,
    required this.position,
    required this.isActive,
    required this.isPast,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    if (!isActive || line.words.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: Text(
          line.text,
          style: TextStyle(
            fontSize: isActive ? 22 : 18,
            fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
            height: 1.35,
            color: isPast
                ? theme.textTheme.bodySmall?.color?.withValues(alpha: 0.4)
                : theme.textTheme.bodyLarge?.color,
          ),
        ),
      );
    }

    final activeWordIdx = line.wordIndexAt(position);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        children: [
          Expanded(
            child: Wrap(
              children: List.generate(line.words.length, (i) {
                final word = line.words[i];
                final isCurrentWord = i == activeWordIdx;
                final isPastWord = i < activeWordIdx;
                return Text(
                  '${word.word} ',
                  style: TextStyle(
                    fontSize: 22,
                    height: 1.35,
                    fontWeight: isCurrentWord ? FontWeight.w900 : FontWeight.w500,
                    color: isCurrentWord
                        ? AppColors.musikAccent
                        : isPastWord
                            ? theme.textTheme.bodySmall?.color?.withValues(alpha: 0.4)
                            : theme.textTheme.bodyLarge?.color,
                  ),
                );
              }),
            ),
          ),
        ],
      ),
    );
  }
}


