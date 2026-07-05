import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/track.dart';
import '../navigation/app_routes.dart';
import '../services/app_navigation_service.dart';
import '../services/audio_player_service.dart';
import '../services/auth_service.dart';
import '../services/deezer_api_service.dart';
import '../services/library_service.dart';
import '../theme/app_theme.dart';
import '../utils/album_builder.dart';
import 'playlist_screen.dart';

enum _LibraryItemType { playlist, artist, album }

class _LibraryItem {
  final String id;
  final String title;
  final String subtitle;
  final _LibraryItemType type;
  final Color color;
  final IconData icon;
  final List<Track> tracks;

  const _LibraryItem({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.type,
    required this.color,
    required this.icon,
    this.tracks = const [],
  });

  bool get isCircular => type == _LibraryItemType.artist;
}

class LibraryScreen extends StatefulWidget {
  const LibraryScreen({super.key});

  @override
  State<LibraryScreen> createState() => _LibraryScreenState();
}

class _LibraryScreenState extends State<LibraryScreen> {
  String _filter = 'Playlists';
  bool _gridView = false;

  static const _filters = ['Playlists', 'Artists', 'Albums'];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<DeezerApiService>().fetchChart();
    });
  }

  List<_LibraryItem> _items({
    required List<Track> chart,
    required List<Track> recent,
    required LibraryService library,
  }) {
    final visibleChart = library.visibleTracks(chart);
    final items = <_LibraryItem>[];

    if (_filter == 'Playlists') {
      if (library.likedTracks.isNotEmpty) {
        items.add(_LibraryItem(
          id: 'liked',
          title: 'Liked Songs',
          subtitle: 'Playlist - ${library.likedTracks.length} songs',
          type: _LibraryItemType.playlist,
          color: AppColors.musikViolet,
          icon: Icons.favorite,
          tracks: library.likedTracks,
        ));
      }
      if (recent.isNotEmpty) {
        items.add(_LibraryItem(
          id: 'recent',
          title: 'Recently Played',
          subtitle: 'Playlist - ${recent.length} songs',
          type: _LibraryItemType.playlist,
          color: AppColors.musikSecondary,
          icon: Icons.history,
          tracks: recent,
        ));
      }
      for (final playlist in library.playlists) {
        items.add(_LibraryItem(
          id: playlist.id,
          title: playlist.name,
          subtitle: playlist.subtitle,
          type: _LibraryItemType.playlist,
          color: context.surfaceHighlight,
          icon: Icons.queue_music,
          tracks: playlist.tracks,
        ));
      }
      if (visibleChart.isNotEmpty) {
        items.add(_LibraryItem(
          id: 'chart',
          title: 'Top Chart',
          subtitle: 'Live playlist - ${visibleChart.length} songs',
          type: _LibraryItemType.playlist,
          color: AppColors.musikAccent,
          icon: Icons.trending_up,
          tracks: visibleChart,
        ));
      }
      return items;
    }

    if (_filter == 'Artists') {
      final artists = <String, List<Track>>{};
      for (final track in visibleChart) {
        artists.putIfAbsent(track.artist, () => []).add(track);
      }
      return artists.entries
          .map(
            (entry) => _LibraryItem(
              id: entry.key,
              title: entry.key,
              subtitle: 'Artist - ${entry.value.length} songs',
              type: _LibraryItemType.artist,
              color: AppColors.musikSecondary,
              icon: Icons.person,
              tracks: entry.value,
            ),
          )
          .toList();
    }

    final albums = <String, List<Track>>{};
    for (final track in visibleChart) {
      final key = '${track.album}|${track.artist}';
      albums.putIfAbsent(key, () => []).add(track);
    }
    return albums.entries.map((entry) {
      final first = entry.value.first;
      return _LibraryItem(
        id: entry.key,
        title: first.album.isEmpty ? first.title : first.album,
        subtitle: 'Album - ${first.artist}',
        type: _LibraryItemType.album,
        color: context.surfaceHighlight,
        icon: Icons.album,
        tracks: entry.value,
      );
    }).toList();
  }

  void _openItem(_LibraryItem item) {
    final nav = context.read<AppNavigationService>();

    switch (item.type) {
      case _LibraryItemType.album:
        if (item.tracks.isNotEmpty) {
          AppRoutes.album(context, album: AlbumBuilder.fromTrack(item.tracks.first, item.tracks));
        }
        break;
      case _LibraryItemType.artist:
        nav.openSearchTab(item.title);
        break;
      case _LibraryItemType.playlist:
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => PlaylistScreen(
              title: item.title,
              subtitle: item.subtitle,
              gradientTop: item.color,
              gradientBottom: context.background,
              tracks: item.tracks,
            ),
          ),
        );
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthService>().user;
    final chart = context.watch<DeezerApiService>().chartTracks;
    final player = context.watch<AudioPlayerService>();
    final library = context.watch<LibraryService>();
    final items = _items(chart: chart, recent: player.playHistory, library: library);

    return Scaffold(
      backgroundColor: context.background,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 8, 0),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () => AppRoutes.profile(context),
                    child: CircleAvatar(
                      radius: 16,
                      backgroundColor: AppColors.musikAccent,
                      child: Text(
                        (user?.name.isNotEmpty == true ? user!.name[0] : 'M').toUpperCase(),
                        style: const TextStyle(color: Colors.black, fontWeight: FontWeight.w700, fontSize: 14),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Text('Library', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w700)),
                  ),
                  IconButton(
                    icon: const Icon(Icons.add),
                    onPressed: () => context.read<AppNavigationService>().openSearchTab(),
                    tooltip: 'Find music',
                  ),
                  IconButton(
                    icon: const Icon(Icons.search),
                    onPressed: () => context.read<AppNavigationService>().openSearchTab(),
                  ),
                  IconButton(
                    icon: const Icon(Icons.usb, size: 22),
                    tooltip: 'USB Music',
                    onPressed: () => AppRoutes.usb(context),
                  ),
                ],
              ),
            ),
            SizedBox(
              height: 44,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                itemCount: _filters.length,
                itemBuilder: (_, i) {
                  final label = _filters[i];
                  final selected = _filter == label;
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: FilterChip(
                      label: Text(label, style: const TextStyle(fontSize: 13)),
                      selected: selected,
                      onSelected: (_) => setState(() => _filter = label),
                      backgroundColor: context.surfaceElevated,
                      selectedColor: AppColors.musikAccent,
                      checkmarkColor: Colors.black,
                      labelStyle: TextStyle(
                        color: selected ? Colors.black : Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                      side: BorderSide.none,
                    ),
                  );
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              child: Row(
                children: [
                  Text(
                    chart.isEmpty ? 'Loading catalog...' : '${items.length} items',
                    style: TextStyle(color: context.textSecondary, fontSize: 13),
                  ),
                  const Spacer(),
                  IconButton(
                    icon: Icon(_gridView ? Icons.view_list : Icons.grid_view, size: 22),
                    color: context.textSecondary,
                    onPressed: () => setState(() => _gridView = !_gridView),
                  ),
                ],
              ),
            ),
            Expanded(
              child: chart.isEmpty && items.isEmpty
                  ? const Center(child: CircularProgressIndicator(color: AppColors.musikAccent))
                  : items.isEmpty
                      ? Center(
                          child: Padding(
                            padding: const EdgeInsets.all(24),
                            child: Text(
                              'Your library will update as you like songs and play music.',
                              textAlign: TextAlign.center,
                              style: TextStyle(color: context.textSecondary),
                            ),
                          ),
                        )
                      : _gridView
                          ? GridView.builder(
                              padding: const EdgeInsets.all(16),
                              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: 2,
                                mainAxisSpacing: 16,
                                crossAxisSpacing: 16,
                                childAspectRatio: 0.85,
                              ),
                              itemCount: items.length,
                              itemBuilder: (_, i) => _GridItem(item: items[i], onTap: () => _openItem(items[i])),
                            )
                          : ListView.builder(
                              padding: const EdgeInsets.symmetric(horizontal: 8),
                              itemCount: items.length,
                              itemBuilder: (_, i) {
                                final item = items[i];
                                return ListTile(
                                  leading: Container(
                                    width: 48,
                                    height: 48,
                                    decoration: BoxDecoration(
                                      color: item.color,
                                      borderRadius: item.isCircular
                                          ? BorderRadius.circular(24)
                                          : BorderRadius.circular(6),
                                    ),
                                    child: Icon(item.icon, color: Colors.white70),
                                  ),
                                  title: Text(item.title, style: const TextStyle(fontWeight: FontWeight.w600)),
                                  subtitle: Text(item.subtitle, style: TextStyle(color: context.textSecondary, fontSize: 13)),
                                  onTap: () => _openItem(item),
                                );
                              },
                            ),
            ),
          ],
        ),
      ),
    );
  }
}

class _GridItem extends StatelessWidget {
  final _LibraryItem item;
  final VoidCallback onTap;

  const _GridItem({required this.item, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Container(
              width: double.infinity,
              decoration: BoxDecoration(
                color: item.color,
                borderRadius: BorderRadius.circular(item.isCircular ? 80 : 8),
              ),
              child: Icon(
                item.icon,
                size: 48,
                color: Colors.white.withValues(alpha: 0.7),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(item.title, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}


