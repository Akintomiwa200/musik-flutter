import 'package:flutter/material.dart';

import '../../theme/app_theme.dart';
import '../../widgets/onboarding/album_collage.dart';
import '../../widgets/musik_logo.dart';
import '../../widgets/onboarding/onboarding_button.dart';
import 'login_screen.dart';
import 'signup_flow_screen.dart';

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  void _showSocialSnack(BuildContext context, String provider) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Use email sign up for now — $provider login is not enabled yet.'),
        backgroundColor: AppColors.surfaceElevated,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: constraints.maxHeight),
                child: IntrinsicHeight(
                  child: Column(
                    children: [
                      const SizedBox(height: 8),
                      const SizedBox(height: 180, child: AlbumCollage()),
                      const SizedBox(height: 8),
                      const MusikLogo(size: 72),
                      const Spacer(),
              const Text(
                'Your music.\nYour way.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w900,
                  height: 1.15,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 32),
              OnboardingPrimaryButton(
                label: 'Sign up free',
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const SignupFlowScreen()),
                  );
                },
              ),
              const SizedBox(height: 12),
              OnboardingOutlineButton(
                label: 'Continue with Google',
                icon: Icons.g_mobiledata,
                onPressed: () => _showSocialSnack(context, 'Google'),
              ),
              const SizedBox(height: 12),
              OnboardingOutlineButton(
                label: 'Continue with Facebook',
                icon: Icons.facebook,
                onPressed: () => _showSocialSnack(context, 'Facebook'),
              ),
              const SizedBox(height: 12),
              OnboardingOutlineButton(
                label: 'Continue with Apple',
                icon: Icons.apple,
                onPressed: () => _showSocialSnack(context, 'Apple'),
              ),
              const SizedBox(height: 20),
              TextButton(
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const LoginScreen()),
                  );
                },
                child: const Text(
                  'Log in',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
                      const SizedBox(height: 8),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
