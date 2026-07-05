import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';

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

  String get _shareUrl => musikShareUrl('track', '$artist $title');
  String get _shareText => 'Listen to "$title" by $artist on Musik: $_shareUrl';

  Future<void> _copy(BuildContext context) async {
    await Clipboard.setData(ClipboardData(text: _shareUrl));
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Link copied'), duration: Duration(seconds: 2)),
      );
    }
  }

  Future<void> _launchShare(BuildContext context, Uri uri) async {
    final opened = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!opened && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No app found to complete sharing')),
      );
    }
  }

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
              style: TextStyle(color: context.textSecondary, fontSize: 16),
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
                    onTap: () => _copy(context),
                  ),
                  _ShareAction(
                    label: 'WhatsApp',
                    icon: Icons.chat,
                    color: const Color(0xFF25D366),
                    onTap: () => _launchShare(
                      context,
                      Uri.parse('https://wa.me/?text=${Uri.encodeComponent(_shareText)}'),
                    ),
                  ),
                  _ShareAction(
                    label: 'Twitter',
                    icon: Icons.tag,
                    color: const Color(0xFF1DA1F2),
                    onTap: () => _launchShare(
                      context,
                      Uri.parse('https://twitter.com/intent/tweet?text=${Uri.encodeComponent(_shareText)}'),
                    ),
                  ),
                  _ShareAction(
                    label: 'Messages',
                    icon: Icons.message_outlined,
                    color: const Color(0xFF34C759),
                    onTap: () => _launchShare(
                      context,
                      Uri.parse('sms:?body=${Uri.encodeComponent(_shareText)}'),
                    ),
                  ),
                  _ShareAction(
                    label: 'More',
                    icon: Icons.more_horiz,
                    onTap: () => _launchShare(
                      context,
                      Uri.parse('mailto:?subject=${Uri.encodeComponent(title)}&body=${Uri.encodeComponent(_shareText)}'),
                    ),
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
      onTap: onTap,
      child: Column(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: color ?? context.surfaceElevated,
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: Colors.white),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 11, color: context.textSecondary),
          ),
        ],
      ),
    );
  }
}


