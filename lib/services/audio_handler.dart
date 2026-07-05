import 'dart:async';

import 'package:audio_service/audio_service.dart';
import 'package:just_audio/just_audio.dart';

class MusikAudioHandler extends JustAudioBackgroundTask {
  final _player = AudioPlayer();

  @override
  Future<void> onStart() async {
    await super.onStart();
  }

  @override
  Future<AudioPlayer> onCreatePlayer() async {
    return _player;
  }

  @override
  Future<void> onTaskRemoved() async {
    await _player.pause();
    await _player.stop();
    await super.onTaskRemoved();
  }

  Future<void> playMediaItem({
    required String id,
    required String title,
    required String artist,
    String? album,
    String? artUri,
    Duration? duration,
  }) async {
    await _player.stop();
    await _player.setAudioSource(
      AudioSource.uri(
        Uri.parse(''),
        tag: MediaItem(
          id: id,
          title: title,
          artist: artist,
          album: album ?? '',
          artUri: artUri != null ? Uri.tryParse(artUri) : null,
          duration: duration,
        ),
      ),
    );
  }

  Future<void> setSourceUri(String uri) async {
    await _player.stop();
    await _player.setAudioSource(AudioSource.uri(Uri.parse(uri)));
  }
}
