import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../services/preferences_service.dart';
import '../../theme/app_theme.dart';
import '../main_shell.dart';

class ChoosePodcastsScreen extends StatelessWidget {
  const ChoosePodcastsScreen({super.key});

  Future<void> _finish(BuildContext context) async {
    await context.read<PreferencesService>().completeTasteOnboarding();
    if (!context.mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const MainShell()),
      (_) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 24, 24, 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Podcasts are coming soon.',
                style: TextStyle(fontSize: 28, fontWeight: FontWeight.w700, height: 1.15),
              ),
              const SizedBox(height: 12),
              Text(
                'Musik is focused on songs, artists, albums, local files, and USB playback right now.',
                style: TextStyle(color: context.textSecondary, fontSize: 15, height: 1.4),
              ),
              const Spacer(),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: FilledButton(
                  onPressed: () => _finish(context),
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.musikAccent,
                    foregroundColor: Colors.black,
                    shape: const StadiumBorder(),
                    textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                  ),
                  child: const Text('Continue to Musik'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}


