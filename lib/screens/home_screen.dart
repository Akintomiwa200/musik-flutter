import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../data/sample_content.dart';
import '../models/catalog_album.dart';
import '../models/track.dart';
import '../navigation/app_routes.dart';
import '../services/app_navigation_service.dart';
import '../services/audio_player_service.dart';
import '../services/auth_service.dart';
import '../services/deezer_api_service.dart';
import '../services/preferences_service.dart';
import '../services/usb_music_service.dart';
import '../theme/app_theme.dart';
import '../utils/album_builder.dart';
import '../widgets/musik_logo.dart';
import '../widgets/track_cover.dart';

class HomeScreen extends StatefulWidget {
  final VoidCallback? onOpenSettings;

  const HomeScreen({super.key, this.onOpenSettings});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _usbService = UsbMusicService();
  List<Track> _localTracks = [];
  bool _loadingLocal = true;

  @override
  void initState() {
    super.initState();
    _loadLocal();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadCatalog());
  }

  String? _artistNameForId(String id) {
    for (final artist in SampleContent.artists) {
      if (artist.id == id) return artist.name;
    }
    return null;
  }

  Future<void> _loadCatalog() async {
    final deezer = context.read<DeezerApiService>();
    final prefs = context.read<PreferencesService>();
    await deezer.fetchHomeCatalog();

    final artistNames = prefs.selectedArtists
        .map(_artistNameForId)
        .whereType<String>()
        .toList();
    if (artistNames.isNotEmpty) {
      await deezer.fetchForYou(artistNames);
    }
  }

  Future<void> _loadLocal() async {
    setState(() => _loadingLocal = true);
    await _usbService.requestPermissions();
    final local = await _usbService.scanLocalMusic();
    if (mounted) {
      setState(() {
        _localTracks = local;
        _loadingLocal = false;
      });
    }
  }

  Future<void> _refresh() async {
    await Future.wait([_loadLocal(), _loadCatalog()]);
  }

  void _openSettings() {
    if (widget.onOpenSettings != null) {
      widget.onOpenSettings!();
    } else {
      AppRoutes.settings(context);
    }
  }

  Future<void> _openCatalogAlbum(CatalogAlbum album) async {
    final deezer = context.read<DeezerApiService>();
    try {
      final tracks = await deezer.fetchAlbumTracks(album.id);
      if (!mounted) return;
      if (tracks.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No tracks found for this album')),
        );
        return;
      }
      AppRoutes.album(
        context,
        album: AlbumBuilder.playlist(album.title, album.artist, tracks, color: AppColors.musikViolet),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not load album: $e')),
        );
      }
    }
  }

  String _greeting(String? name) {
    final hour = DateTime.now().hour;
    final time = hour < 12 ? 'Good morning' : hour < 17 ? 'Good afternoon' : 'Good evening';
    final who = (name != null && name.isNotEmpty) ? ', ${name.split(' ').first}' : '';
    return '$time$who';
  }

  @override
  Widget build(BuildContext context) {
    final deezer = context.watch<DeezerApiService>();
    final player = context.watch<AudioPlayerService>();
    final user = context.watch<AuthService>().user;
    final chart = deezer.chartTracks;
    final albums = deezer.chartAlbums;
    final forYou = deezer.forYouTracks;
    final recent = player.playHistory;

    final initialLoading = deezer.loading && chart.isEmpty;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: initialLoading
            ? const Center(child: CircularProgressIndicator(color: AppColors.musikAccent))
            : RefreshIndicator(
                onRefresh: _refresh,
                color: AppColors.musikAccent,
                backgroundColor: AppColors.surfaceElevated,
                child: CustomScrollView(
                  slivers: [
                    SliverAppBar(
                      floating: true,
                      pinned: true,
                      backgroundColor: AppColors.background,
                      elevation: 0,
                      leading: const Padding(
                        padding: EdgeInsets.all(10),
                        child: MusikAppIcon(size: 36),
                      ),
                      leadingWidth: 56,
                      title: Text(
                        _greeting(user?.name),
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
                      ),
                      actions: [
                        IconButton(
                          icon: const Icon(Icons.search),
                          onPressed: () => context.read<AppNavigationService>().openSearchTab(),
                        ),
                        IconButton(icon: const Icon(Icons.settings_outlined), onPressed: _openSettings),
                        const SizedBox(width: 4),
                      ],
                    ),
                    if (deezer.error != null && chart.isEmpty)
                      SliverToBoxAdapter(
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: _ErrorBanner(
                            message: 'Could not load music catalog',
                            onRetry: _loadCatalog,
                          ),
                        ),
                      ),
                    if (chart.isNotEmpty)
                      SliverToBoxAdapter(
                        child: _HeroTrackCard(
                          track: chart.first,
                          onPlay: () => player.playTrack(chart.first, queue: chart, index: 0),
                        ),
                      ),
                    if (recent.isNotEmpty) ...[
                      const _SectionTitle('Recently played'),
                      SliverToBoxAdapter(
                        child: SizedBox(
                          height: 200,
                          child: ListView.builder(
                            scrollDirection: Axis.horizontal,
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            itemCount: recent.length,
                            itemBuilder: (_, i) {
                              final track = recent[i];
                              return _ChartTrackCard(
                                track: track,
                                onTap: () => player.playTrack(track, queue: recent, index: i),
                              );
                            },
                          ),
                        ),
                      ),
                    ],
                    if (chart.isNotEmpty) ...[
                      const _SectionTitle('Top tracks'),
                      SliverToBoxAdapter(
                        child: SizedBox(
                          height: 200,
                          child: ListView.builder(
                            scrollDirection: Axis.horizontal,
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            itemCount: chart.length,
                            itemBuilder: (_, i) {
                              final track = chart[i];
                              return _ChartTrackCard(
                                track: track,
                                onTap: () => player.playTrack(track, queue: chart, index: i),
                                onLongPress: () => AppRoutes.album(
                                  context,
                                  album: AlbumBuilder.fromTrack(track, chart),
                                ),
                              );
                            },
                          ),
                        ),
                      ),
                    ],
                    if (albums.isNotEmpty) ...[
                      const _SectionTitle('Trending albums'),
                      SliverToBoxAdapter(
                        child: SizedBox(
                          height: 200,
                          child: ListView.builder(
                            scrollDirection: Axis.horizontal,
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            itemCount: albums.length,
                            itemBuilder: (_, i) {
                              final album = albums[i];
                              return _AlbumCard(
                                album: album,
                                onTap: () => _openCatalogAlbum(album),
                              );
                            },
                          ),
                        ),
                      ),
                    ],
                    if (forYou.isNotEmpty) ...[
                      const _SectionTitle('Based on your artists'),
                      SliverToBoxAdapter(
                        child: SizedBox(
                          height: 200,
                          child: ListView.builder(
                            scrollDirection: Axis.horizontal,
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            itemCount: forYou.length,
                            itemBuilder: (_, i) {
                              final track = forYou[i];
                              return _ChartTrackCard(
                                track: track,
                                onTap: () => player.playTrack(track, queue: forYou, index: i),
                              );
                            },
                          ),
                        ),
                      ),
                    ],
                    const _SectionTitle('Quick access'),
                    SliverToBoxAdapter(
                      child: SizedBox(
                        height: 88,
                        child: ListView(
                          scrollDirection: Axis.horizontal,
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          children: [
                            if (chart.isNotEmpty)
                              _QuickChip(
                                label: 'Play chart',
                                color: AppColors.musikAccent,
                                icon: Icons.play_arrow,
                                onTap: () => player.playTrack(chart.first, queue: chart, index: 0),
                              ),
                            _QuickChip(
                              label: 'USB music',
                              color: AppColors.musikSecondary,
                              icon: Icons.usb,
                              onTap: () => AppRoutes.usb(context),
                            ),
                            _QuickChip(
                              label: 'Search',
                              color: AppColors.musikViolet,
                              icon: Icons.search,
                              onTap: () => context.read<AppNavigationService>().openSearchTab(),
                            ),
                            if (_localTracks.isNotEmpty)
                              _QuickChip(
                                label: 'Your files',
                                color: const Color(0xFF477D95),
                                icon: Icons.audio_file,
                                onTap: () {
                                  player.playTrack(_localTracks.first, queue: _localTracks, index: 0);
                                },
                              ),
                          ],
                        ),
                      ),
                    ),
                    if (_localTracks.isNotEmpty) ...[
                      const _SectionTitle('On this device'),
                      SliverList(
                        delegate: SliverChildBuilderDelegate(
                          (context, i) {
                            final track = _localTracks[i];
                            final playing = player.currentTrack?.id == track.id && player.isPlaying;
                            return ListTile(
                              leading: TrackCover(track: track, size: 48, borderRadius: 6),
                              title: Text(track.title, maxLines: 1, overflow: TextOverflow.ellipsis),
                              subtitle: Text(track.artist),
                              trailing: Icon(
                                playing ? Icons.equalizer : Icons.play_circle_outline,
                                color: AppColors.musikAccent,
                              ),
                              onTap: () => player.playTrack(track, queue: _localTracks, index: i),
                            );
                          },
                          childCount: _localTracks.length.clamp(0, 10),
                        ),
                      ),
                    ] else if (!_loadingLocal) ...[
                      const _SectionTitle('On this device'),
                      SliverToBoxAdapter(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: OutlinedButton.icon(
                            onPressed: () => AppRoutes.usb(context),
                            icon: const Icon(Icons.usb),
                            label: const Text('Import music from USB or storage'),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: AppColors.musikAccent,
                              side: const BorderSide(color: AppColors.musikAccent),
                              padding: const EdgeInsets.symmetric(vertical: 14),
                            ),
                          ),
                        ),
                      ),
                    ],
                    const SliverPadding(padding: EdgeInsets.only(bottom: 120)),
                  ],
                ),
              ),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String title;

  const _SectionTitle(this.title);

  @override
  Widget build(BuildContext context) {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 24, 16, 12),
        child: Text(title, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w700)),
      ),
    );
  }
}

