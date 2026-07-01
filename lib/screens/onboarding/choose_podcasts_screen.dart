import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../data/sample_content.dart';
import '../../services/preferences_service.dart';
import '../../theme/app_theme.dart';
import '../main_shell.dart';

class ChoosePodcastsScreen extends StatelessWidget {
  const ChoosePodcastsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final prefs = context.watch<PreferencesService>();
    final selected = prefs.selectedPodcasts;

    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 16),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 24),
              child: Text(
                'Now choose some podcasts.',
                style: TextStyle(fontSize: 28, fontWeight: FontWeight.w700, height: 1.15),
              ),
            ),
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: TextField(
                readOnly: true,
                decoration: InputDecoration(
                  hintText: 'Search',
                  hintStyle: const TextStyle(color: Color(0xFFB3B3B3)),
                  prefixIcon: const Icon(Icons.search, color: Color(0xFFB3B3B3)),
                  filled: true,
                  fillColor: const Color(0xFF242424),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: GridView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  mainAxisSpacing: 16,
                  crossAxisSpacing: 16,
                  childAspectRatio: 0.85,
                ),
                itemCount: SampleContent.podcasts.length,
                itemBuilder: (context, i) {
                  final podcast = SampleContent.podcasts[i];
                  final isSelected = selected.contains(podcast.id);
                  return _PodcastTile(
                    podcast: podcast,
                    isSelected: isSelected,
                    onTap: () => prefs.togglePodcast(podcast.id),
                  );
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 8, 24, 20),
              child: SizedBox(
                width: double.infinity,
                height: 52,
                child: FilledButton(
                  onPressed: () async {
                    await prefs.completeTasteOnboarding();
                    if (!context.mounted) return;
                    Navigator.of(context).pushAndRemoveUntil(
                      MaterialPageRoute(builder: (_) => const MainShell()),
                      (_) => false,
                    );
                  },
                  style: FilledButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: Colors.black,
                    shape: const StadiumBorder(),
                    textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                  ),
                  child: const Text('Done'),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PodcastTile extends StatelessWidget {
  final PodcastItem podcast;
  final bool isSelected;
  final VoidCallback onTap;

  const _PodcastTile({
    required this.podcast,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    if (podcast.isCategory) {
      return GestureDetector(
        onTap: onTap,
        child: Container(
          decoration: BoxDecoration(
            color: podcast.color,
            borderRadius: BorderRadius.circular(8),
            border: isSelected ? Border.all(color: Colors.white, width: 2) : null,
          ),
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                podcast.title,
                style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
              ),
              const Spacer(),
              Align(
                alignment: Alignment.bottomRight,
                child: Icon(
                  isSelected ? Icons.check_circle : Icons.podcasts,
                  color: Colors.white.withValues(alpha: 0.8),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return GestureDetector(
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Container(
              width: double.infinity,
              decoration: BoxDecoration(
                color: podcast.color,
                borderRadius: BorderRadius.circular(6),
                border: isSelected ? Border.all(color: AppColors.musikAccent, width: 2) : null,
              ),
              child: Stack(
                children: [
                  Center(
                    child: Icon(Icons.podcasts, size: 40, color: Colors.white.withValues(alpha: 0.7)),
                  ),
                  if (isSelected)
                    const Positioned(
                      top: 8,
                      right: 8,
                      child: Icon(Icons.check_circle, color: AppColors.musikAccent, size: 22),
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            podcast.title,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}
