import 'package:flutter/foundation.dart';
import 'package:youtube_explode_dart/youtube_explode_dart.dart';

import '../models/track.dart';

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

/// Resolves Deezer catalog tracks to full-length audio streams via YouTube.
class StreamResolverService {
  final YoutubeExplode _yt = YoutubeExplode();
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

    try {
      final query = '${track.artist} ${track.title}'.trim();
      final results = await _yt.search.search(query);
      final candidates = results.take(8).toList();
      if (candidates.isEmpty) throw StateError('No YouTube match for "$query"');

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
      );

      String url;
      final duration = pick.duration ?? track.duration;

      if (manifest.audioOnly.isNotEmpty) {
        url = manifest.audioOnly.withHighestBitrate().url.toString();
      } else if (manifest.muxed.isNotEmpty) {
        url = manifest.muxed.withHighestBitrate().url.toString();
      } else {
        throw StateError('No playable streams for ${pick.title}');
      }

      final resolved = ResolvedStream(url: url, duration: duration, isFullLength: true);
      _cache[track.id] = resolved;
      return resolved;
    } catch (e) {
      debugPrint('Full stream resolve failed for ${track.title}: $e');
      if (track.previewUrl != null && track.previewUrl!.isNotEmpty) {
        return ResolvedStream(
          url: track.previewUrl!,
          duration: const Duration(seconds: 30),
          isFullLength: false,
        );
      }
      rethrow;
    }
  }

  void clearCache() => _cache.clear();

  void dispose() => _yt.close();
}
