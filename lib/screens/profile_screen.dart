import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../navigation/app_routes.dart';
import '../services/auth_service.dart';
import '../services/deezer_api_service.dart';
import '../theme/app_theme.dart';
import 'playlist_screen.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthService>().user;
    final chart = context.watch<DeezerApiService>().chartTracks;
    final name = user?.name ?? 'Musik User';

    final playlists = [
      ('My Favorites', chart.take(8).toList(), AppColors.musikViolet),
      ('Top Chart', chart, AppColors.musikAccent),
      ('Fresh Drops', chart.length > 5 ? chart.sublist(5) : chart, AppColors.musikSecondary),
    ];

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF0D3D4A), Color(0xFF0A0A0F)],
            stops: [0.0, 0.42],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back),
                      onPressed: () => Navigator.pop(context),
                    ),
                    const Spacer(),
                    IconButton(
                      icon: const Icon(Icons.settings_outlined),
                      onPressed: () => AppRoutes.settings(context),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              CircleAvatar(
                radius: 48,
                backgroundColor: AppColors.musikAccent,
                child: Text(
                  name.isNotEmpty ? name[0].toUpperCase() : '?',
                  style: const TextStyle(fontSize: 36, fontWeight: FontWeight.w700, color: Colors.black),
                ),
              ),
              const SizedBox(height: 16),
              Text(name, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w700)),
              const SizedBox(height: 8),
              Text(user?.email ?? '', style: const TextStyle(color: AppColors.textSecondary, fontSize: 13)),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _StatColumn(value: '${playlists.length}', label: 'Playlists'),
                  _StatColumn(value: '${chart.length}', label: 'Tracks'),
                  const _StatColumn(value: 'Musik', label: 'Member'),
                ],
              ),
              const SizedBox(height: 24),
              const Align(
                alignment: Alignment.centerLeft,
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: 20),
                  child: Text('Your playlists', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
                ),
              ),
              const SizedBox(height: 8),
              Expanded(
                child: chart.isEmpty
                    ? const Center(child: CircularProgressIndicator(color: AppColors.musikAccent))
                    : ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        itemCount: playlists.length,
                        itemBuilder: (_, i) {
                          final (title, tracks, color) = playlists[i];
                          return ListTile(
                            leading: Container(
                              width: 48,
                              height: 48,
                              decoration: BoxDecoration(
                                color: color,
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: const Icon(Icons.queue_music, color: Colors.white70),
                            ),
                            title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
                            subtitle: Text('${tracks.length} songs', style: const TextStyle(color: AppColors.textSecondary)),
                            trailing: const Icon(Icons.chevron_right, color: AppColors.textSecondary),
                            onTap: () {
                              if (tracks.isEmpty) return;
                              Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (_) => PlaylistScreen(
                                    title: title,
                                    subtitle: 'Playlist • $name',
                                    gradientTop: color,
                                    gradientBottom: AppColors.background,
                                    tracks: tracks,
                                  ),
                                ),
                              );
                            },
                          );
                        },
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatColumn extends StatelessWidget {
  final String value;
  final String label;

  const _StatColumn({required this.value, required this.label});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(value, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
        const SizedBox(height: 4),
        Text(label, style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
      ],
    );
  }
}
