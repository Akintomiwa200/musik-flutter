import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../models/lyrics.dart';
import '../models/track.dart';

class LyricsService extends ChangeNotifier {
  final Map<String, TrackLyrics> _cache = {};
  bool _loading = false;

  bool get loading => _loading;

  String _key(Track track) => '${track.artist}|${track.title}'.toLowerCase();

  TrackLyrics? cachedFor(Track track) => _cache[_key(track)];

  Future<TrackLyrics> fetchForTrack(Track track) async {
    final key = _key(track);
    if (_cache.containsKey(key)) return _cache[key]!;

    _loading = true;
    notifyListeners();

    try {
      final results = await Future.any([
        _fetchFromLrcLib(track),
        _fetchFromLyricsOvh(track),
      ]).timeout(const Duration(seconds: 8));

      if (results != null) {
        _cache[key] = results;
        return results;
      }
    } catch (e) {
      debugPrint('All lyrics sources failed for "${track.title}": $e');
    } finally {
      _loading = false;
      notifyListeners();
    }

    const empty = TrackLyrics(plain: null, synced: []);
    _cache[key] = empty;
    return empty;
  }

  Future<TrackLyrics?> _fetchFromLrcLib(Track track) async {
    try {
      final durationSec = track.duration?.inSeconds ?? 0;
      final uri = Uri.parse('https://lrclib.net/api/get').replace(queryParameters: {
        'track_name': track.title,
        'artist_name': track.artist,
        'album_name': track.album,
        if (durationSec > 0) 'duration': '$durationSec',
      });

      final res = await http.get(uri).timeout(const Duration(seconds: 5));
      if (res.statusCode == 200) {
        final json = jsonDecode(res.body) as Map<String, dynamic>;
        final syncedRaw = json['syncedLyrics'] as String?;
        final plain = json['plainLyrics'] as String?;
        final instrumental = json['instrumental'] as bool? ?? false;

        return TrackLyrics(
          plain: plain,
          synced: syncedRaw != null ? _parseLrc(syncedRaw) : [],
          instrumental: instrumental,
        );
      }
    } catch (e) {
      debugPrint('lrclib failed: $e');
    }
    return null;
  }

  Future<TrackLyrics?> _fetchFromLyricsOvh(Track track) async {
    try {
      final uri = Uri.parse('https://api.lyrics.ovh/v1/${Uri.encodeComponent(track.artist)}/${Uri.encodeComponent(track.title)}');
      final res = await http.get(uri).timeout(const Duration(seconds: 5));
      if (res.statusCode == 200) {
        final json = jsonDecode(res.body) as Map<String, dynamic>;
        final text = json['lyrics'] as String?;
        if (text != null && text.isNotEmpty && text != 'No lyrics found') {
          return TrackLyrics(
            plain: text,
            synced: _estimateTimestamps(text),
            instrumental: false,
          );
        }
      }
    } catch (e) {
      debugPrint('lyrics.ovh failed: $e');
    }
    return null;
  }

  List<LyricsLine> _estimateTimestamps(String text) {
    final lines = text.split('\n')
        .map((l) => l.trim())
        .where((l) => l.isNotEmpty)
        .toList();

    if (lines.isEmpty) return [];

    const totalEstimate = Duration(seconds: 180);
    final perLine = totalEstimate ~/ lines.length;

    return List.generate(lines.length, (i) {
      return LyricsLine(
        timestamp: Duration(seconds: (i * perLine.inSeconds)),
        text: lines[i],
      );
    });
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
    return _estimateWordTimestamps(lines);
  }

  List<LyricsLine> _estimateWordTimestamps(List<LyricsLine> lines) {
    final result = <LyricsLine>[];
    for (var i = 0; i < lines.length; i++) {
      final line = lines[i];
      final words = line.text.split(RegExp(r'\s+'));
      if (words.length < 2) {
        result.add(line);
        continue;
      }

      final nextStart = i + 1 < lines.length
          ? lines[i + 1].timestamp
          : line.timestamp + const Duration(seconds: 4);
      final lineDuration = nextStart - line.timestamp;
      final wordDuration = lineDuration ~/ words.length;

      final wordLyrics = <LyricsWord>[];
      var wordTime = line.timestamp;
      for (final word in words) {
        wordLyrics.add(LyricsWord(timestamp: wordTime, word: word));
        wordTime += wordDuration;
      }

      result.add(LyricsLine(
        timestamp: line.timestamp,
        text: line.text,
        words: wordLyrics,
      ));
    }
    return result;
  }
}
