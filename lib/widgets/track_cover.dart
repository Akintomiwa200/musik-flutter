import 'package:flutter/material.dart';

import '../models/track.dart';

class TrackCover extends StatelessWidget {
  final Track? track;
  final double? size;
  final double borderRadius;
  final bool expand;

  const TrackCover({
    super.key,
    this.track,
    this.size = 48,
    this.borderRadius = 8,
    this.expand = false,
  });

  @override
  Widget build(BuildContext context) {
    final url = track?.coverUrl;
    if (expand) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(borderRadius),
        child: url != null && url.isNotEmpty
            ? Image.network(url, fit: BoxFit.cover, errorBuilder: (_, __, ___) => _placeholderExpand())
            : _placeholderExpand(),
      );
    }

    final s = size ?? 48;
    if (url != null && url.isNotEmpty) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(borderRadius),
        child: Image.network(
          url,
          width: s,
          height: s,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => _placeholder(s),
        ),
      );
    }
    return _placeholder(s);
  }

  Widget _placeholder(double s) {
    return Container(
      width: s,
      height: s,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(borderRadius),
        gradient: const LinearGradient(
          colors: [Color(0xFF00C9A7), Color(0xFF14141C)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Icon(Icons.music_note, color: Colors.white.withValues(alpha: 0.5), size: s * 0.4),
    );
  }

  Widget _placeholderExpand() {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(borderRadius),
        gradient: const LinearGradient(
          colors: [Color(0xFF00C9A7), Color(0xFF14141C)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Center(
        child: Icon(Icons.music_note, color: Colors.white.withValues(alpha: 0.5), size: 80),
      ),
    );
  }
}
