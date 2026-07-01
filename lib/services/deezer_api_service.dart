import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../models/catalog_album.dart';
import '../models/track.dart';

class DeezerApiService extends ChangeNotifier {
  static const _base = 'https://api.deezer.com';

  bool _loading = false;
  String? _error;
  List<Track> _chartTracks = [];
  List<CatalogAlbum> _chartAlbums = [];
  List<Track> _forYouTracks = [];
  List<Track> _searchResults = [];

  bool get loading => _loading;
  String? get error => _error;
  List<Track> get chartTracks => List.unmodifiable(_chartTracks);
  List<CatalogAlbum> get chartAlbums => List.unmodifiable(_chartAlbums);
  List<Track> get forYouTracks => List.unmodifiable(_forYouTracks);
  List<Track> get searchResults => List.unmodifiable(_searchResults);

  Future<void> fetchHomeCatalog() async {
    _loading = true;
    _error = null;
    notifyListeners();
    try {
      await Future.wait([_loadChartTracks(), _loadChartAlbums()]);
    } catch (e) {
      _error = e.toString();
      debugPrint('Home catalog error: $e');
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<void> fetchChart() => fetchHomeCatalog();

  Future<void> _loadChartTracks() async {
    final res = await http.get(Uri.parse('$_base/chart/0/tracks')).timeout(const Duration(seconds: 15));
    if (res.statusCode != 200) throw Exception('Chart unavailable (${res.statusCode})');
    final json = jsonDecode(res.body) as Map<String, dynamic>;
    final data = json['data'] as List<dynamic>? ?? [];
    _chartTracks = data.map((e) => _trackFromJson(e as Map<String, dynamic>)).toList();
  }

  Future<void> _loadChartAlbums() async {
    final res = await http.get(Uri.parse('$_base/chart/0/albums')).timeout(const Duration(seconds: 15));
    if (res.statusCode != 200) throw Exception('Albums unavailable (${res.statusCode})');
    final json = jsonDecode(res.body) as Map<String, dynamic>;
    final data = json['data'] as List<dynamic>? ?? [];
    _chartAlbums = data.map((e) => _albumFromJson(e as Map<String, dynamic>)).toList();
  }

  Future<void> fetchForYou(List<String> artistNames) async {
    if (artistNames.isEmpty) {
      _forYouTracks = [];
      notifyListeners();
      return;
    }
    final picks = <Track>[];
    for (final name in artistNames.take(8)) {
      try {
        final uri = Uri.parse('$_base/search').replace(queryParameters: {'q': name});
        final res = await http.get(uri).timeout(const Duration(seconds: 10));
        if (res.statusCode != 200) continue;
        final json = jsonDecode(res.body) as Map<String, dynamic>;
        final data = json['data'] as List<dynamic>? ?? [];
        if (data.isEmpty) continue;
        picks.add(_trackFromJson(data.first as Map<String, dynamic>));
      } catch (e) {
        debugPrint('For-you fetch error for $name: $e');
      }
    }
    _forYouTracks = picks;
    notifyListeners();
  }

  Future<List<Track>> fetchAlbumTracks(String albumId) async {
    final res = await http.get(Uri.parse('$_base/album/$albumId')).timeout(const Duration(seconds: 15));
    if (res.statusCode != 200) throw Exception('Album load failed (${res.statusCode})');
    final json = jsonDecode(res.body) as Map<String, dynamic>;
    final data = json['tracks']?['data'] as List<dynamic>? ?? [];
    return data.map((e) => _trackFromJson(e as Map<String, dynamic>)).toList();
  }

  Future<List<Track>> search(String query) async {
    if (query.trim().isEmpty) {
      _searchResults = [];
      notifyListeners();
      return [];
    }
    _loading = true;
    _error = null;
    notifyListeners();
    try {
      final uri = Uri.parse('$_base/search').replace(queryParameters: {'q': query.trim()});
      final res = await http.get(uri).timeout(const Duration(seconds: 15));
      if (res.statusCode != 200) throw Exception('Search failed (${res.statusCode})');
      final json = jsonDecode(res.body) as Map<String, dynamic>;
      final data = json['data'] as List<dynamic>? ?? [];
      _searchResults = data.map((e) => _trackFromJson(e as Map<String, dynamic>)).toList();
      return _searchResults;
    } catch (e) {
      _error = e.toString();
      debugPrint('Deezer search error: $e');
      return [];
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  CatalogAlbum _albumFromJson(Map<String, dynamic> json) {
    final artist = json['artist'] as Map<String, dynamic>?;
    return CatalogAlbum(
      id: '${json['id']}',
      title: json['title'] as String? ?? 'Album',
      artist: artist?['name'] as String? ?? 'Various',
      coverUrl: json['cover_medium'] as String? ?? json['cover_big'] as String? ?? '',
      trackCount: json['nb_tracks'] as int?,
    );
  }

  Track _trackFromJson(Map<String, dynamic> json) {
    final artist = json['artist'] as Map<String, dynamic>?;
    final album = json['album'] as Map<String, dynamic>?;
    final durationSec = json['duration'] as int? ?? 0;
    final preview = json['preview'] as String? ?? '';

    return Track(
      id: 'deezer-${json['id']}',
      title: json['title'] as String? ?? 'Unknown',
      artist: artist?['name'] as String? ?? 'Unknown Artist',
      album: album?['title'] as String? ?? 'Single',
      filePath: '',
      previewUrl: preview.isNotEmpty ? preview : null,
      coverUrl: album?['cover_medium'] as String? ?? album?['cover_big'] as String?,
      duration: Duration(seconds: durationSec),
      source: 'deezer',
    );
  }
}
