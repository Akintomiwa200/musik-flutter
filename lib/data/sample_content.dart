import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

class ArtistItem {
  final String id;
  final String name;
  final Color color;

  const ArtistItem({required this.id, required this.name, required this.color});
}

class PodcastItem {
  final String id;
  final String title;
  final Color color;
  final bool isCategory;
  final String? categoryLabel;

  const PodcastItem({
    required this.id,
    required this.title,
    required this.color,
    this.isCategory = false,
    this.categoryLabel,
  });
}

class BrowseCategory {
  final String id;
  final String title;
  final Color color;
  final String section;
  final String searchQuery;

  const BrowseCategory({
    required this.id,
    required this.title,
    required this.color,
    required this.section,
    required this.searchQuery,
  });
}

class HomeShortcut {
  final String id;
  final String title;
  final Color color;
  final IconData? icon;
  final String? searchQuery;

  const HomeShortcut({
    required this.id,
    required this.title,
    required this.color,
    this.icon,
    this.searchQuery,
  });
}

class RecentSearchItem {
  final String id;
  final String title;
  final String subtitle;
  final bool isArtist;
  final Color color;

  const RecentSearchItem({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.isArtist,
    required this.color,
  });
}

class SampleContent {
  static const artists = [
    ArtistItem(id: 'billie', name: 'Billie Eilish', color: Color(0xFF2D6A4F)),
    ArtistItem(id: 'kanye', name: 'Kanye West', color: Color(0xFF5C4B37)),
    ArtistItem(id: 'ariana', name: 'Ariana Grande', color: Color(0xFF7B4B94)),
    ArtistItem(id: 'drake', name: 'Drake', color: Color(0xFF1E3A5F)),
    ArtistItem(id: 'taylor', name: 'Taylor Swift', color: Color(0xFFB56576)),
    ArtistItem(id: 'weeknd', name: 'The Weeknd', color: Color(0xFF3D0C02)),
    ArtistItem(id: 'beyonce', name: 'Beyoncé', color: Color(0xFFD4A017)),
    ArtistItem(id: 'travis', name: 'Travis Scott', color: Color(0xFF4A0404)),
    ArtistItem(id: 'dua', name: 'Dua Lipa', color: Color(0xFF006D77)),
    ArtistItem(id: 'post', name: 'Post Malone', color: Color(0xFF6C584C)),
    ArtistItem(id: 'rihanna', name: 'Rihanna', color: Color(0xFF9B2226)),
    ArtistItem(id: 'eminem', name: 'Eminem', color: Color(0xFF495057)),
    ArtistItem(id: 'sza', name: 'SZA', color: Color(0xFF5F0F40)),
    ArtistItem(id: 'badbunny', name: 'Bad Bunny', color: Color(0xFFE85D04)),
    ArtistItem(id: 'olivia', name: 'Olivia Rodrigo', color: Color(0xFF9D4EDD)),
  ];

  static const podcasts = [
    PodcastItem(id: 'tech', title: 'Tech Talk Daily', color: Color(0xFF00C9A7)),
    PodcastItem(id: 'culture', title: 'Culture Cast', color: Color(0xFF7C5CFC)),
    PodcastItem(id: 'crime', title: 'More in True crime', color: Color(0xFFFF6B35), isCategory: true, categoryLabel: 'True crime'),
    PodcastItem(id: 'comedy', title: 'More in Comedy', color: Color(0xFFE63946), isCategory: true, categoryLabel: 'Comedy'),
    PodcastItem(id: 'stories', title: 'More in Stories', color: Color(0xFF2D6A4F), isCategory: true, categoryLabel: 'Stories'),
    PodcastItem(id: 'music', title: 'Musik Sessions', color: Color(0xFFF4A261)),
    PodcastItem(id: 'news', title: 'World Brief', color: Color(0xFF264653)),
    PodcastItem(id: 'daily', title: 'Morning Mix', color: Color(0xFF457B9D)),
  ];

  static const browseCategories = [
    BrowseCategory(id: 'pop', title: 'Pop', color: Color(0xFF7C5CFC), section: 'Top genres', searchQuery: 'pop hits'),
    BrowseCategory(id: 'hiphop', title: 'Hip-Hop', color: Color(0xFFFF6B35), section: 'Top genres', searchQuery: 'hip hop'),
    BrowseCategory(id: 'charts', title: 'Charts', color: Color(0xFF1E3264), section: 'Explore', searchQuery: 'top charts'),
    BrowseCategory(id: 'new', title: 'New Music', color: Color(0xFF00C9A7), section: 'Explore', searchQuery: 'new releases'),
    BrowseCategory(id: 'discover', title: 'Discover', color: Color(0xFFE8115B), section: 'Explore', searchQuery: 'trending'),
    BrowseCategory(id: 'mood', title: 'Mood', color: Color(0xFF477D95), section: 'Explore', searchQuery: 'chill vibes'),
    BrowseCategory(id: 'rock', title: 'Rock', color: Color(0xFFBA5D07), section: 'Podcasts & audio', searchQuery: 'rock podcast'),
    BrowseCategory(id: 'comedy_pod', title: 'Comedy', color: Color(0xFFE91429), section: 'Podcasts & audio', searchQuery: 'comedy podcast'),
    BrowseCategory(id: 'news', title: 'News', color: Color(0xFF509BF5), section: 'Podcasts & audio', searchQuery: 'news podcast'),
    BrowseCategory(id: 'sports', title: 'Sports', color: Color(0xFF148A08), section: 'Podcasts & audio', searchQuery: 'sports podcast'),
  ];

  static const homeShortcuts = [
    HomeShortcut(id: 'favorites', title: 'My Favorites', color: Color(0xFF7C5CFC), icon: Icons.favorite),
    HomeShortcut(id: 'top', title: 'Top Hits', color: AppColors.musikAccent),
    HomeShortcut(id: 'new', title: 'Fresh Drops', color: AppColors.musikSecondary),
    HomeShortcut(id: 'chill', title: 'Chill Mix', color: Color(0xFF477D95), searchQuery: 'chill music'),
    HomeShortcut(id: 'usb', title: 'USB Music', color: Color(0xFF148A08), icon: Icons.usb),
  ];

  static const defaultRecentSearches = [
    RecentSearchItem(id: 'pop', title: 'Pop hits', subtitle: 'Search', isArtist: false, color: Color(0xFF7C5CFC)),
    RecentSearchItem(id: 'drake', title: 'Drake', subtitle: 'Artist', isArtist: true, color: Color(0xFF1E3A5F)),
    RecentSearchItem(id: 'rock', title: 'Rock classics', subtitle: 'Search', isArtist: false, color: Color(0xFFBA5D07)),
    RecentSearchItem(id: 'jazz', title: 'Jazz evening', subtitle: 'Search', isArtist: false, color: Color(0xFF457B9D)),
  ];

  static const editorsPicks = [
    HomeShortcut(id: 'ep1', title: 'Global Hits', color: Color(0xFFFF6B35), searchQuery: 'global hits'),
    HomeShortcut(id: 'ep2', title: 'Indie Wave', color: Color(0xFF7C5CFC), searchQuery: 'indie'),
    HomeShortcut(id: 'ep3', title: 'Rock Pulse', color: Color(0xFFBA5D07), searchQuery: 'rock'),
    HomeShortcut(id: 'ep4', title: 'Night Piano', color: Color(0xFF477D95), searchQuery: 'piano'),
    HomeShortcut(id: 'ep5', title: 'Afro Groove', color: Color(0xFF00C9A7), searchQuery: 'afrobeat'),
  ];
}
