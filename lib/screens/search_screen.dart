import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/track.dart';
import '../navigation/app_routes.dart';
import '../services/app_navigation_service.dart';
import '../services/audio_player_service.dart';
import '../services/deezer_api_service.dart';
import '../services/library_service.dart';
import '../services/preferences_service.dart';
import '../services/recommendation_service.dart';
import '../theme/app_theme.dart';
import '../utils/album_builder.dart';
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
  String _tab = 'All';
  Timer? _debounce;
  List<Track> _apiResults = [];
  bool _searching = false;

  static const _tabs = ['All', 'Songs', 'Artists', 'Albums'];

  @override
  void initState() {
    super.initState();
    _focusNode.addListener(() {
      setState(() => _active = _focusNode.hasFocus || _query.isNotEmpty);
    });
    context.read<AppNavigationService>().addListener(_onNavChanged);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _onNavChanged();
      context.read<DeezerApiService>().fetchChart();
    });
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

  void _onQueryChanged(String value) {
    setState(() => _query = value);
    _debounce?.cancel();
    if (value.trim().isEmpty) {
      setState(() {
        _apiResults = [];
        _searching = false;
      });
      return;
    }
    _debounce = Timer(const Duration(milliseconds: 450), () async {
      setState(() => _searching = true);
      final results = await context.read<DeezerApiService>().search(value);
      if (!mounted) return;
      setState(() {
        _apiResults = context.read<LibraryService>().visibleTracks(results);
        _searching = false;
      });
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
      _tab = 'All';
    });
  }

  List<Track> _tracksForAlbum(String album, String artist) =>
      _apiResults.where((track) => track.album == album && track.artist == artist).toList();

  Future<void> _saveRecent({
    required String id,
    required String title,
    required String subtitle,
    required bool isArtist,
    required Color color,
  }) {
    return context.read<PreferencesService>().addRecentSearch({
      'id': id,
      'title': title,
      'subtitle': subtitle,
      'isArtist': isArtist,
      'color': color.toARGB32(),
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_active) return _buildActiveSearch();
    return _buildBrowse();
  }

  Widget _buildBrowse() {
    final deezer = context.watch<DeezerApiService>();
    final player = context.watch<AudioPlayerService>();
    final library = context.watch<LibraryService>();
    final recommender = context.read<RecommendationService>();
    final chart = library.visibleTracks(deezer.chartTracks);
    final playHistory = player.playHistory;
    final liked = library.likedTracks;
    final catalog = [...chart, ...liked];

    // Compute personalized sections from user profile
    final profileSections = recommender.forProfile(
      playHistory: playHistory,
      likedTracks: liked,
      catalog: catalog,
    );

    // Build all sections
    final sections = <Widget>[];

    // Title row
    sections.add(
      Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
        child: Row(
          children: [
            Text('Search', style: TextStyle(fontSize: 28, fontWeight: FontWeight.w700, color: context.textPrimary)),
            const Spacer(),
            IconButton(
              icon: Icon(Icons.camera_alt_outlined, color: context.textPrimary),
              onPressed: () => AppRoutes.scanner(context),
            ),
          ],
        ),
      ),
    );

    // Search bar
    sections.add(
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: GestureDetector(
          onTap: () => setState(() => _active = true),
          child: Container(
            height: 48,
            decoration: BoxDecoration(color: context.surfaceHighlight, borderRadius: BorderRadius.circular(8)),
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                Icon(Icons.search, color: context.textSecondary),
                const SizedBox(width: 12),
                Text('Songs, artists, or albums', style: TextStyle(color: context.textSecondary, fontSize: 15)),
              ],
            ),
          ),
        ),
      ),
    );

    // Personalized recommendation sections
    if (profileSections.isNotEmpty) {
      for (final entry in profileSections.entries) {
        final tracks = entry.value;
        if (tracks.isEmpty) continue;
        sections.add(_SectionHeader(title: entry.key));
        sections.add(
          SizedBox(
            height: 64,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: tracks.length,
              itemBuilder: (context, i) {
                final track = tracks[i];
                return Padding(
                  padding: const EdgeInsets.only(right: 12),
                  child: _TrackResult(
                    track: track,
                    queue: tracks,
                    onTap: _playTrack,
                  ),
                );
              },
            ),
          ),
        );
      }
    }

    // Top songs (chart) - always shown as fallback / trending
    if (chart.isNotEmpty) {
      sections.add(const _SectionHeader(title: 'Trending now'));
      sections.add(
        SizedBox(
          height: 64,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: chart.length > 10 ? 10 : chart.length,
            itemBuilder: (context, i) {
              final track = chart[i];
              return Padding(
                padding: const EdgeInsets.only(right: 12),
                child: _TrackResult(
                  track: track,
                  queue: chart,
                  onTap: _playTrack,
                ),
              );
            },
          ),
        ),
      );
    } else if (profileSections.isEmpty) {
      sections.add(
        const Padding(
          padding: EdgeInsets.all(24),
          child: Center(child: CircularProgressIndicator(color: AppColors.musikAccent)),
        ),
      );
    }

    // Artists
    final artists = <String>{for (final track in chart) track.artist}.take(12).toList();
    if (artists.isNotEmpty) {
      sections.add(const _SectionHeader(title: 'Artists'));
      sections.add(
        SizedBox(
          height: 124,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: artists.length,
            itemBuilder: (context, i) {
              final artist = artists[i];
              return _ArtistBrowseItem(
                artist: artist,
                onTap: () => _openArtist(artist),
              );
            },
          ),
        ),
      );
    }

    // Albums
    final albums = <String, Track>{};
    for (final track in chart) {
      final albumTitle = track.album.trim();
      if (albumTitle.isNotEmpty) {
        albums.putIfAbsent('$albumTitle|${track.artist}', () => track);
      }
    }
    final albumTracks = albums.values.take(12).toList();
    if (albumTracks.isNotEmpty) {
      sections.add(const _SectionHeader(title: 'Albums'));
      sections.add(
        SizedBox(
          height: 188,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: albumTracks.length,
            itemBuilder: (context, i) {
              final track = albumTracks[i];
              return _AlbumBrowseItem(
                track: track,
                onTap: () => _openAlbum(track.album, track.artist),
              );
            },
          ),
        ),
      );
    }

    // Podcasts (placeholder)
    sections.add(
      Padding(
        padding: const EdgeInsets.fromLTRB(16, 28, 16, 8),
        child: ListTile(
          contentPadding: EdgeInsets.zero,
          leading: Icon(Icons.podcasts, color: context.textSecondary),
          title: const Text('Podcasts'),
          subtitle: Text('Coming soon', style: TextStyle(color: context.textSecondary)),
        ),
      ),
    );

    return Scaffold(
      backgroundColor: context.background,
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, i) => sections[i],
                childCount: sections.length,
              ),
            ),
            const SliverPadding(padding: EdgeInsets.only(bottom: 120)),
          ],
        ),
      ),
    );
  }

  Widget _buildActiveSearch() {
    return Scaffold(
      backgroundColor: context.background,
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
                      style: TextStyle(color: context.textPrimary),
                      decoration: InputDecoration(
                        hintText: 'Songs, artists, or albums',
                        hintStyle: TextStyle(color: context.textSecondary),
                        prefixIcon: Icon(Icons.search, color: context.textSecondary),
                        filled: true,
                        fillColor: context.surfaceHighlight,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
                        contentPadding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),
                  TextButton(
                    onPressed: _cancel,
                    child: Text('Cancel', style: TextStyle(color: context.accent, fontWeight: FontWeight.w600)),
                  ),
                ],
              ),
            ),
            SizedBox(
              height: 44,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                itemCount: _tabs.length,
                itemBuilder: (_, i) {
                  final tab = _tabs[i];
                  final selected = tab == _tab;
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ChoiceChip(
                      label: Text(tab),
                      selected: selected,
                      onSelected: (_) => setState(() => _tab = tab),
                      selectedColor: AppColors.musikAccent,
                      labelStyle: TextStyle(color: selected ? Theme.of(context).colorScheme.onPrimary : context.textPrimary),
                      side: BorderSide.none,
                      backgroundColor: context.surfaceElevated,
                    ),
                  );
                },
              ),
            ),
            if (_searching)
              const Expanded(child: Center(child: CircularProgressIndicator(color: AppColors.musikAccent)))
            else if (_query.trim().isNotEmpty)
              Expanded(child: _SearchResults(tab: _tab, tracks: _apiResults, onTrackTap: _playTrack, onArtistTap: _openArtist, onAlbumTap: _openAlbum))
            else
              Expanded(child: _RecentSearches(onTap: _activateSearch)),
          ],
        ),
      ),
    );
  }

  Future<void> _playTrack(Track track, List<Track> queue) async {
    await _saveRecent(
      id: track.id,
      title: track.title,
      subtitle: track.artist,
      isArtist: false,
      color: context.surfaceHighlight,
    );
    if (!mounted) return;
    context.read<AudioPlayerService>().playTrack(track, queue: queue, index: queue.indexWhere((item) => item.id == track.id));
  }

  Future<void> _openArtist(String artist) async {
    await _saveRecent(
      id: 'artist-$artist',
      title: artist,
      subtitle: 'Artist',
      isArtist: true,
      color: AppColors.musikSecondary,
    );
    if (!mounted) return;
    context.read<AppNavigationService>().openSearchTab(artist);
  }

  Future<void> _openAlbum(String album, String artist) async {
    final tracks = _tracksForAlbum(album, artist);
    if (tracks.isEmpty) return;
    await _saveRecent(
      id: 'album-$album-$artist',
      title: album,
      subtitle: artist,
      isArtist: false,
      color: AppColors.musikViolet,
    );
    if (!mounted) return;
    AppRoutes.album(context, album: AlbumBuilder.fromTrack(tracks.first, tracks));
  }
}

