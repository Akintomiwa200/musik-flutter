import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/catalog_album.dart';
import '../models/track.dart';
import '../navigation/app_routes.dart';
import '../services/app_navigation_service.dart';
import '../services/audio_player_service.dart';
import '../services/deezer_api_service.dart';
import '../services/library_service.dart';
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

  Future<void> _loadCatalog() async {
    final deezer = context.read<DeezerApiService>();
    final prefs = context.read<PreferencesService>();
    await deezer.fetchHomeCatalog();

    final artistNames = prefs.selectedArtists.toList();
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
        album: AlbumBuilder.playlist(album.title, album.artist, tracks,
            color: AppColors.musikViolet),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not load album: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final deezer = context.watch<DeezerApiService>();
    final player = context.watch<AudioPlayerService>();
    final library = context.watch<LibraryService>();
    final chart = library.visibleTracks(deezer.chartTracks);
    final albums = deezer.chartAlbums;
    final forYou = library.visibleTracks(deezer.forYouTracks);
    final recent = library.visibleTracks(player.playHistory);

    final initialLoading = deezer.loading && chart.isEmpty;

    return Scaffold(
      backgroundColor: context.background,
      body: SafeArea(
        child: initialLoading
            ? const Center(
                child: CircularProgressIndicator(color: AppColors.musikAccent))
            : RefreshIndicator(
                onRefresh: _refresh,
                color: AppColors.musikAccent,
                backgroundColor: context.surfaceElevated,
                child: CustomScrollView(
                  slivers: [
                    SliverAppBar(
                      floating: true,
                      pinned: true,
                      backgroundColor: context.background,
                      elevation: 0,
                      leading: const Padding(
                        padding: EdgeInsets.all(12),
                        child: MusikAppIcon(size: 36),
                      ),
                      leadingWidth: 56,
                      title: const Text(
                        'Music App',
                        style: TextStyle(
                            fontSize: 15, fontWeight: FontWeight.w800),
                      ),
                      actions: [
                        Padding(
                          padding: const EdgeInsets.only(right: 12),
                          child: DecoratedBox(
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border:
                                  Border.all(color: context.surfaceHighlight),
                            ),
                            child: IconButton(
                              icon: const Icon(Icons.search, size: 22),
                              onPressed: () => context
                                  .read<AppNavigationService>()
                                  .openSearchTab(),
                            ),
                          ),
                        ),
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
                          onPlay: () => player.playTrack(chart.first,
                              queue: chart, index: 0),
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
                                onTap: () => player.playTrack(track,
                                    queue: recent, index: i),
                              );
                            },
                          ),
                        ),
                      ),
                    ],
                    if (chart.isNotEmpty) ...[
                      const _SectionTitle('New Releases'),
                      SliverToBoxAdapter(
                        child: SizedBox(
                          height: 128,
                          child: ListView.builder(
                            scrollDirection: Axis.horizontal,
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            itemCount: chart.length,
                            itemBuilder: (_, i) {
                              final track = chart[i];
                              return _ChartTrackCard(
                                track: track,
                                onTap: () => player.playTrack(track,
                                    queue: chart, index: i),
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
                      const _SectionTitle('Artists'),
                      SliverToBoxAdapter(
                        child: SizedBox(
                          height: 128,
                          child: ListView.builder(
                            scrollDirection: Axis.horizontal,
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            itemCount: albums.length,
                            itemBuilder: (_, i) {
                              final album = albums[i];
                              return _ArtistCard(
                                album: album,
                                onTap: () => _openCatalogAlbum(album),
                              );
                            },
                          ),
                        ),
                      ),
                    ],
                    if (forYou.isNotEmpty) ...[
                      const _SectionTitle('Top Music'),
                      SliverToBoxAdapter(
                        child: SizedBox(
                          height: 128,
                          child: ListView.builder(
                            scrollDirection: Axis.horizontal,
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            itemCount: forYou.length,
                            itemBuilder: (_, i) {
                              final track = forYou[i];
                              return _ChartTrackCard(
                                track: track,
                                onTap: () => player.playTrack(track,
                                    queue: forYou, index: i),
                              );
                            },
                          ),
                        ),
                      ),
                    ],
                    const _SectionTitle('Your music'),
                    SliverToBoxAdapter(
                      child: SizedBox(
                        height: 88,
                        child: ListView(
                          scrollDirection: Axis.horizontal,
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          children: [
                            if (library.likedTracks.isNotEmpty)
                              _HomeActionChip(
                                label: 'Liked songs',
                                color: AppColors.musikViolet,
                                icon: Icons.favorite,
                                onTap: () => player.playTrack(
                                  library.likedTracks.first,
                                  queue: library.likedTracks,
                                  index: 0,
                                ),
                              ),
                            if (recent.isNotEmpty)
                              _HomeActionChip(
                                label: 'Recently played',
                                color: AppColors.musikAccent,
                                icon: Icons.history,
                                onTap: () => player.playTrack(recent.first,
                                    queue: recent, index: 0),
                              ),
                            if (_localTracks.isNotEmpty)
                              _HomeActionChip(
                                label: 'Local files',
                                color: const Color(0xFF477D95),
                                icon: Icons.audio_file,
                                onTap: () {
                                  player.playTrack(_localTracks.first,
                                      queue: _localTracks, index: 0);
                                },
                              ),
                            _HomeActionChip(
                              label: 'USB library',
                              color: AppColors.musikSecondary,
                              icon: Icons.usb,
                              onTap: () => AppRoutes.usb(context),
                            ),
                            _HomeActionChip(
                              label: 'Find music',
                              color: context.surfaceHighlight,
                              icon: Icons.search,
                              onTap: () => context
                                  .read<AppNavigationService>()
                                  .openSearchTab(),
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
                            final playing =
                                player.currentTrack?.id == track.id &&
                                    player.isPlaying;
                            return ListTile(
                              leading: TrackCover(
                                  track: track, size: 48, borderRadius: 6),
                              title: Text(track.title,
                                  maxLines: 1, overflow: TextOverflow.ellipsis),
                              subtitle: Text(track.artist),
                              trailing: Icon(
                                playing
                                    ? Icons.equalizer
                                    : Icons.play_circle_outline,
                                color: AppColors.musikAccent,
                              ),
                              onTap: () => player.playTrack(track,
                                  queue: _localTracks, index: i),
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
                            label:
                                const Text('Import music from USB or storage'),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: AppColors.musikAccent,
                              side: const BorderSide(
                                  color: AppColors.musikAccent),
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
        padding: const EdgeInsets.fromLTRB(16, 18, 16, 10),
        child: Row(
          children: [
            Text(title,
                style:
                    const TextStyle(fontSize: 17, fontWeight: FontWeight.w800)),
            const Spacer(),
            const Text(
              'See All',
              style: TextStyle(
                fontSize: 12,
                color: AppColors.musikAccent,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
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
            height: 100,
            child: Stack(
              fit: StackFit.expand,
              children: [
                Container(
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.centerLeft,
                      end: Alignment.centerRight,
                      colors: [
                        AppColors.musikAccent,
                        AppColors.musikViolet,
                      ],
                    ),
                  ),
                ),
                Positioned.fill(
                  child: CustomPaint(painter: _WaveformBackdropPainter()),
                ),
                Positioned(
                  right: 0,
                  bottom: 0,
                  top: 0,
                  width: 124,
                  child: cover != null && cover.isNotEmpty
                      ? Image.network(
                          cover,
                          fit: BoxFit.cover,
                          color: Colors.white.withValues(alpha: 0.25),
                          colorBlendMode: BlendMode.screen,
                        )
                      : Icon(Icons.headphones,
                          size: 84,
                          color: Colors.white.withValues(alpha: 0.28)),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(14, 12, 120, 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'TRY FREE TRIAL',
                        style: TextStyle(
                          fontSize: 10,
                          color: Colors.white70,
                          letterSpacing: 1.6,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        '30-Day Free Trial\nOnly For You!',
                        maxLines: 2,
                        style: TextStyle(
                            fontSize: 16,
                            height: 1.05,
                            color: Colors.white,
                            fontWeight: FontWeight.w900),
                      ),
                      const Spacer(),
                      FilledButton(
                        onPressed: onPlay,
                        style: FilledButton.styleFrom(
                          backgroundColor: AppColors.musikLime,
                          foregroundColor: context.textPrimary,
                          minimumSize: const Size(74, 24),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 0),
                          textStyle: const TextStyle(
                              fontSize: 10, fontWeight: FontWeight.w900),
                        ),
                        child: const Text('Play Now'),
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

class _HomeActionChip extends StatelessWidget {
  final String label;
  final Color color;
  final IconData icon;
  final VoidCallback onTap;

  const _HomeActionChip({
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
        color: context.surfaceElevated,
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
                    borderRadius:
                        const BorderRadius.horizontal(left: Radius.circular(8)),
                  ),
                  child: Icon(icon, color: Colors.white),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    label,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                        fontSize: 12, fontWeight: FontWeight.w600),
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

  const _ChartTrackCard(
      {required this.track, required this.onTap, this.onLongPress});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 12),
      child: GestureDetector(
        onTap: onTap,
        onLongPress: onLongPress,
        child: SizedBox(
          width: 82,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Stack(
                alignment: Alignment.center,
                children: [
                  TrackCover(track: track, size: 82, borderRadius: 8),
                  Container(
                    width: 26,
                    height: 26,
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.34),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.play_arrow,
                        color: Colors.white, size: 18),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Text(track.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                      fontSize: 11, fontWeight: FontWeight.w800)),
              Text(track.artist,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                      fontSize: 10, color: context.textSecondary)),
            ],
          ),
        ),
      ),
    );
  }
}

class _ArtistCard extends StatelessWidget {
  final CatalogAlbum album;
  final VoidCallback onTap;

  const _ArtistCard({required this.album, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 16),
      child: GestureDetector(
        onTap: onTap,
        child: SizedBox(
          width: 82,
          child: Column(
            children: [
              ClipOval(
                child: album.coverUrl.isNotEmpty
                    ? Image.network(album.coverUrl,
                        width: 82, height: 82, fit: BoxFit.cover)
                    : Container(
                        width: 82,
                        height: 82,
                        color: context.surfaceElevated),
              ),
              const SizedBox(height: 8),
              Text(
                album.artist,
                maxLines: 1,
                textAlign: TextAlign.center,
                overflow: TextOverflow.ellipsis,
                style:
                    const TextStyle(fontSize: 11, fontWeight: FontWeight.w800),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _WaveformBackdropPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withValues(alpha: 0.45)
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round;
    final startX = size.width * 0.58;
    for (var i = 0; i < 24; i++) {
      final x = startX + i * 4.4;
      final h = 10 + ((i * 7) % 28).toDouble();
      canvas.drawLine(Offset(x, (size.height - h) / 2),
          Offset(x, (size.height + h) / 2), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
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
        color: context.surfaceElevated,
        borderRadius: BorderRadius.circular(10),
        border:
            Border.all(color: AppColors.musikSecondary.withValues(alpha: 0.5)),
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


