import 'package:flutter/material.dart';

import '../models/album.dart';
import '../models/track.dart';
import '../theme/app_theme.dart';

class AlbumBuilder {
  AlbumBuilder._();

  static Album playlist(String title, String subtitle, List<Track> tracks, {Color? color}) {
    final c = color ?? AppColors.musikAccent;
    return Album(
      id: 'playlist-${title.hashCode}',
      title: title,
      artist: subtitle,
      year: DateTime.now().year,
      gradientTop: c,
      gradientBottom: AppColors.background,
      tracks: tracks.isNotEmpty ? tracks : const [],
    );
  }

  static Album fromTrack(Track seed, List<Track> catalog) {
    final sameAlbum = catalog
        .where((t) => t.album == seed.album && t.artist == seed.artist)
        .toList();
    final tracks = sameAlbum.length > 1 ? sameAlbum : catalog.take(15).toList();
    return Album(
      id: 'album-${seed.id}',
      title: seed.album.isNotEmpty ? seed.album : seed.title,
      artist: seed.artist,
      year: DateTime.now().year,
      gradientTop: AppColors.musikViolet,
      gradientBottom: AppColors.background,
      tracks: tracks,
    );
  }
}
