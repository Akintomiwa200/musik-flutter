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
import 'services/lyrics_service.dart';
import 'services/preferences_service.dart';
import 'services/stream_resolver_service.dart';
import 'theme/app_theme.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  if (!kIsWeb && Platform.isWindows) {
    JustAudioMediaKit.ensureInitialized(windows: true, linux: false);
  }
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
      systemNavigationBarColor: AppColors.surface,
      systemNavigationBarIconBrightness: Brightness.light,
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
        ChangeNotifierProvider(
          create: (ctx) => AudioPlayerService.create(ctx.read<StreamResolverService>()),
        ),
        ChangeNotifierProvider(create: (_) => AuthService()),
        ChangeNotifierProvider(create: (_) => PreferencesService()),
        ChangeNotifierProvider(create: (_) => DeviceService()),
        ChangeNotifierProvider(create: (_) => AppNavigationService()),
        ChangeNotifierProvider(create: (_) => DeezerApiService()),
        ChangeNotifierProvider(create: (_) => LyricsService()),
      ],
      child: MaterialApp(
        title: 'Musik',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.darkTheme,
        home: const AuthGate(),
      ),
    );
  }
}
