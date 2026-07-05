import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../services/auth_service.dart';
import '../../services/preferences_service.dart';
import '../main_shell.dart';
import 'login_screen.dart';
import 'splash_screen.dart';
import 'welcome_screen.dart';

class AuthGate extends StatefulWidget {
  const AuthGate({super.key});

  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  bool _ready = false;
  bool _splashDone = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final auth = context.read<AuthService>();
    final prefs = context.read<PreferencesService>();
    await Future.wait([
      auth.loadSession(),
      prefs.load(),
      Future<void>.delayed(const Duration(milliseconds: 1400)),
    ]);
    if (mounted) setState(() => _ready = true);
  }

  @override
  Widget build(BuildContext context) {
    if (!_ready || !_splashDone) {
      return SplashScreen(onFinished: () => setState(() => _splashDone = true));
    }

    final auth = context.watch<AuthService>();
    if (!auth.isLoggedIn) {
      return auth.onboardingSeen ? const LoginScreen() : const WelcomeScreen();
    }

    return const MainShell();
  }
}
