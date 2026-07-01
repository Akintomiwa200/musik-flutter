import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../models/lyrics.dart';
import '../models/track.dart';

class LyricsService extends ChangeNotifier {
  static const _base = 'https://lrclib.net/api';

  final Map<String, TrackLyrics> _cache = {};
  bool _loading = false;

  bool get loading => _loading;

  String _key(Track track) => '${track.artist}|${track.title}'.toLowerCase();

  TrackLyrics? cachedFor(Track track) => _cache[_key(track)];

  Future<TrackLyrics> fetchForTrack(Track track) async {
    final key = _key(track);
    if (_cache.containsKey(key)) return _cache[key]!;

    _loading = true;

    try {
      final durationSec = track.duration?.inSeconds ?? 0;
      final uri = Uri.parse('$_base/get').replace(queryParameters: {
        'track_name': track.title,
        'artist_name': track.artist,
        'album_name': track.album,
        if (durationSec > 0) 'duration': '$durationSec',
      });

      final res = await http.get(uri).timeout(const Duration(seconds: 12));
      if (res.statusCode == 200) {
        final json = jsonDecode(res.body) as Map<String, dynamic>;
        final syncedRaw = json['syncedLyrics'] as String?;
        final plain = json['plainLyrics'] as String?;
        final instrumental = json['instrumental'] as bool? ?? false;

        final lyrics = TrackLyrics(
          plain: plain,
          synced: syncedRaw != null ? _parseLrc(syncedRaw) : [],
          instrumental: instrumental,
        );
        _cache[key] = lyrics;
        return lyrics;
      }
    } catch (e) {
      debugPrint('Lyrics fetch error: $e');
    } finally {
      _loading = false;
      notifyListeners();
    }

    const empty = TrackLyrics(plain: null, synced: []);
    _cache[key] = empty;
    return empty;
  }

  List<LyricsLine> _parseLrc(String lrc) {
    final lines = <LyricsLine>[];
    final pattern = RegExp(r'\[(\d{1,2}):(\d{2})(?:\.(\d{1,3}))?\](.*)');

    for (final raw in lrc.split('\n')) {
      final match = pattern.firstMatch(raw.trim());
      if (match == null) continue;
      final min = int.parse(match.group(1)!);
      final sec = int.parse(match.group(2)!);
      final frac = match.group(3);
      var ms = 0;
      if (frac != null) {
        final padded = frac.padRight(3, '0').substring(0, 3);
        ms = int.parse(padded);
      }
      final text = match.group(4)?.trim() ?? '';
      if (text.isEmpty) continue;
      lines.add(LyricsLine(
        timestamp: Duration(minutes: min, seconds: sec, milliseconds: ms),
        text: text,
      ));
    }

    lines.sort((a, b) => a.timestamp.compareTo(b.timestamp));
    return lines;
  }
}
