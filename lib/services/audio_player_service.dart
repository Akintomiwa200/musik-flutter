import 'dart:async';

import 'package:audio_session/audio_session.dart';
import 'package:flutter/foundation.dart';
import 'package:just_audio/just_audio.dart';

import '../models/track.dart';
import 'download_service.dart';
import 'notification_service.dart';
import 'recommendation_service.dart';
import 'stream_resolver_service.dart';

enum PlaybackStatus { stopped, playing, paused, loading }
enum RepeatSetting { off, all, one }

class AudioPlayerService extends ChangeNotifier {
  static Map<String, String> get _streamHeaders => {
    'User-Agent': 'Mozilla/5.0 (Linux; Android 14) Musik/1.0',
  };

  final StreamResolverService _resolver;
  final RecommendationService _recommender;
  final DownloadService _downloadService;
  final NotificationService _notification;
  final AudioPlayer _player = AudioPlayer();
  Track? _currentTrack;
  List<Track> _queue = [];
  final List<Track> _playHistory = [];
  int _queueIndex = 0;
  PlaybackStatus _state = PlaybackStatus.stopped;
  bool _shuffle = false;
  RepeatSetting _repeatMode = RepeatSetting.off;
  bool _demoMode = false;
  bool _resolving = false;
  String? _lastError;
  Timer? _demoTimer;
  Timer? _sleepTimer;
  Duration _demoPosition = Duration.zero;
  Duration _demoDuration = Duration.zero;
  final _demoPositionController = StreamController<Duration>.broadcast();
  StreamSubscription<Duration>? _positionSub;
  StreamSubscription<PlayerState>? _playerStateSub;
  List<Track> _catalog = [];

  AudioPlayerService(this._resolver, this._recommender, this._downloadService, this._notification);

  void setCatalog(List<Track> tracks) {
    _catalog = tracks;
  }

  void addTracksToCatalog(Iterable<Track> tracks) {
    final existing = _catalog.map((t) => t.id).toSet();
    for (final track in tracks) {
      if (!existing.contains(track.id)) {
        _catalog.add(track);
        existing.add(track.id);
      }
    }
  }

  Track? get currentTrack => _currentTrack;
  List<Track> get playHistory => List.unmodifiable(_playHistory);
  List<Track> get queue => List.unmodifiable(_queue);
  int get queueIndex => _queueIndex;
  PlaybackStatus get state => _state;
  bool get shuffle => _shuffle;
  bool get repeat => _repeatMode != RepeatSetting.off;
  RepeatSetting get repeatMode => _repeatMode;
  bool get isPlaying => _state == PlaybackStatus.playing;
  bool get isResolving => _resolving;
  String? get lastError => _lastError;

  List<Track> get upcomingTracks {
    if (_queueIndex < 0 || _queueIndex >= _queue.length - 1) return [];
    return _queue.sublist(_queueIndex + 1);
  }

  void reorderUpcoming(int oldIndex, int newIndex) {
    final start = _queueIndex + 1;
    if (start >= _queue.length) return;
    final upcoming = List<Track>.from(_queue.sublist(start));
    if (oldIndex < 0 || oldIndex >= upcoming.length) return;
    var target = newIndex;
    if (target > upcoming.length) target = upcoming.length;
    if (target > oldIndex) target--;
    final moved = upcoming.removeAt(oldIndex);
    upcoming.insert(target, moved);
    _queue = [..._queue.sublist(0, start), ...upcoming];
    notifyListeners();
  }

  Future<void> addToQueue(Track track) async {
    if (_currentTrack == null) {
      await playTrack(track, queue: [track], index: 0);
      return;
    }
    _queue.add(track);
    notifyListeners();
  }

  void setSleepTimer(Duration duration) {
    _sleepTimer?.cancel();
    _sleepTimer = Timer(duration, stop);
    notifyListeners();
  }

  void cancelSleepTimer() {
    _sleepTimer?.cancel();
    _sleepTimer = null;
    notifyListeners();
  }

  Stream<Duration> get positionStream =>
      _demoMode ? _demoPositionController.stream : _player.createPositionStream();

  Stream<Duration?> get durationStream =>
      _demoMode ? Stream.value(_demoDuration) : _player.durationStream;

  Duration get position => _demoMode ? _demoPosition : _player.position;
  Duration? get duration => _demoMode ? _demoDuration : _player.duration;

  Future<void> _init() async {
    try {
      final session = await AudioSession.instance;
      await session.configure(const AudioSessionConfiguration.music());
    } catch (e) {
      debugPrint('Audio session setup skipped: $e');
    }

    _playerStateSub = _player.playerStateStream.listen((ps) {
      if (ps.processingState == ProcessingState.completed) {
        _onTrackComplete();
      }
      _syncPlaybackStatus(ps);
    });

    _positionSub = _player.createPositionStream(
      steps: 1,
      minPeriod: const Duration(milliseconds: 200),
    ).listen((_) => notifyListeners());

    _notification.listen(this);
  }

