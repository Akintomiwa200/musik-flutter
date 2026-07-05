class LyricsWord {
  final Duration timestamp;
  final String word;

  const LyricsWord({required this.timestamp, required this.word});
}

class LyricsLine {
  final Duration timestamp;
  final String text;
  final List<LyricsWord> words;

  const LyricsLine({
    required this.timestamp,
    required this.text,
    this.words = const [],
  });

  int wordIndexAt(Duration position) {
    if (words.isEmpty) return -1;
    var idx = -1;
    for (var i = 0; i < words.length; i++) {
      if (words[i].timestamp <= position) {
        idx = i;
      } else {
        break;
      }
    }
    return idx;
  }
}

class TrackLyrics {
  final String? plain;
  final List<LyricsLine> synced;
  final bool instrumental;

  const TrackLyrics({
    this.plain,
    this.synced = const [],
    this.instrumental = false,
  });

  bool get hasSynced => synced.isNotEmpty;
  bool get hasLyrics => (plain?.isNotEmpty ?? false) || synced.isNotEmpty;

  LyricsLine? lineAt(Duration position) {
    if (synced.isEmpty) return null;
    LyricsLine? current;
    for (final line in synced) {
      if (line.timestamp <= position) {
        current = line;
      } else {
        break;
      }
    }
    return current;
  }

  int indexAt(Duration position) {
    if (synced.isEmpty) return -1;
    var idx = -1;
    for (var i = 0; i < synced.length; i++) {
      if (synced[i].timestamp <= position) {
        idx = i;
      } else {
        break;
      }
    }
    return idx;
  }
}
