import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../navigation/app_routes.dart';
import '../services/auth_service.dart';
import '../services/theme_service.dart';
import '../theme/app_theme.dart';
import '../widgets/persistent_bottom_chrome.dart';

class SettingsScreen extends StatelessWidget {
  final int currentTab;
  const SettingsScreen({super.key, this.currentTab = 0});

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthService>().user;
    final displayName = user?.name ?? 'Musik User';
    final email = user?.email ?? '';

    return ChromeScaffold(
      selectedTab: currentTab,
      appBar: AppBar(
        elevation: 0,
        centerTitle: true,
        title: const Text(
          'Settings',
          style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        children: [
          _ProfileHeader(
            displayName: displayName,
            subtitle: email.isNotEmpty ? email : 'View profile',
            onTap: () => AppRoutes.profile(context),
          ),
          const SizedBox(height: 20),
          const _SectionLabel('Personalization'),
          const SizedBox(height: 8),
          _SettingsCard(
            children: [
              _DarkModeTile(),
              const _TileDivider(),
              _AccentColorTile(),
            ],
          ),
          const SizedBox(height: 24),
          const _SectionLabel('Account'),
          const SizedBox(height: 8),
          _SettingsCard(
            children: [
              _SettingsTile(
                label: 'Profile',
                icon: Icons.person_outline,
                onTap: () => AppRoutes.account(context),
              ),
              const _TileDivider(),
              _SettingsTile(
                label: 'Storage & USB',
                icon: Icons.storage_outlined,
                onTap: () => AppRoutes.storage(context),
              ),
            ],
          ),
          const SizedBox(height: 24),
          const _SectionLabel('Support'),
          const SizedBox(height: 8),
          _SettingsCard(
            children: [
              _SettingsTile(
                label: 'About Musik',
                icon: Icons.info_outline,
                onTap: () => _showAbout(context),
              ),
            ],
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  void _showAbout(BuildContext context) {
    showAboutDialog(
      context: context,
      applicationName: 'Musik',
      applicationVersion: '1.0.0',
      applicationLegalese: '\u00a9 2025 Musik',
      children: [
        const Text('A Spotify-inspired music player with USB support.'),
      ],
    );
  }
}

class _ProfileHeader extends StatelessWidget {
  final String displayName;
  final String subtitle;
  final VoidCallback onTap;

  const _ProfileHeader({
    required this.displayName,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: onTap,
      child: Row(
        children: [
          CircleAvatar(
            radius: 26,
            backgroundColor: context.surfaceHighlight,
            child: const Icon(Icons.person, color: AppColors.textSecondary),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Hi, $displayName',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 13,
                    color: context.textSecondary,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          Icon(Icons.chevron_right, color: context.textSecondary),
        ],
      ),
    );
  }
}

class _PremiumBanner extends StatelessWidget {
  final VoidCallback onKnowMore;
  const _PremiumBanner({required this.onKnowMore});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF6A3DE8), Color(0xFFB23FE0)],
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Premium Membership',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Ad-free, offline listening',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.85),
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 14),
                ElevatedButton(
                  onPressed: onKnowMore,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: const Color(0xFF6A3DE8),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 18,
                      vertical: 10,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(24),
                    ),
                    elevation: 0,
                    textStyle: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  child: const Text('Know More'),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          const Icon(Icons.card_giftcard, color: Colors.white, size: 48),
        ],
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String text;
  const _SectionLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w600,
        color: context.textSecondary,
      ),
    );
  }
}

class _SettingsCard extends StatelessWidget {
  final List<Widget> children;
  const _SettingsCard({required this.children});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: context.surface,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(children: children),
    );
  }
}

class _TileDivider extends StatelessWidget {
  const _TileDivider();

  @override
  Widget build(BuildContext context) {
    return Divider(
      color: context.surfaceHighlight,
      height: 1,
      indent: 52,
    );
  }
}

class _DarkModeTile extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final themeService = context.watch<ThemeService>();
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16),
      leading: Icon(
        themeService.isDarkMode ? Icons.dark_mode : Icons.light_mode,
        color: context.textSecondary,
      ),
      title: const Text('Dark Mode', style: TextStyle(fontSize: 15)),
      trailing: Switch(
        value: themeService.isDarkMode,
        activeColor: themeService.accentColor,
        onChanged: (value) => themeService.setDarkMode(value),
      ),
    );
  }
}

class _AccentColorTile extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final themeService = context.watch<ThemeService>();
    return ListTile(
      leading: Icon(Icons.palette_outlined, color: context.textSecondary),
      title: const Text('Accent Color', style: TextStyle(fontSize: 15)),
      subtitle: Row(
        children: [
          Container(
            width: 14,
            height: 14,
            decoration: BoxDecoration(
              color: themeService.accentColor,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 8),
          Text(
            '#${themeService.accentColor.value.toRadixString(16).substring(2).toUpperCase()}',
            style: TextStyle(fontSize: 12, color: context.textMuted),
          ),
        ],
      ),
      onTap: () => _showColorPicker(context, themeService),
    );
  }

  void _showColorPicker(BuildContext context, ThemeService themeService) {
    showModalBottomSheet(
      context: context,
      backgroundColor: context.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => Padding(
        padding: const EdgeInsets.fromLTRB(24, 20, 24, 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: context.surfaceHighlight,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'Choose Accent Color',
              style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 20),
            Wrap(
              spacing: 14,
              runSpacing: 14,
              children: ThemeService.presetAccents.map((color) {
                final selected = color == themeService.accentColor;
                return GestureDetector(
                  onTap: () {
                    themeService.setAccentColor(color);
                    Navigator.pop(context);
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: color,
                      shape: BoxShape.circle,
                      border: selected
                          ? Border.all(color: Colors.white, width: 3)
                          : null,
                      boxShadow: selected
                          ? [BoxShadow(color: color.withValues(alpha: 0.5), blurRadius: 8)]
                          : null,
                    ),
                    child: selected
                        ? const Icon(Icons.check, color: Colors.white, size: 22)
                        : null,
                  ),
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }
}

class _SettingsTile extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback onTap;

  const _SettingsTile({
    required this.label,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16),
      leading: Icon(icon, color: context.textSecondary, size: 22),
      title: Text(label, style: const TextStyle(fontSize: 15)),
      trailing: Icon(
        Icons.chevron_right,
        color: context.textSecondary,
        size: 22,
      ),
      onTap: onTap,
    );
  }
}