  void _syncPlaybackStatus(PlayerState ps) {
    if (_demoMode) return;
    if (_resolving) return;
    if (ps.processingState == ProcessingState.loading ||
        ps.processingState == ProcessingState.buffering) {
      _state = PlaybackStatus.loading;
    } else if (ps.playing) {
      _state = PlaybackStatus.playing;
    } else if (_currentTrack != null) {
      _state = PlaybackStatus.paused;
    } else {
      _state = PlaybackStatus.stopped;
    }
    _updateNotification();
    notifyListeners();
  }

  void _updateNotification() {
    if (_currentTrack == null || _state == PlaybackStatus.stopped) {
      _notification.cancel();
      return;
    }
    _notification.showNowPlaying(
      _currentTrack!,
      _state == PlaybackStatus.playing,
      downloads: _downloadService,
    );
  }

  void _recordPlay(Track track) {
    _playHistory.removeWhere((t) => t.id == track.id);
    _playHistory.insert(0, track);
    if (_playHistory.length > 15) {
      _playHistory.removeRange(15, _playHistory.length);
    }
  }

  Future<void> playTrack(Track track, {List<Track>? queue, int? index}) async {
    _lastError = null;

    addTracksToCatalog([track]);
    if (queue != null) addTracksToCatalog(queue);

    final localPath = _downloadService.localPathFor(track.id);
    final playable = localPath != null ? track.copyWith(filePath: localPath, source: 'local') : track;

    _currentTrack = playable;
    _recordPlay(playable);
    if (queue != null) {
      _queue = List.from(queue);
      _queueIndex = index ?? _queue.indexWhere((t) => t.id == playable.id);
      if (_queueIndex < 0) _queueIndex = 0;
    } else if (_queue.isEmpty) {
      _queue = [playable];
      _queueIndex = 0;
    }

    _state = PlaybackStatus.loading;
    _resolving = false;
    notifyListeners();

    if (playable.hasLocalFile) {
      await _playLocal(playable);
      return;
    }

    if (playable.isDemo) {
      await _player.stop();
      _stopDemo();
      await _startDemoPlayback(playable);
      return;
    }

    if (playable.isRemoteCatalog || playable.isStream) {
      await _playRemote(playable);
      return;
    }

    if (playable.filePath.isEmpty) {
      await _player.stop();
      _stopDemo();
      await _startDemoPlayback(playable);
    }

    _updateNotification();
  }

  Future<void> _playLocal(Track track) async {
    _stopDemo();
    try {
      await _player.stop();
      await _player.setFilePath(track.filePath);
      await _player.play();
    } catch (e) {
      _lastError = 'Could not play local file: $e';
      debugPrint(_lastError);
      _state = PlaybackStatus.stopped;
      notifyListeners();
    }
  }

  Future<void> _playRemote(Track track) async {
    _stopDemo();
    _resolving = true;
    _state = PlaybackStatus.loading;
    await _player.stop();

    try {
      final resolved = await _resolver.resolve(track).timeout(const Duration(seconds: 15));
      final enriched = track.copyWith(
        streamUrl: resolved.url,
        duration: resolved.duration ?? track.duration,
      );
      _currentTrack = enriched;
      if (_queueIndex >= 0 && _queueIndex < _queue.length) {
        _queue[_queueIndex] = enriched;
      }

      _resolving = false;
      notifyListeners();

      await _player.stop();
      final uri = Uri.parse(resolved.url);
      if (uri.scheme == 'http' || uri.scheme == 'https') {
        await _player.setAudioSource(
          AudioSource.uri(uri, headers: _streamHeaders),
        );
      } else {
        await _player.setFilePath(resolved.url);
      }
      await _player.play();
      _state = PlaybackStatus.playing;
      notifyListeners();
    } on TimeoutException {
      _resolving = false;
      _lastError = 'Could not resolve stream — timed out. Try again.';
      debugPrint(_lastError);
      _state = PlaybackStatus.stopped;
      notifyListeners();
    } on PlayerException catch (e) {
      _resolving = false;
      _lastError = 'Playback failed: ${e.message ?? e.code}';
      debugPrint('Remote play error: $e');
      _state = PlaybackStatus.stopped;
      notifyListeners();
    } catch (e) {
      _resolving = false;
      _lastError = 'Could not load song: $e';
      debugPrint(_lastError);
      _state = PlaybackStatus.stopped;
      notifyListeners();
    }
  }

