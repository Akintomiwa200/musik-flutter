import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../services/auth_service.dart';
import '../../theme/app_theme.dart';
import 'login_screen.dart';

class WelcomeScreen extends StatefulWidget {
  const WelcomeScreen({super.key});

  @override
  State<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen> {
  final _controller = PageController();
  int _page = 0;

  static const _slides = [
    _OnboardingSlideData(
      title: 'Music for your\nwellbeing',
      highlighted: 'wellbeing',
      body:
          'Listen to music that fits your mood, calms your day, and keeps your rhythm close.',
      assetSeed: 0,
    ),
    _OnboardingSlideData(
      title: 'Rhythms based on\nyour needs',
      highlighted: 'needs',
      body:
          'Discover playlists and artists shaped around how you feel and what you want to hear.',
      assetSeed: 1,
    ),
    _OnboardingSlideData(
      title: 'Playlist to boost\nyour energy',
      highlighted: 'energy',
      body:
          'Build your library, stream your favorites, and keep every beat ready when you need it.',
      assetSeed: 2,
    ),
  ];

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _continue() async {
    if (_page < _slides.length - 1) {
      await _controller.nextPage(
        duration: const Duration(milliseconds: 280),
        curve: Curves.easeOut,
      );
      return;
    }
    await context.read<AuthService>().completeOnboarding();
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const LoginScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: PageView.builder(
                controller: _controller,
                itemCount: _slides.length,
                onPageChanged: (value) => setState(() => _page = value),
                itemBuilder: (context, index) => _OnboardingSlide(
                  data: _slides[index],
                  onNext: _continue,
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(28, 0, 28, 24),
              child: Row(
                children: [
                  for (var i = 0; i < _slides.length; i++)
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 180),
                      width: i == _page ? 18 : 6,
                      height: 6,
                      margin: const EdgeInsets.only(right: 6),
                      decoration: BoxDecoration(
                        color: i == _page
                            ? AppColors.musikAccent
                            : context.surfaceHighlight,
                        borderRadius: BorderRadius.circular(999),
                      ),
                    ),
                  const Spacer(),
                  TextButton(
                    onPressed: () async {
                      await context.read<AuthService>().completeOnboarding();
                      if (!context.mounted) return;
                      Navigator.of(context).pushReplacement(
                        MaterialPageRoute(builder: (_) => const LoginScreen()),
                      );
                    },
                    child: const Text('Skip'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _OnboardingSlide extends StatelessWidget {
  final _OnboardingSlideData data;
  final VoidCallback onNext;

  const _OnboardingSlide({required this.data, required this.onNext});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(28, 22, 28, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          RichText(
            text: TextSpan(
              style: TextStyle(
                color: context.textPrimary,
                fontSize: 25,
                height: 1.06,
                fontWeight: FontWeight.w900,
              ),
              children: _titleSpans(data.title, data.highlighted),
            ),
          ),
          const SizedBox(height: 10),
          Text(
            data.body,
            style: TextStyle(
              color: context.textSecondary,
              fontSize: 12,
              height: 1.4,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: 42,
            height: 42,
            child: FilledButton(
              onPressed: onNext,
              style: FilledButton.styleFrom(
                padding: EdgeInsets.zero,
                backgroundColor: AppColors.musikAccent,
                shape: const CircleBorder(),
              ),
              child: const Icon(Icons.arrow_forward, color: Colors.white),
            ),
          ),
          const Spacer(),
          Center(child: _OnboardingPerson(seed: data.assetSeed)),
        ],
      ),
    );
  }

  List<TextSpan> _titleSpans(String title, String highlighted) {
    final index = title.indexOf(highlighted);
    if (index < 0) return [TextSpan(text: title)];
    return [
      TextSpan(text: title.substring(0, index)),
      TextSpan(
        text: highlighted,
        style: const TextStyle(color: AppColors.musikAccent),
      ),
      TextSpan(text: title.substring(index + highlighted.length)),
    ];
  }
}

class _OnboardingPerson extends StatelessWidget {
  final int seed;

  const _OnboardingPerson({required this.seed});

  @override
  Widget build(BuildContext context) {
    final sweater = [
      const Color(0xFFF7E4D6),
      const Color(0xFFFFE6D4),
      const Color(0xFF7FE7DD),
    ][seed];
    return SizedBox(
      height: 360,
      child: Stack(
        alignment: Alignment.bottomCenter,
        children: [
          Container(
            width: 178,
            height: 178,
            margin: const EdgeInsets.only(bottom: 118),
            decoration: BoxDecoration(
              color: context.surfaceElevated,
              shape: BoxShape.circle,
            ),
          ),
          Positioned(
            bottom: 0,
            child: Container(
              width: 190,
              height: 210,
              decoration: BoxDecoration(
                color: sweater,
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(88)),
              ),
            ),
          ),
          Positioned(
            bottom: 190,
            child: Container(
              width: 112,
              height: 112,
              decoration: const BoxDecoration(
                color: Color(0xFFFFC49B),
                shape: BoxShape.circle,
              ),
              child: Icon(
                seed == 2 ? Icons.record_voice_over : Icons.sentiment_satisfied,
                size: 52,
                color: Colors.white,
              ),
            ),
          ),
          Positioned(
            bottom: 226,
            left: 78,
            child: Container(
              width: 34,
              height: 74,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppColors.musikAccent, width: 4),
              ),
            ),
          ),
          Positioned(
            bottom: 226,
            right: 78,
            child: Container(
              width: 34,
              height: 74,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppColors.musikAccent, width: 4),
              ),
            ),
          ),
          Positioned(
            bottom: 74,
            child: Container(
              width: 70,
              height: 120,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: context.surfaceHighlight, width: 2),
              ),
              child: Icon(
                seed == 0 ? Icons.music_note : Icons.mic,
                color: AppColors.musikAccent,
                size: 32,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _OnboardingSlideData {
  final String title;
  final String highlighted;
  final String body;
  final int assetSeed;

  const _OnboardingSlideData({
    required this.title,
    required this.highlighted,
    required this.body,
    required this.assetSeed,
  });
}