class _SearchResults extends StatelessWidget {
  final String tab;
  final List<Track> tracks;
  final Future<void> Function(Track track, List<Track> queue) onTrackTap;
  final Future<void> Function(String artist) onArtistTap;
  final Future<void> Function(String album, String artist) onAlbumTap;

  const _SearchResults({
    required this.tab,
    required this.tracks,
    required this.onTrackTap,
    required this.onArtistTap,
    required this.onAlbumTap,
  });

  @override
  Widget build(BuildContext context) {
    if (tracks.isEmpty) {
      return Center(child: Text('No results', style: TextStyle(color: context.textSecondary)));
    }

    final artists = <String>{for (final track in tracks) track.artist}.toList();
    final albums = <String, Track>{};
    for (final track in tracks) {
      albums.putIfAbsent('${track.album}|${track.artist}', () => track);
    }

    final children = <Widget>[];
    if (tab == 'All' || tab == 'Songs') {
      children.addAll(tracks.map((track) => _TrackResult(track: track, queue: tracks, onTap: onTrackTap)));
    }
    if (tab == 'All' || tab == 'Artists') {
      children.addAll(artists.map((artist) => ListTile(
            leading: const CircleAvatar(backgroundColor: AppColors.musikSecondary, child: Icon(Icons.person, color: Colors.white)),
            title: Text(artist),
            subtitle: Text('Artist', style: TextStyle(color: context.textSecondary)),
            onTap: () => onArtistTap(artist),
          )));
    }
    if (tab == 'All' || tab == 'Albums') {
      children.addAll(albums.values.map((track) => ListTile(
            leading: TrackCover(track: track, size: 48),
            title: Text(track.album.isEmpty ? track.title : track.album),
            subtitle: Text('Album - ${track.artist}', style: TextStyle(color: context.textSecondary)),
            onTap: () => onAlbumTap(track.album, track.artist),
          )));
    }

    return ListView(padding: const EdgeInsets.symmetric(horizontal: 16), children: children);
  }
}

