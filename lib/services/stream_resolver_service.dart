import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:youtube_explode_dart/youtube_explode_dart.dart';

import '../models/track.dart';
import 'piped_resolver_service.dart';

class ResolvedStream {
  final String url;
  final Duration? duration;
  final bool isFullLength;

  const ResolvedStream({
    required this.url,
    this.duration,
    this.isFullLength = true,
  });
}

/// Resolves tracks to full-length audio streams.
/// Runs Piped and YouTube in parallel; first to respond wins.
class StreamResolverService {
  final YoutubeExplode _yt = YoutubeExplode();
  final PipedResolverService _piped = PipedResolverService();
  final Map<String, ResolvedStream> _cache = {};

  Future<ResolvedStream> resolve(Track track) async {
    if (_cache.containsKey(track.id)) return _cache[track.id]!;

    if (track.streamUrl != null && track.streamUrl!.isNotEmpty) {
      final cached = ResolvedStream(url: track.streamUrl!, duration: track.duration);
      _cache[track.id] = cached;
      return cached;
    }

    if (track.hasLocalFile) {
      final local = ResolvedStream(url: track.filePath, duration: track.duration, isFullLength: true);
      _cache[track.id] = local;
      return local;
    }

    // Run Piped and YouTube in parallel, take the first to complete
    final result = await Future.any([
      _resolvePiped(track),
      _resolveYoutube(track),
    ]);

    _cache[track.id] = result;
    return result;
  }

  Future<ResolvedStream> _resolvePiped(Track track) async {
    final piped = await _piped.resolve(track).timeout(const Duration(seconds: 7));
    if (piped != null) {
      return ResolvedStream(url: piped.url, duration: piped.duration ?? track.duration);
    }
    throw TimeoutException('Piped failed');
  }

  Future<ResolvedStream> _resolveYoutube(Track track) async {
    final query = '${track.artist} ${track.title}'.trim();
    final results = await _yt.search.search(query).timeout(const Duration(seconds: 7));
    final candidates = results.take(6).toList();
    if (candidates.isEmpty) throw TimeoutException('No YouTube results');

    Video? pick;
    final titleLower = track.title.toLowerCase();
    final artistLower = track.artist.toLowerCase();

    for (final candidate in candidates) {
      final t = candidate.title.toLowerCase();
      if (t.contains('karaoke') || t.contains('lyrics video') || t.contains('8d audio')) {
        continue;
      }
      if (t.contains(titleLower) || t.contains(artistLower)) {
        pick = candidate;
        break;
      }
    }
    pick ??= candidates.first;

    final manifest = await _yt.videos.streamsClient.getManifest(
      pick.id,
      ytClients: const [YoutubeApiClient.androidVr, YoutubeApiClient.safari],
    ).timeout(const Duration(seconds: 7));

    final duration = pick.duration ?? track.duration;

    String url;
    if (manifest.audioOnly.isNotEmpty) {
      url = manifest.audioOnly.withHighestBitrate().url.toString();
    } else if (manifest.muxed.isNotEmpty) {
      url = manifest.muxed.withHighestBitrate().url.toString();
    } else {
      throw TimeoutException('No audio stream');
    }

    return ResolvedStream(url: url, duration: duration, isFullLength: true);
  }

  void clearCache() => _cache.clear();

  void dispose() {
    _yt.close();
    _piped.clearCache();
  }
}
