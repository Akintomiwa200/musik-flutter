import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class PreferencesService extends ChangeNotifier {
  static const _tasteCompleteKey = 'taste_onboarding_complete';
  static const _artistsKey = 'selected_artists';
  static const _podcastsKey = 'selected_podcasts';
  static const _recentSearchesKey = 'recent_searches';

  bool _tasteComplete = false;
  Set<String> _selectedArtists = {};
  Set<String> _selectedPodcasts = {};
  List<Map<String, dynamic>> _recentSearches = [];

  bool get tasteOnboardingComplete => _tasteComplete;
  Set<String> get selectedArtists => Set.unmodifiable(_selectedArtists);
  Set<String> get selectedPodcasts => Set.unmodifiable(_selectedPodcasts);
  List<Map<String, dynamic>> get recentSearches => List.unmodifiable(_recentSearches);

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    _tasteComplete = prefs.getBool(_tasteCompleteKey) ?? false;
    _selectedArtists = (prefs.getStringList(_artistsKey) ?? []).toSet();
    _selectedPodcasts = (prefs.getStringList(_podcastsKey) ?? []).toSet();
    final raw = prefs.getString(_recentSearchesKey);
    if (raw != null) {
      final list = jsonDecode(raw) as List<dynamic>;
      _recentSearches = list.cast<Map<String, dynamic>>();
    }
    notifyListeners();
  }

  Future<void> toggleArtist(String id) async {
    if (_selectedArtists.contains(id)) {
      _selectedArtists.remove(id);
    } else {
      _selectedArtists.add(id);
    }
    await _saveArtists();
    notifyListeners();
  }

  Future<void> togglePodcast(String id) async {
    if (_selectedPodcasts.contains(id)) {
      _selectedPodcasts.remove(id);
    } else {
      _selectedPodcasts.add(id);
    }
    await _savePodcasts();
    notifyListeners();
  }

  Future<void> completeTasteOnboarding() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_tasteCompleteKey, true);
    _tasteComplete = true;
    notifyListeners();
  }

  Future<void> addRecentSearch(Map<String, dynamic> item) async {
    _recentSearches.removeWhere((e) => e['id'] == item['id']);
    _recentSearches.insert(0, item);
    if (_recentSearches.length > 10) {
      _recentSearches = _recentSearches.take(10).toList();
    }
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_recentSearchesKey, jsonEncode(_recentSearches));
    notifyListeners();
  }

  Future<void> resetTasteOnboarding() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_tasteCompleteKey);
    await prefs.remove(_artistsKey);
    await prefs.remove(_podcastsKey);
    _tasteComplete = false;
    _selectedArtists = {};
    _selectedPodcasts = {};
    notifyListeners();
  }

  Future<void> _saveArtists() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_artistsKey, _selectedArtists.toList());
  }

  Future<void> _savePodcasts() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_podcastsKey, _selectedPodcasts.toList());
  }
}
