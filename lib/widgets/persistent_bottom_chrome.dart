import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../navigation/app_routes.dart';
import '../services/audio_player_service.dart';
import '../services/device_service.dart';
import '../theme/app_theme.dart';
import 'mini_player_bar.dart';
import 'sheets/device_picker_sheet.dart';

class PersistentBottomChrome extends StatelessWidget {
  final int selectedIndex;
  final ValueChanged<int> onTabSelected;

  const PersistentBottomChrome({
    super.key,
    required this.selectedIndex,
    required this.onTabSelected,
  });

  void _openNowPlaying(BuildContext context) {
    AppRoutes.nowPlaying(context);
  }

  @override
  Widget build(BuildContext context) {
    final player = context.watch<AudioPlayerService>();
    final device = context.watch<DeviceService>();
    final hasTrack = player.currentTrack != null;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (hasTrack)
          StreamBuilder<Duration>(
            stream: player.positionStream,
            builder: (context, snap) {
              final pos = snap.data ?? player.position;
              final dur = player.duration;
              final progress = dur != null && dur.inMilliseconds > 0
                  ? pos.inMilliseconds / dur.inMilliseconds
                  : 0.0;
              return MiniPlayerBar(
                title: player.currentTrack!.title,
                artist: player.currentTrack!.artist,
                track: player.currentTrack,
                deviceLabel: device.activeDeviceLabel,
                isPlaying: player.isPlaying,
                isLoading: player.isResolving ||
                    player.state == PlaybackStatus.loading,
                progress: progress,
                onTap: () => _openNowPlaying(context),
                onPlayPause: player.togglePlayPause,
                onCast: () => showDevicePickerSheet(context),
              );
            },
          ),
        NavigationBar(
          selectedIndex: selectedIndex,
          onDestinationSelected: onTabSelected,
          backgroundColor: context.surface,
          indicatorColor: AppColors.musikAccent.withValues(alpha: 0.12),
          height: 64,
          labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
          destinations: [
            NavigationDestination(
              icon: Icon(Icons.home_outlined),
              selectedIcon: Icon(Icons.home),
              label: 'Home',
            ),
            NavigationDestination(
              icon: Icon(Icons.explore_outlined),
              selectedIcon: Icon(Icons.explore),
              label: 'Discover',
            ),
            NavigationDestination(
              icon: Icon(Icons.cloud_download_outlined),
              selectedIcon: Icon(Icons.cloud_download),
              label: 'Download',
            ),
            NavigationDestination(
              icon: Icon(Icons.queue_music_outlined),
              selectedIcon: Icon(Icons.queue_music),
              label: 'Playlist',
            ),
            NavigationDestination(
              icon: Icon(Icons.person_outline_rounded),
              selectedIcon: Icon(Icons.person),
              label: 'Profile',
            ),
          ],
        ),
      ],
    );
  }
}

/// Wraps a screen with mini-player + bottom nav (used by Settings).
class ChromeScaffold extends StatelessWidget {
  final Widget body;
  final PreferredSizeWidget? appBar;
  final int selectedTab;

  const ChromeScaffold({
    super.key,
    required this.body,
    this.appBar,
    this.selectedTab = 0,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: appBar,
      body: body,
      bottomNavigationBar: PersistentBottomChrome(
        selectedIndex: selectedTab,
        onTabSelected: (i) => Navigator.of(context).pop(i),
      ),
    );
  }
}