class _TrackResult extends StatelessWidget {
  final Track track;
  final List<Track> queue;
  final Future<void> Function(Track track, List<Track> queue) onTap;

  const _TrackResult({required this.track, required this.queue, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: TrackCover(track: track, size: 48),
      title: Text(track.title, style: const TextStyle(fontWeight: FontWeight.w600)),
      subtitle: Text('${track.artist} - ${track.album}', style: TextStyle(color: context.textSecondary, fontSize: 13)),
      onTap: () => onTap(track, queue),
    );
  }
}

class _RecentSearches extends StatelessWidget {
  final ValueChanged<String> onTap;

  const _RecentSearches({required this.onTap});

  @override
  Widget build(BuildContext context) {
    final recent = context.watch<PreferencesService>().recentSearches;
    if (recent.isEmpty) {
      return Center(
        child: Text('Search for music to build your recent searches.', style: TextStyle(color: context.textSecondary)),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: recent.length,
      itemBuilder: (context, i) {
        final item = recent[i];
        final isArtist = item['isArtist'] as bool? ?? false;
        final title = item['title'] as String? ?? '';
        return ListTile(
          contentPadding: EdgeInsets.zero,
          leading: Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: Color(item['color'] as int? ?? context.surfaceHighlight.toARGB32()),
              shape: isArtist ? BoxShape.circle : BoxShape.rectangle,
              borderRadius: isArtist ? null : BorderRadius.circular(4),
            ),
            child: Icon(isArtist ? Icons.person : Icons.album, color: context.textSecondary),
          ),
          title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
          subtitle: Text(item['subtitle'] as String? ?? '', style: TextStyle(color: context.textSecondary, fontSize: 13)),
          onTap: () => onTap(title),
        );
      },
    );
  }
}

class _ArtistBrowseItem extends StatelessWidget {
  final String artist;
  final VoidCallback onTap;

  const _ArtistBrowseItem({required this.artist, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 14),
      child: GestureDetector(
        onTap: onTap,
        child: SizedBox(
          width: 88,
          child: Column(
            children: [
              CircleAvatar(
                radius: 38,
                backgroundColor: context.surfaceHighlight,
                child: Text(
                  artist.isEmpty ? '?' : artist[0].toUpperCase(),
                  style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w700),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                artist,
                maxLines: 2,
                textAlign: TextAlign.center,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AlbumBrowseItem extends StatelessWidget {
  final Track track;
  final VoidCallback onTap;

  const _AlbumBrowseItem({required this.track, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final title = track.album.isEmpty ? track.title : track.album;
    return Padding(
      padding: const EdgeInsets.only(right: 12),
      child: GestureDetector(
        onTap: onTap,
        child: SizedBox(
          width: 132,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TrackCover(track: track, size: 132, borderRadius: 8),
              const SizedBox(height: 8),
              Text(
                title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
              ),
              Text(
                track.artist,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(fontSize: 12, color: context.textSecondary),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  const _SectionHeader({required this.title});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
      child: Text(
        title,
        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
      ),
    );
  }
}


