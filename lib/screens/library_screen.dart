import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../data/sample_library.dart';
import '../models/track.dart';
import '../navigation/app_routes.dart';
import '../services/app_navigation_service.dart';
import '../services/auth_service.dart';
import '../services/deezer_api_service.dart';
import '../theme/app_theme.dart';
import '../utils/album_builder.dart';
import 'playlist_screen.dart';

class LibraryScreen extends StatefulWidget {
  const LibraryScreen({super.key});

  @override
  State<LibraryScreen> createState() => _LibraryScreenState();
}

class _LibraryScreenState extends State<LibraryScreen> {
  String _filter = 'Playlists';
  bool _gridView = false;

  static const _filters = ['Playlists', 'Artists', 'Albums', 'Podcasts & shows'];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<DeezerApiService>().fetchChart();
    });
  }

  List<LibraryItem> _items(List<Track> chart) {
    final all = SampleLibrary.itemsForChart(chart);
    switch (_filter) {
      case 'Artists':
        return all.where((i) => i.type == LibraryItemType.artist).toList();
      case 'Albums':
        return all.where((i) => i.type == LibraryItemType.album).toList();
      case 'Podcasts & shows':
        return all.where((i) => i.type == LibraryItemType.podcast).toList();
      default:
        return all.where((i) => i.type == LibraryItemType.playlist).toList();
    }
  }

  List<Track> _playlistTracks(String id, List<Track> chart) {
    if (chart.isEmpty) return [];
    switch (id) {
      case 'favorites':
        return chart.take(8).toList();
      case 'fresh':
        return chart.length > 5 ? chart.sublist(5) : chart;
      case 'chill':
        return chart.take(12).toList();
      default:
        return chart;
    }
  }

  void _openItem(LibraryItem item, List<Track> chart) {
    final nav = context.read<AppNavigationService>();

    if (item.searchQuery != null) {
      nav.openSearchTab(item.searchQuery);
      return;
    }

    switch (item.type) {
      case LibraryItemType.album:
        if (chart.isNotEmpty) {
          AppRoutes.album(context, album: AlbumBuilder.fromTrack(chart.first, chart));
        }
        break;
      case LibraryItemType.artist:
        nav.openSearchTab(item.title);
        break;
      case LibraryItemType.playlist:
        final tracks = _playlistTracks(item.id, chart);
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => PlaylistScreen(
              title: item.title,
              subtitle: item.subtitle,
              gradientTop: item.color,
              gradientBottom: AppColors.background,
              tracks: tracks,
            ),
          ),
        );
        break;
      case LibraryItemType.podcast:
        nav.openSearchTab('podcast');
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthService>().user;
    final chart = context.watch<DeezerApiService>().chartTracks;
    final items = _items(chart);

    return Scaffold(
      backgroundColor: AppColors.background,
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
                      backgroundColor: AppColors.surfaceElevated,
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
                    chart.isEmpty ? 'Loading catalog…' : '${items.length} items',
                    style: const TextStyle(color: AppColors.textSecondary, fontSize: 13),
                  ),
                  const Spacer(),
                  IconButton(
                    icon: Icon(_gridView ? Icons.view_list : Icons.grid_view, size: 22),
                    color: AppColors.textSecondary,
                    onPressed: () => setState(() => _gridView = !_gridView),
                  ),
                ],
              ),
            ),
            Expanded(
              child: chart.isEmpty && items.isEmpty
                  ? const Center(child: CircularProgressIndicator(color: AppColors.musikAccent))
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
                          itemBuilder: (_, i) => _GridItem(item: items[i], onTap: () => _openItem(items[i], chart)),
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
                                child: Icon(
                                  item.icon ?? (item.isCircular ? Icons.person : Icons.album),
                                  color: Colors.white70,
                                ),
                              ),
                              title: Text(item.title, style: const TextStyle(fontWeight: FontWeight.w600)),
                              subtitle: Text(item.subtitle, style: const TextStyle(color: AppColors.textSecondary, fontSize: 13)),
                              onTap: () => _openItem(item, chart),
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
  final LibraryItem item;
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
                item.icon ?? Icons.album,
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