class _HeroTrackCard extends StatelessWidget {
  final Track track;
  final VoidCallback onPlay;

  const _HeroTrackCard({required this.track, required this.onPlay});

  @override
  Widget build(BuildContext context) {
    final cover = track.coverUrl;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      child: GestureDetector(
        onTap: onPlay,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(14),
          child: SizedBox(
            height: 180,
            child: Stack(
              fit: StackFit.expand,
              children: [
                if (cover != null && cover.isNotEmpty)
                  Image.network(cover, fit: BoxFit.cover)
                else
                  Container(color: AppColors.musikViolet),
                Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [Colors.transparent, Colors.black.withValues(alpha: 0.85)],
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppColors.musikAccent,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Text(
                          '#1 RIGHT NOW',
                          style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: Colors.black),
                        ),
                      ),
                      const Spacer(),
                      Text(
                        track.title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w900),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        track.artist,
                        style: const TextStyle(fontSize: 15, color: AppColors.textSecondary),
                      ),
                      const SizedBox(height: 12),
                      FilledButton.icon(
                        onPressed: onPlay,
                        icon: const Icon(Icons.play_arrow, size: 22),
                        label: const Text('Play full song'),
                        style: FilledButton.styleFrom(
                          backgroundColor: AppColors.musikAccent,
                          foregroundColor: Colors.black,
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _QuickChip extends StatelessWidget {
  final String label;
  final Color color;
  final IconData icon;
  final VoidCallback onTap;

  const _QuickChip({
    required this.label,
    required this.color,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: Material(
        color: AppColors.surfaceElevated,
        borderRadius: BorderRadius.circular(8),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(8),
          child: SizedBox(
            width: 150,
            child: Row(
              children: [
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: color,
                    borderRadius: const BorderRadius.horizontal(left: Radius.circular(8)),
                  ),
                  child: Icon(icon, color: Colors.white),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    label,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ChartTrackCard extends StatelessWidget {
  final Track track;
  final VoidCallback onTap;
  final VoidCallback? onLongPress;

  const _ChartTrackCard({required this.track, required this.onTap, this.onLongPress});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 12),
      child: GestureDetector(
        onTap: onTap,
        onLongPress: onLongPress,
        child: SizedBox(
          width: 140,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: TrackCover(track: track, size: 140, borderRadius: 8)),
              const SizedBox(height: 8),
              Text(track.title, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
              Text(track.artist, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
            ],
          ),
        ),
      ),
    );
  }
}

class _AlbumCard extends StatelessWidget {
  final CatalogAlbum album;
  final VoidCallback onTap;

  const _AlbumCard({required this.album, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 12),
      child: GestureDetector(
        onTap: onTap,
        child: SizedBox(
          width: 140,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: album.coverUrl.isNotEmpty
                      ? Image.network(album.coverUrl, width: 140, fit: BoxFit.cover)
                      : Container(color: AppColors.surfaceElevated),
                ),
              ),
              const SizedBox(height: 8),
              Text(album.title, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
              Text(album.artist, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
            ],
          ),
        ),
      ),
    );
  }
}

class _ErrorBanner extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _ErrorBanner({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surfaceElevated,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.musikSecondary.withValues(alpha: 0.5)),
      ),
      child: Row(
        children: [
          const Icon(Icons.wifi_off, color: AppColors.musikSecondary),
          const SizedBox(width: 12),
          Expanded(child: Text(message, style: const TextStyle(fontSize: 13))),
          TextButton(onPressed: onRetry, child: const Text('Retry')),
        ],
      ),
    );
  }
}
