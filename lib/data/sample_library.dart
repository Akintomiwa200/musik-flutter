import 'package:flutter/material.dart';

import '../models/track.dart';
import '../theme/app_theme.dart';

enum LibraryItemType { playlist, artist, album, podcast }

class LibraryItem {
  final String id;
  final String title;
  final String subtitle;
  final LibraryItemType type;
  final Color color;
  final IconData? icon;
  final String? searchQuery;

  const LibraryItem({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.type,
    required this.color,
    this.icon,
    this.searchQuery,
  });

  bool get isCircular => type == LibraryItemType.artist;
}

class UserPlaylist {
  final String id;
  final String name;
  final int likes;
  final Color color;
  final List<Track> tracks;

  const UserPlaylist({
    required this.id,
    required this.name,
    required this.likes,
    required this.color,
    required this.tracks,
  });

  String get durationLabel {
    final mins = tracks.fold<int>(0, (s, t) => s + (t.duration?.inMinutes ?? 3));
    final h = mins ~/ 60;
    final m = mins % 60;
    if (h > 0) return '${h} hr $m min';
    return '$m min';
  }
}

class SampleLibrary {
  static List<LibraryItem> itemsForChart(List<Track> chart) {
    final count = chart.length;
    final topArtist = chart.isNotEmpty ? chart.first.artist : 'Various Artists';
    final topAlbum = chart.isNotEmpty ? chart.first.album : 'Top Album';

    return [
      const LibraryItem(
        id: 'favorites',
        title: 'My Favorites',
        subtitle: 'Playlist • Saved tracks',
        type: LibraryItemType.playlist,
        color: Color(0xFF7C5CFC),
        icon: Icons.favorite,
      ),
      LibraryItem(
        id: 'chart',
        title: 'Top Chart',
        subtitle: 'Playlist • $count tracks',
        type: LibraryItemType.playlist,
        color: AppColors.musikAccent,
      ),
      LibraryItem(
        id: 'artist-top',
        title: topArtist,
        subtitle: 'Artist',
        type: LibraryItemType.artist,
        color: Color(0xFF7C5CFC),
        searchQuery: topArtist,
      ),
      LibraryItem(
        id: 'album-top',
        title: topAlbum,
        subtitle: 'Album • $topArtist',
        type: LibraryItemType.album,
        color: AppColors.musikSecondary,
      ),
      const LibraryItem(
        id: 'fresh',
        title: 'Fresh Drops',
        subtitle: 'Playlist • Updated today',
        type: LibraryItemType.playlist,
        color: AppColors.musikSecondary,
      ),
      const LibraryItem(
        id: 'chill',
        title: 'Chill Mix',
        subtitle: 'Playlist • Relax & unwind',
        type: LibraryItemType.playlist,
        color: Color(0xFF477D95),
        searchQuery: 'chill music',
      ),
      const LibraryItem(
        id: 'podcast',
        title: 'Musik Podcasts',
        subtitle: 'Podcast • Browse shows',
        type: LibraryItemType.podcast,
        color: Color(0xFF1D3557),
        searchQuery: 'podcast',
      ),
    ];
  }
}
