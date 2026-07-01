import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/user_profile.dart';
import '../../services/auth_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/onboarding/onboarding_button.dart';
import '../../widgets/onboarding/signup_text_field.dart';
import 'choose_artists_screen.dart';

class SignupFlowScreen extends StatefulWidget {
  const SignupFlowScreen({super.key});

  @override
  State<SignupFlowScreen> createState() => _SignupFlowScreenState();
}

class _SignupFlowScreenState extends State<SignupFlowScreen> {
  int _step = 0;
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _nameController = TextEditingController();
  final _genderController = TextEditingController();
  String _gender = '';
  bool _marketingNews = false;
  bool _marketingShare = false;

  bool get _emailValid {
    final e = _emailController.text.trim();
    return e.contains('@') && e.contains('.');
  }

  bool get _passwordValid => _passwordController.text.length >= 8;
  bool get _genderValid => _gender.isNotEmpty;
  bool get _nameValid => _nameController.text.trim().isNotEmpty;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _nameController.dispose();
    _genderController.dispose();
    super.dispose();
  }

  void _next() {
    if (_step < 3) {
      setState(() => _step++);
      return;
    }
    _createAccount();
  }

  Future<void> _createAccount() async {
    final profile = UserProfile(
      email: _emailController.text.trim(),
      password: _passwordController.text,
      name: _nameController.text.trim(),
      gender: _gender,
      marketingNews: _marketingNews,
      marketingShare: _marketingShare,
    );
    await context.read<AuthService>().signUp(profile);
    if (!mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const ChooseArtistsScreen()),
      (_) => false,
    );
  }

  Future<void> _pickGender() async {
    const options = ['Man', 'Woman', 'Non-binary', 'Something else', 'Prefer not to say'];
    final picked = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: const Color(0xFF282828),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Padding(
                padding: EdgeInsets.all(16),
                child: Text(
                  "What's your gender?",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
                ),
              ),
              for (final option in options)
                ListTile(
                  title: Text(option),
                  trailing: _gender == option ? const Icon(Icons.check, color: AppColors.musikAccent) : null,
                  onTap: () => Navigator.pop(ctx, option),
                ),
            ],
          ),
        );
      },
    );
    if (picked != null) {
      setState(() {
        _gender = picked;
        _genderController.text = picked;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return SignupScaffold(
      onBack: () {
        if (_step > 0) {
          setState(() => _step--);
        } else {
          Navigator.pop(context);
        }
      },
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 24),
          Expanded(child: _buildStep()),
        ],
      ),
    );
  }

  Widget _buildStep() {
    switch (_step) {
      case 0:
        return _EmailStep(
          controller: _emailController,
          enabled: _emailValid,
          onChanged: (_) => setState(() {}),
          onNext: _next,
        );
      case 1:
        return _PasswordStep(
          controller: _passwordController,
          enabled: _passwordValid,
          onChanged: (_) => setState(() {}),
          onNext: _next,
        );
      case 2:
        return _GenderStep(
          controller: _genderController,
          enabled: _genderValid,
          onTap: _pickGender,
          onNext: _next,
        );
      case 3:
      default:
        return _NameStep(
          nameController: _nameController,
          enabled: _nameValid,
          marketingNews: _marketingNews,
          marketingShare: _marketingShare,
          onChanged: (_) => setState(() {}),
          onMarketingNewsChanged: (v) => setState(() => _marketingNews = v),
          onMarketingShareChanged: (v) => setState(() => _marketingShare = v),
          onCreate: _createAccount,
        );
    }
  }
}

class _EmailStep extends StatelessWidget {
  final TextEditingController controller;
  final bool enabled;
  final ValueChanged<String> onChanged;
  final VoidCallback onNext;

  const _EmailStep({
    required this.controller,
    required this.enabled,
    required this.onChanged,
    required this.onNext,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "What's your email?",
          style: TextStyle(fontSize: 26, fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 24),
        SignupTextField(
          controller: controller,
          hintText: 'Email',
          keyboardType: TextInputType.emailAddress,
          onChanged: onChanged,
          showCheckmark: enabled,
        ),
        const SizedBox(height: 12),
        const Text(
          "You'll need to confirm this email later.",
          style: TextStyle(color: Color(0xFFB3B3B3), fontSize: 14),
        ),
        const Spacer(),
        SignupNextButton(enabled: enabled, onPressed: onNext),
        const SizedBox(height: 16),
      ],
    );
  }
}