  Future<void> _startDemoPlayback(Track track) async {
    _demoMode = true;
    _demoDuration = track.duration ?? const Duration(seconds: 30);
    _demoPosition = Duration.zero;
    _demoPositionController.add(_demoPosition);
    _state = PlaybackStatus.playing;
    notifyListeners();

    _demoTimer?.cancel();
    _demoTimer = Timer.periodic(const Duration(milliseconds: 500), (_) {
      if (_state != PlaybackStatus.playing) return;
      _demoPosition += const Duration(milliseconds: 500);
      _demoPositionController.add(_demoPosition);
      if (_demoPosition >= _demoDuration) {
        _onTrackComplete();
      }
      notifyListeners();
    });
  }

  void _stopDemo() {
    _demoTimer?.cancel();
    _demoTimer = null;
    _demoMode = false;
    _demoPosition = Duration.zero;
  }

  Future<void> togglePlayPause() async {
    if (_currentTrack == null) return;
    if (_demoMode) {
      _state = _state == PlaybackStatus.playing
          ? PlaybackStatus.paused
          : PlaybackStatus.playing;
      notifyListeners();
      return;
    }
    if (_player.playing) {
      await _player.pause();
    } else {
      await _player.play();
    }
  }

  Future<void> stop() async {
    _stopDemo();
    await _player.stop();
    _state = PlaybackStatus.stopped;
    _notification.cancel();
    notifyListeners();
  }

  Future<void> seek(Duration position) async {
    if (_demoMode) {
      _demoPosition = position;
      _demoPositionController.add(_demoPosition);
      notifyListeners();
      return;
    }
    await _player.seek(position);
  }

  Future<void> skipNext() async {
    if (_queue.isEmpty) return;
    if (_shuffle) {
      final shuffled = _shuffledQueue();
      final curIdx = shuffled.indexWhere((t) => t.id == _currentTrack?.id);
      _queueIndex = (curIdx + 1) % shuffled.length;
      await playTrack(shuffled[_queueIndex], queue: shuffled, index: _queueIndex);
      return;
    }
    _queueIndex = (_queueIndex + 1) % _queue.length;
    await playTrack(_queue[_queueIndex], queue: _queue, index: _queueIndex);
  }

  Future<void> skipPrevious() async {
    if (_queue.isEmpty) return;
    final pos = _demoMode ? _demoPosition : _player.position;
    if (pos.inSeconds > 3) {
      await seek(Duration.zero);
      return;
    }
    _queueIndex = (_queueIndex - 1 + _queue.length) % _queue.length;
    await playTrack(_queue[_queueIndex], queue: _queue, index: _queueIndex);
  }

  void toggleShuffle() {
    _shuffle = !_shuffle;
    notifyListeners();
  }

  List<Track> _shuffledQueue() {
    final current = _queueIndex.clamp(0, _queue.length - 1);
    final result = <Track>[];
    result.add(_queue[current]);
    final rest = List<Track>.from(_queue);
    rest.removeAt(current);
    rest.shuffle();
    result.addAll(rest);
    return result;
  }

  void toggleRepeat() {
    _repeatMode = switch (_repeatMode) {
      RepeatSetting.off => RepeatSetting.all,
      RepeatSetting.all => RepeatSetting.one,
      RepeatSetting.one => RepeatSetting.off,
    };
    notifyListeners();
  }

  void setRepeatSetting(RepeatSetting mode) {
    _repeatMode = mode;
    notifyListeners();
  }

  Future<void> _onTrackComplete() async {
    if (_repeatMode == RepeatSetting.one && _currentTrack != null) {
      if (_demoMode) {
        _demoPosition = Duration.zero;
        _demoPositionController.add(_demoPosition);
        _state = PlaybackStatus.playing;
        notifyListeners();
        return;
      }
      await seek(Duration.zero);
      await _player.play();
      return;
    }
    if (_queueIndex < _queue.length - 1) {
      await skipNext();
    } else if (_repeatMode == RepeatSetting.all && _queue.isNotEmpty) {
      _queueIndex = 0;
      await playTrack(_queue.first, queue: _queue, index: 0);
    } else if (_currentTrack != null && _catalog.isNotEmpty) {
      final similar = _recommender.similarTo(_currentTrack!, _catalog, count: 10);
      if (similar.isNotEmpty) {
        _queue.addAll(similar);
        await skipNext();
      } else {
        _state = PlaybackStatus.stopped;
        notifyListeners();
      }
    } else {
      _state = PlaybackStatus.stopped;
      notifyListeners();
    }
  }

  static AudioPlayerService create(StreamResolverService resolver, DownloadService downloadService) {
    final service = AudioPlayerService(resolver, RecommendationService(), downloadService, NotificationService());
    service._init();
    return service;
  }

  @override
  void dispose() {
    _stopDemo();
    _sleepTimer?.cancel();
    _positionSub?.cancel();
    _playerStateSub?.cancel();
    _demoPositionController.close();
    _player.dispose();
    super.dispose();
  }
}
