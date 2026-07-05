import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/track.dart';

class SavedPlaylist {
  final String id;
  final String name;
  final List<Track> tracks;

  const SavedPlaylist({
    required this.id,
    required this.name,
    required this.tracks,
  });

  String get subtitle => 'Playlist - ${tracks.length} songs';
}

class LibraryService extends ChangeNotifier {
  static const _likedTracksKey = 'library_liked_tracks';
  static const _hiddenTracksKey = 'library_hidden_tracks';
  static const _playlistsKey = 'library_playlists';

  final Map<String, Track> _likedTracks = {};
  final Set<String> _hiddenTrackIds = {};
  final List<SavedPlaylist> _playlists = [];

  List<Track> get likedTracks => List.unmodifiable(_likedTracks.values);
  Set<String> get hiddenTrackIds => Set.unmodifiable(_hiddenTrackIds);
  List<SavedPlaylist> get playlists => List.unmodifiable(_playlists);

  bool isLiked(String trackId) => _likedTracks.containsKey(trackId);
  bool isHidden(String trackId) => _hiddenTrackIds.contains(trackId);

  List<Track> visibleTracks(Iterable<Track> tracks) =>
      tracks.where((track) => !isHidden(track.id)).toList();

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();

    _likedTracks
      ..clear()
      ..addEntries(
        (prefs.getStringList(_likedTracksKey) ?? [])
            .map(_decodeTrack)
            .whereType<Track>()
            .map((track) => MapEntry(track.id, track)),
      );

    _hiddenTrackIds
      ..clear()
      ..addAll(prefs.getStringList(_hiddenTracksKey) ?? []);

    _playlists
      ..clear()
      ..addAll(
        (prefs.getStringList(_playlistsKey) ?? [])
            .map(_decodePlaylist)
            .whereType<SavedPlaylist>(),
      );

    notifyListeners();
  }

  Future<void> toggleLike(Track track) async {
    if (_likedTracks.containsKey(track.id)) {
      _likedTracks.remove(track.id);
    } else {
      _likedTracks[track.id] = track;
      _hiddenTrackIds.remove(track.id);
    }
    await _saveLikedTracks();
    await _saveHiddenTracks();
    notifyListeners();
  }

  Future<void> likeAll(Iterable<Track> tracks) async {
    for (final track in tracks) {
      if (!_hiddenTrackIds.contains(track.id)) {
        _likedTracks[track.id] = track;
      }
    }
    await _saveLikedTracks();
    notifyListeners();
  }

  Future<void> hideTrack(Track track) async {
    _hiddenTrackIds.add(track.id);
    _likedTracks.remove(track.id);
    for (var i = 0; i < _playlists.length; i++) {
      final playlist = _playlists[i];
      _playlists[i] = SavedPlaylist(
        id: playlist.id,
        name: playlist.name,
        tracks: playlist.tracks.where((item) => item.id != track.id).toList(),
      );
    }
    await Future.wait([_saveHiddenTracks(), _saveLikedTracks(), _savePlaylists()]);
    notifyListeners();
  }

  Future<void> addToPlaylist(Track track, {String playlistName = 'My Playlist'}) async {
    final index = _playlists.indexWhere((playlist) => playlist.name == playlistName);
    if (index == -1) {
      _playlists.add(SavedPlaylist(
        id: 'playlist-${DateTime.now().microsecondsSinceEpoch}',
        name: playlistName,
        tracks: [track],
      ));
    } else {
      final playlist = _playlists[index];
      if (playlist.tracks.any((item) => item.id == track.id)) return;
      _playlists[index] = SavedPlaylist(
        id: playlist.id,
        name: playlist.name,
        tracks: [...playlist.tracks, track],
      );
    }
    await _savePlaylists();
    notifyListeners();
  }

  Future<void> _saveLikedTracks() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(
      _likedTracksKey,
      _likedTracks.values.map((track) => jsonEncode(_trackToJson(track))).toList(),
    );
  }

  Future<void> _saveHiddenTracks() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_hiddenTracksKey, _hiddenTrackIds.toList());
  }

  Future<void> _savePlaylists() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(
      _playlistsKey,
      _playlists.map((playlist) => jsonEncode(_playlistToJson(playlist))).toList(),
    );
  }

  Map<String, dynamic> _playlistToJson(SavedPlaylist playlist) => {
        'id': playlist.id,
        'name': playlist.name,
        'tracks': playlist.tracks.map(_trackToJson).toList(),
      };

  SavedPlaylist? _decodePlaylist(String raw) {
    try {
      final json = jsonDecode(raw) as Map<String, dynamic>;
      final tracks = (json['tracks'] as List<dynamic>? ?? [])
          .cast<Map<String, dynamic>>()
          .map(_trackFromJson)
          .toList();
      return SavedPlaylist(
        id: json['id'] as String? ?? 'playlist-${json['name'].hashCode}',
        name: json['name'] as String? ?? 'My Playlist',
        tracks: tracks,
      );
    } catch (_) {
      return null;
    }
  }

  Track? _decodeTrack(String raw) {
    try {
      return _trackFromJson(jsonDecode(raw) as Map<String, dynamic>);
    } catch (_) {
      return null;
    }
  }

  Map<String, dynamic> _trackToJson(Track track) => {
        'id': track.id,
        'title': track.title,
        'artist': track.artist,
        'album': track.album,
        'filePath': track.filePath,
        'durationMs': track.duration?.inMilliseconds,
        'source': track.source,
        'isDemo': track.isDemo,
        'previewUrl': track.previewUrl,
        'streamUrl': track.streamUrl,
        'coverUrl': track.coverUrl,
      };

  Track _trackFromJson(Map<String, dynamic> json) => Track(
        id: json['id'] as String,
        title: json['title'] as String? ?? 'Unknown',
        artist: json['artist'] as String? ?? 'Unknown Artist',
        album: json['album'] as String? ?? '',
        filePath: json['filePath'] as String? ?? '',
        duration: json['durationMs'] is int ? Duration(milliseconds: json['durationMs'] as int) : null,
        source: json['source'] as String? ?? 'local',
        isDemo: json['isDemo'] as bool? ?? false,
        previewUrl: json['previewUrl'] as String?,
        streamUrl: json['streamUrl'] as String?,
        coverUrl: json['coverUrl'] as String?,
      );
}
