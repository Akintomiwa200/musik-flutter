import 'dart:async';

import 'package:flutter/services.dart';

import '../models/track.dart';
import 'audio_player_service.dart';
import 'download_service.dart';

class NotificationService {
  static const _channel = MethodChannel('com.musik.app/notification');
  static const _eventChannel = EventChannel('com.musik.app/notification_events');

  StreamSubscription<dynamic>? _sub;

  void listen(AudioPlayerService player) {
    _sub?.cancel();
    _sub = _eventChannel.receiveBroadcastStream().listen((event) {
      switch (event as String) {
        case 'play':
          player.togglePlayPause();
          break;
        case 'pause':
          player.togglePlayPause();
          break;
        case 'next':
          player.skipNext();
          break;
        case 'prev':
          player.skipPrevious();
          break;
        case 'stop':
          player.stop();
          break;
      }
    });
  }

  void dispose() {
    _sub?.cancel();
  }

  Future<void> showNowPlaying(Track track, bool isPlaying, {DownloadService? downloads}) async {
    try {
      await _channel.invokeMethod('showNotification', {
        'id': track.id,
        'title': track.title,
        'artist': track.artist,
        'album': track.album,
        'artUrl': track.coverUrl ?? '',
        'isPlaying': isPlaying,
      });
    } catch (_) {}
  }

  Future<void> cancel() async {
    try {
      await _channel.invokeMethod('cancelNotification');
    } catch (_) {}
  }
}
