import 'dart:math';

import '../models/track.dart';

class RecommendationService {
  final Random _rng = Random();

  List<Track> similarTo(Track seed, List<Track> catalog, {int count = 10}) {
    final pool = catalog.where((t) => t.id != seed.id).toList();
    if (pool.isEmpty) return [];

    final sameArtist = pool.where((t) => t.artist == seed.artist).toList();
    final sameAlbum = pool.where((t) => t.album == seed.album && t.artist == seed.artist).toList();

    final result = <Track>[];
    final added = <String>{};

    for (final track in [...sameAlbum, ...sameArtist]) {
      if (!added.contains(track.id)) {
        result.add(track);
        added.add(track.id);
      }
    }

    for (final track in pool) {
      if (result.length >= count) break;
      if (added.contains(track.id)) continue;
      final seedWords = seed.title.toLowerCase().split(RegExp(r'\s+'));
      final trackWords = track.title.toLowerCase().split(RegExp(r'\s+'));
      final overlap = seedWords.where((w) => trackWords.contains(w)).length;
      if (overlap > 0) {
        result.add(track);
        added.add(track.id);
      }
    }

    pool.shuffle(_rng);
    for (final track in pool) {
      if (result.length >= count) break;
      if (added.contains(track.id)) continue;
      result.add(track);
      added.add(track.id);
    }

    return result;
  }

  /// Returns named sections of recommendations based on the user's profile.
  /// [playHistory] — most recent first.
  /// [likedTracks] — tracks the user has liked.
  /// [catalog] — full pool to recommend from.
  Map<String, List<Track>> forProfile({
    required List<Track> playHistory,
    required List<Track> likedTracks,
    required List<Track> catalog,
    int sectionCount = 6,
  }) {
    final result = <String, List<Track>>{};
    final used = <String>{};

    if (catalog.isEmpty) return result;

    // 1. Because you listened to (last played track)
    final recentSeed = playHistory.where((t) => !likedTracks.any((l) => l.id == t.id)).toList();
    if (recentSeed.isNotEmpty) {
      final recs = similarTo(recentSeed.first, catalog, count: sectionCount)
          .where((t) => !used.contains(t.id))
          .toList();
      if (recs.isNotEmpty) {
        result['Because you listened to "${recentSeed.first.title}"'] = recs;
        used.addAll(recs.map((t) => t.id));
      }
    }

    // 2. Based on your likes (pick a random liked track)
    if (likedTracks.isNotEmpty) {
      final seed = likedTracks[_rng.nextInt(likedTracks.length)];
      final recs = similarTo(seed, catalog, count: sectionCount)
          .where((t) => !used.contains(t.id))
          .toList();
      if (recs.isNotEmpty) {
        result['Based on your likes'] = recs;
        used.addAll(recs.map((t) => t.id));
      }
    }

    // 3. More of what you play (from play history artists)
    final artistSeeds = <String>{for (final t in playHistory) t.artist};
    if (artistSeeds.isNotEmpty) {
      final byArtist = catalog
          .where((t) => artistSeeds.contains(t.artist) && !used.contains(t.id))
          .take(sectionCount)
          .toList();
      if (byArtist.isNotEmpty) {
        result['More from your favorite artists'] = byArtist;
        used.addAll(byArtist.map((t) => t.id));
      }
    }

    // 4. Random discovery (from catalog, not yet used)
    final discovery = catalog
        .where((t) => !used.contains(t.id))
        .toList();
    discovery.shuffle(_rng);
    if (discovery.isNotEmpty) {
      result['Discover something new'] = discovery.take(sectionCount).toList();
    }

    return result;
  }
}
