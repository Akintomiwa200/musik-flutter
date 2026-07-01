import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../services/auth_service.dart';
import '../../services/preferences_service.dart';
import '../../theme/app_theme.dart';
import '../main_shell.dart';
import 'choose_artists_screen.dart';
import 'welcome_screen.dart';

class AuthGate extends StatefulWidget {
  const AuthGate({super.key});

  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  bool _ready = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    await context.read<AuthService>().loadSession();
    await context.read<PreferencesService>().load();
    if (mounted) setState(() => _ready = true);
  }

  @override
  Widget build(BuildContext context) {
    if (!_ready) {
      return const Scaffold(
        backgroundColor: Colors.black,
        body: Center(
          child: CircularProgressIndicator(color: AppColors.musikAccent),
        ),
      );
    }

    final auth = context.watch<AuthService>();
    if (!auth.isLoggedIn) return const WelcomeScreen();

    final prefs = context.watch<PreferencesService>();
    if (!prefs.tasteOnboardingComplete) return const ChooseArtistsScreen();

    return const MainShell();
  }
}
