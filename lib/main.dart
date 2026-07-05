import 'dart:io' show Platform;

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:just_audio_media_kit/just_audio_media_kit.dart';
import 'package:provider/provider.dart';

import 'screens/onboarding/auth_gate.dart';
import 'services/app_navigation_service.dart';
import 'services/audio_player_service.dart';
import 'services/auth_service.dart';
import 'services/deezer_api_service.dart';
import 'services/device_service.dart';
import 'services/download_service.dart';
import 'services/library_service.dart';
import 'services/lyrics_service.dart';
import 'services/preferences_service.dart';
import 'services/recommendation_service.dart';
import 'services/stream_resolver_service.dart';
import 'services/theme_service.dart';
import 'theme/app_theme.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  if (!kIsWeb && Platform.isWindows) {
    JustAudioMediaKit.ensureInitialized(windows: true, linux: false);
  }
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
      statusBarBrightness: Brightness.light,
      systemNavigationBarColor: AppColors.surface,
      systemNavigationBarIconBrightness: Brightness.dark,
    ),
  );
  runApp(const MusikApp());
}

class MusikApp extends StatelessWidget {
  const MusikApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        Provider(create: (_) => StreamResolverService()),
        Provider(create: (_) => RecommendationService()),
        ChangeNotifierProvider(create: (ctx) => DownloadService(ctx.read<StreamResolverService>())..init()),
        ChangeNotifierProvider(
          create: (ctx) =>
              AudioPlayerService.create(ctx.read<StreamResolverService>(), ctx.read<DownloadService>()),
        ),
        ChangeNotifierProvider(create: (_) => AuthService()),
        ChangeNotifierProvider(create: (_) => PreferencesService()..load()),
        ChangeNotifierProvider(create: (_) => LibraryService()..load()),
        ChangeNotifierProvider(create: (_) => DeviceService()),
        ChangeNotifierProvider(create: (_) => AppNavigationService()),
        ChangeNotifierProvider(create: (_) => DeezerApiService()),
        ChangeNotifierProvider(create: (_) => LyricsService()),
        ChangeNotifierProvider(create: (_) => ThemeService()..load()),
      ],
      child: _CatalogSync(child: Consumer<ThemeService>(
        builder: (_, themeService, __) => MaterialApp(
          title: 'Musik',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.buildTheme(
            dark: themeService.isDarkMode,
            accent: themeService.accentColor,
          ),
          home: AuthGate(),
        ),
      )),
    );
  }
}

class _CatalogSync extends StatefulWidget {
  final Widget child;
  const _CatalogSync({required this.child});
  @override
  State<_CatalogSync> createState() => _CatalogSyncState();
}

class _CatalogSyncState extends State<_CatalogSync> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final library = context.read<LibraryService>();
      final deezer = context.read<DeezerApiService>();
      final player = context.read<AudioPlayerService>();
      _sync(player, library, deezer);
      library.addListener(() => _sync(player, library, deezer));
      deezer.addListener(() => _sync(player, library, deezer));
    });
  }

  void _sync(AudioPlayerService player, LibraryService library, DeezerApiService deezer) {
    final all = [
      ...library.visibleTracks(library.likedTracks),
      ...deezer.chartTracks,
    ];
    player.setCatalog(all.toSet().toList());
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
