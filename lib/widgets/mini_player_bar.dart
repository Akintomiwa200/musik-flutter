import 'package:flutter/material.dart';

import '../models/track.dart';
import '../theme/app_theme.dart';
import 'track_cover.dart';

class MiniPlayerBar extends StatelessWidget {
  final String title;
  final String artist;
  final Track? track;
  final String? deviceLabel;
  final bool isPlaying;
  final bool isLoading;
  final double progress;
  final VoidCallback onTap;
  final VoidCallback onPlayPause;
  final VoidCallback? onCast;

  const MiniPlayerBar({
    super.key,
    required this.title,
    required this.artist,
    this.track,
    this.deviceLabel,
    required this.isPlaying,
    this.isLoading = false,
    required this.progress,
    required this.onTap,
    required this.onPlayPause,
    this.onCast,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: deviceLabel != null ? 72 : 64,
        decoration: BoxDecoration(
          color: const Color(0xFF1A1A2E),
          border: Border(
            top: BorderSide(color: Colors.white.withValues(alpha: 0.08)),
          ),
        ),
        child: Column(
          children: [
            LinearProgressIndicator(
              value: progress.clamp(0.0, 1.0),
              minHeight: 2,
              backgroundColor: Colors.transparent,
              color: AppColors.musikAccent,
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Row(
                  children: [
                    TrackCover(track: track, size: 44, borderRadius: 4),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                          ),
                          Text(
                            artist,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                          ),
                          if (deviceLabel != null) ...[
                            const SizedBox(height: 2),
                            GestureDetector(
                              onTap: onCast,
                              child: Row(
                                children: [
                                  const Icon(Icons.bluetooth_audio, color: AppColors.musikAccent, size: 14),
                                  const SizedBox(width: 4),
                                  Text(
                                    deviceLabel!.toUpperCase(),
                                    style: const TextStyle(
                                      fontSize: 11,
                                      color: AppColors.musikAccent,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    if (onCast != null && deviceLabel == null)
                      IconButton(
                        icon: const Icon(Icons.cast, size: 22),
                        onPressed: onCast,
                      ),
                    IconButton(
                      icon: isLoading
                          ? const SizedBox(
                              width: 28,
                              height: 28,
                              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                            )
                          : Icon(isPlaying ? Icons.pause : Icons.play_arrow),
                      iconSize: 32,
                      onPressed: isLoading ? null : onPlayPause,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
