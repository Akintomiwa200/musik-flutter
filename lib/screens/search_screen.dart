import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../data/sample_content.dart';
import '../models/track.dart';
import '../services/app_navigation_service.dart';
import '../services/audio_player_service.dart';
import '../services/deezer_api_service.dart';
import '../services/preferences_service.dart';
import '../navigation/app_routes.dart';
import '../theme/app_theme.dart';
import '../widgets/track_cover.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final _searchController = TextEditingController();
  final _focusNode = FocusNode();
  bool _active = false;
  String _query = '';
  Timer? _debounce;
  List<Track> _apiResults = [];
  bool _searching = false;

  @override
  void initState() {
    super.initState();
    _focusNode.addListener(() {
      setState(() => _active = _focusNode.hasFocus || _query.isNotEmpty);
    });
    context.read<AppNavigationService>().addListener(_onNavChanged);
    WidgetsBinding.instance.addPostFrameCallback((_) => _onNavChanged());
  }

  void _onNavChanged() {
    final nav = context.read<AppNavigationService>();
    if (nav.tabIndex != 1) return;
    final q = nav.consumePendingSearch();
    if (q != null) _activateSearch(q);
  }

  void _activateSearch(String query) {
    setState(() {
      _active = true;
      _query = query;
      _searchController.text = query;
    });
    _onQueryChanged(query);
    _focusNode.requestFocus();
  }

  void _openCategory(BrowseCategory category) {
    _activateSearch(category.searchQuery);
  }

  void _onQueryChanged(String v) {
    setState(() => _query = v);
    _debounce?.cancel();
    if (v.trim().isEmpty) {
      setState(() {
        _apiResults = [];
        _searching = false;
      });
      return;
    }
    _debounce = Timer(const Duration(milliseconds: 450), () async {
      setState(() => _searching = true);
      final results = await context.read<DeezerApiService>().search(v);
      if (mounted) {
        setState(() {
          _apiResults = results;
          _searching = false;
        });
      }
    });
  }

  @override
  void dispose() {
    context.read<AppNavigationService>().removeListener(_onNavChanged);
    _debounce?.cancel();
    _searchController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _cancel() {
    _searchController.clear();
    _focusNode.unfocus();
    setState(() {
      _query = '';
      _active = false;
    });
  }

  List<RecentSearchItem> get _recentItems {
    final prefs = context.read<PreferencesService>();
    if (prefs.recentSearches.isNotEmpty) {
      return prefs.recentSearches.map((e) {
        return RecentSearchItem(
          id: e['id'] as String,
          title: e['title'] as String,
          subtitle: e['subtitle'] as String,
          isArtist: e['isArtist'] as bool,
          color: Color(e['color'] as int),
        );
      }).toList();
    }
    return SampleContent.defaultRecentSearches;
  }

  List<RecentSearchItem> get _filteredRecent {
    if (_query.isEmpty) return _recentItems;
    return _recentItems
        .where((r) => r.title.toLowerCase().contains(_query.toLowerCase()))
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    if (_active) {
      return _buildActiveSearch();
    }
    return _buildBrowse();
  }

  Widget _buildBrowse() {
    final sections = <String, List<BrowseCategory>>{};
    for (final cat in SampleContent.browseCategories) {
      sections.putIfAbsent(cat.section, () => []).add(cat);
    }

    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                child: Row(
                  children: [
                    const Expanded(
                      child: Text(
                        'Search',
                        style: TextStyle(fontSize: 28, fontWeight: FontWeight.w700),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.camera_alt_outlined),
                      onPressed: () => AppRoutes.scanner(context),
                    ),
                  ],
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: GestureDetector(
                  onTap: () => setState(() => _active = true),
                  child: Container(
                    height: 48,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: const Row(
                      children: [
                        Icon(Icons.search, color: Colors.black54),
                        SizedBox(width: 12),
                        Text(
                          'Artists, songs, or podcasts',
                          style: TextStyle(color: Colors.black54, fontSize: 15),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            for (final entry in sections.entries) ...[
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 28, 16, 12),
                  child: Text(
                    entry.key,
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                  ),
                ),
              ),
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                sliver: SliverGrid(
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    mainAxisSpacing: 12,
                    crossAxisSpacing: 12,
                    childAspectRatio: 1.8,
                  ),
                  delegate: SliverChildBuilderDelegate(
                    (context, i) => _BrowseTile(
                      category: entry.value[i],
                      onTap: () => _openCategory(entry.value[i]),
                    ),
                    childCount: entry.value.length,
                  ),
                ),
              ),
            ],
            const SliverPadding(padding: EdgeInsets.only(bottom: 120)),
          ],
        ),
      ),
    );
  }

  Widget _buildActiveSearch() {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 8, 16, 8),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _searchController,
                      focusNode: _focusNode,
                      autofocus: true,
                      onChanged: _onQueryChanged,
                      style: const TextStyle(color: Colors.black),
                      decoration: InputDecoration(
                        hintText: 'Artists, songs, or podcasts',
                        hintStyle: const TextStyle(color: Colors.black45),
                        prefixIcon: const Icon(Icons.search, color: Colors.black54),
                        filled: true,
                        fillColor: Colors.white,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide.none,
                        ),
                        contentPadding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),
                  TextButton(
                    onPressed: _cancel,
                    child: const Text('Cancel', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
                  ),
                ],
              ),
            ),
            if (_searching)
              const Padding(
                padding: EdgeInsets.all(16),
                child: Center(child: CircularProgressIndicator(color: AppColors.musikAccent)),
              )
            else if (_query.trim().isNotEmpty)
              Expanded(
                child: _apiResults.isEmpty
                    ? const Center(
                        child: Text('No results', style: TextStyle(color: AppColors.textSecondary)),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        itemCount: _apiResults.length,
                        itemBuilder: (context, i) {
                          final track = _apiResults[i];
                          return ListTile(
                            contentPadding: EdgeInsets.zero,
                            leading: TrackCover(track: track, size: 48),
                            title: Text(track.title, style: const TextStyle(fontWeight: FontWeight.w600)),
                            subtitle: Text(
                              '${track.artist} · ${track.album}',
                              style: const TextStyle(color: AppColors.textSecondary, fontSize: 13),
                            ),
                            onTap: () {
                              context.read<AudioPlayerService>().playTrack(
                                    track,
                                    queue: _apiResults,
                                    index: i,
                                  );
                            },
                          );
                        },
                      ),
              )
            else
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: _filteredRecent.length,
                  itemBuilder: (context, i) {
                    final item = _filteredRecent[i];
                    return ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color: item.color,
                          shape: item.isArtist ? BoxShape.circle : BoxShape.rectangle,
                          borderRadius: item.isArtist ? null : BorderRadius.circular(4),
                        ),
                        child: Icon(
                          item.isArtist ? Icons.person : Icons.album,
                          color: Colors.white70,
                        ),
                      ),
                      title: Text(item.title, style: const TextStyle(fontWeight: FontWeight.w600)),
                      subtitle: Text(item.subtitle, style: const TextStyle(color: AppColors.textSecondary, fontSize: 13)),
                      onTap: () {
                        context.read<PreferencesService>().addRecentSearch({
                          'id': item.id,
                          'title': item.title,
                          'subtitle': item.subtitle,
                          'isArtist': item.isArtist,
                          'color': item.color.toARGB32(),
                        });
                        _activateSearch(item.title);
                      },
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

class _BrowseTile extends StatelessWidget {
  final BrowseCategory category;
  final VoidCallback onTap;

  const _BrowseTile({required this.category, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: category.color,
      borderRadius: BorderRadius.circular(8),
      clipBehavior: Clip.hardEdge,
      child: InkWell(
        onTap: onTap,
        child: Stack(
        children: [
          Positioned(
            left: 12,
            top: 12,
            right: 48,
            child: Text(
              category.title,
              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
            ),
          ),
          Positioned(
            right: -8,
            bottom: -8,
            child: Transform.rotate(
              angle: 0.35,
              child: Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.25),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Icon(Icons.album, color: Colors.white.withValues(alpha: 0.5)),
              ),
            ),
          ),
        ],
        ),
      ),
    );
  }
}
