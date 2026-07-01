import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import '../widgets/sheets/music_sheets.dart';

class ShareScreen extends StatelessWidget {
  final String title;
  final String artist;

  const ShareScreen({
    super.key,
    required this.title,
    required this.artist,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.white),
                    onPressed: () => Navigator.pop(context),
                  ),
                  const Expanded(
                    child: Text(
                      'Share',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
                    ),
                  ),
                  const SizedBox(width: 48),
                ],
              ),
            ),
            const Spacer(),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 8),
            Text(
              artist,
              style: const TextStyle(color: AppColors.textSecondary, fontSize: 16),
            ),
            const Spacer(),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 32),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _ShareAction(
                    label: 'Copy\nLink',
                    icon: Icons.link,
                    onTap: () => copyTrackLink(context, title),
                  ),
                  _ShareAction(
                    label: 'WhatsApp',
                    icon: Icons.chat,
                    color: const Color(0xFF25D366),
                  ),
                  _ShareAction(
                    label: 'Twitter',
                    icon: Icons.tag,
                    color: const Color(0xFF1DA1F2),
                  ),
                  _ShareAction(
                    label: 'Messages',
                    icon: Icons.message_outlined,
                    color: const Color(0xFF34C759),
                  ),
                  _ShareAction(
                    label: 'More',
                    icon: Icons.more_horiz,
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

class _ShareAction extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color? color;
  final VoidCallback? onTap;

  const _ShareAction({
    required this.label,
    required this.icon,
    this.color,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap ?? () {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('$label sharing coming soon')),
        );
      },
      child: Column(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: color ?? AppColors.surfaceElevated,
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: Colors.white),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
          ),
        ],
      ),
    );
  }
}