class _PasswordStep extends StatelessWidget {
  final TextEditingController controller;
  final bool enabled;
  final ValueChanged<String> onChanged;
  final VoidCallback onNext;

  const _PasswordStep({
    required this.controller,
    required this.enabled,
    required this.onChanged,
    required this.onNext,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Create a password',
          style: TextStyle(fontSize: 26, fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 24),
        SignupTextField(
          controller: controller,
          hintText: 'Password',
          obscureText: true,
          onChanged: onChanged,
          showCheckmark: enabled,
        ),
        const SizedBox(height: 12),
        const Text(
          'Use at least 8 characters.',
          style: TextStyle(color: Color(0xFFB3B3B3), fontSize: 14),
        ),
        const Spacer(),
        SignupNextButton(enabled: enabled, onPressed: onNext),
        const SizedBox(height: 16),
      ],
    );
  }
}

class _GenderStep extends StatelessWidget {
  final TextEditingController controller;
  final bool enabled;
  final VoidCallback onTap;
  final VoidCallback onNext;

  const _GenderStep({
    required this.controller,
    required this.enabled,
    required this.onTap,
    required this.onNext,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "What's your gender?",
          style: TextStyle(fontSize: 26, fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 24),
        SignupTextField(
          controller: controller,
          hintText: 'Gender',
          readOnly: true,
          onTap: onTap,
          showCheckmark: enabled,
        ),
        const Spacer(),
        SignupNextButton(enabled: enabled, onPressed: onNext),
        const SizedBox(height: 16),
      ],
    );
  }
}

class _NameStep extends StatelessWidget {
  final TextEditingController nameController;
  final bool enabled;
  final bool marketingNews;
  final bool marketingShare;
  final ValueChanged<String> onChanged;
  final ValueChanged<bool> onMarketingNewsChanged;
  final ValueChanged<bool> onMarketingShareChanged;
  final VoidCallback onCreate;

  const _NameStep({
    required this.nameController,
    required this.enabled,
    required this.marketingNews,
    required this.marketingShare,
    required this.onChanged,
    required this.onMarketingNewsChanged,
    required this.onMarketingShareChanged,
    required this.onCreate,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "What's your name?",
            style: TextStyle(fontSize: 26, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 24),
          SignupTextField(
            controller: nameController,
            hintText: 'Name',
            onChanged: onChanged,
            showCheckmark: enabled,
          ),
          const SizedBox(height: 12),
          const Text(
            'This appears on your Musik profile.',
            style: TextStyle(color: Color(0xFFB3B3B3), fontSize: 14),
          ),
          const SizedBox(height: 28),
          const Divider(color: Color(0xFF3E3E3E)),
          const SizedBox(height: 20),
          RichText(
            text: const TextSpan(
              style: TextStyle(color: Color(0xFFB3B3B3), fontSize: 13, height: 1.5),
              children: [
                TextSpan(text: "By tapping on 'Create account', you agree to the Musik "),
                TextSpan(
                  text: 'Terms of Use',
                  style: TextStyle(color: AppColors.musikAccent, fontWeight: FontWeight.w600),
                ),
                TextSpan(text: '.\n\nMusik is committed to protecting your privacy. Read our '),
                TextSpan(
                  text: 'Privacy Policy',
                  style: TextStyle(color: AppColors.musikAccent, fontWeight: FontWeight.w600),
                ),
                TextSpan(text: ' in full.'),
              ],
            ),
          ),
          const SizedBox(height: 20),
          _MarketingRow(
            label: 'Please send me news and offers from Musik',
            value: marketingNews,
            onChanged: onMarketingNewsChanged,
          ),
          const SizedBox(height: 12),
          _MarketingRow(
            label: "Share my registration data with Musik's content providers for marketing purposes.",
            value: marketingShare,
            onChanged: onMarketingShareChanged,
          ),
          const SizedBox(height: 28),
          OnboardingPrimaryButton(
            label: 'Create account',
            filled: false,
            onPressed: enabled ? onCreate : null,
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}

class _MarketingRow extends StatelessWidget {
  final String label;
  final bool value;
  final ValueChanged<bool> onChanged;

  const _MarketingRow({
    required this.label,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Text(
            label,
            style: const TextStyle(color: Color(0xFFB3B3B3), fontSize: 13, height: 1.4),
          ),
        ),
        const SizedBox(width: 12),
        Switch(
          value: value,
          onChanged: onChanged,
          activeTrackColor: AppColors.musikAccent,
          inactiveTrackColor: const Color(0xFF535353),
        ),
      ],
    );
  }
}
