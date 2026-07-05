import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../models/track.dart';

class PipedResolvedStream {
  final String url;
  final Duration? duration;

  const PipedResolvedStream({required this.url, this.duration});
}

/// Resolves full-length audio via the Piped API (YouTube proxy).
/// Tries multiple instances for reliability.
class PipedResolverService {
  static const _instances = [
    'https://pipedapi.kavin.rocks',
    'https://pipedapi.smnz.de',
    'https://pipedapi.piedpiper.uno',
  ];

  final Map<String, PipedResolvedStream> _cache = {};
  int _rateLimitUntil = 0;
  int _instanceIndex = 0;

  String get _instance => _instances[_instanceIndex % _instances.length];

  Future<PipedResolvedStream?> resolve(Track track) async {
    if (_cache.containsKey(track.id)) return _cache[track.id];

    final query = '${track.artist} ${track.title}'.trim();
    for (var attempt = 0; attempt < _instances.length; attempt++) {
      try {
        final result = await _searchAndResolve(query, _instance);
        if (result != null) {
          _cache[track.id] = result;
          return result;
        }
      } catch (e) {
        debugPrint('Piped instance $_instance failed: $e');
        _instanceIndex++;
      }
    }
    return null;
  }

  Future<PipedResolvedStream?> _searchAndResolve(String query, String instance) async {
    if (_rateLimitUntil > DateTime.now().millisecondsSinceEpoch) {
      return null;
    }

    final searchRes = await http.get(
      Uri.parse('$instance/search?q=${Uri.encodeComponent(query)}&filter=music_songs'),
      headers: _headers,
    ).timeout(const Duration(seconds: 5));

    if (searchRes.statusCode == 429) {
      _rateLimitUntil = DateTime.now().millisecondsSinceEpoch + 30000;
      return null;
    }
    if (searchRes.statusCode != 200) return null;

    final searchData = jsonDecode(searchRes.body) as Map<String, dynamic>;
    final items = searchData['items'] as List?;
    if (items == null || items.isEmpty) return null;

    final first = items[0] as Map<String, dynamic>;
    final videoUrl = first['url'] as String? ?? '';
    final videoId = videoUrl.split('?v=').lastOrNull;
    final duration = first['duration'] as int?;

    if (videoId == null || videoId.isEmpty) return null;

    final streamRes = await http.get(
      Uri.parse('$instance/streams/$videoId'),
      headers: _headers,
    ).timeout(const Duration(seconds: 5));

    if (streamRes.statusCode == 429) {
      _rateLimitUntil = DateTime.now().millisecondsSinceEpoch + 30000;
      return null;
    }
    if (streamRes.statusCode != 200) return null;

    final streamData = jsonDecode(streamRes.body) as Map<String, dynamic>;
    final audioStreams = streamData['audioStreams'] as List?;

    if (audioStreams == null || audioStreams.isEmpty) return null;

    final best =
        (audioStreams.last as Map<String, dynamic>)['url'] as String?;
    if (best == null || best.isEmpty) return null;

    return PipedResolvedStream(
      url: best,
      duration: duration != null ? Duration(seconds: duration) : null,
    );
  }

  Map<String, String> get _headers => {
        'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) Musik/1.0',
      };

  void clearCache() => _cache.clear();
}
