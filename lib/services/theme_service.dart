import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeService extends ChangeNotifier {
  static const _darkModeKey = 'dark_mode';
  static const _accentColorKey = 'accent_color';

  bool _isDarkMode = true;
  Color _accentColor = const Color(0xFF00C9A7);

  bool get isDarkMode => _isDarkMode;
  Color get accentColor => _accentColor;

  static const List<Color> presetAccents = [
    Color(0xFF00C9A7),
    Color(0xFF7C5CFC),
    Color(0xFFFF6B35),
    Color(0xFFFF4D6D),
    Color(0xFF4CAF50),
    Color(0xFF2196F3),
    Color(0xFFFF9800),
    Color(0xFFE91E63),
  ];

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getBool(_darkModeKey);
    // Default to system dark mode if no preference saved
    if (saved == null) {
      _isDarkMode = WidgetsBinding.instance.platformDispatcher.platformBrightness == Brightness.dark;
    } else {
      _isDarkMode = saved;
    }
    final savedAccent = prefs.getInt(_accentColorKey);
    if (savedAccent != null) {
      _accentColor = Color(savedAccent);
    }
    notifyListeners();
  }

  Future<void> setDarkMode(bool value) async {
    if (value == _isDarkMode) return;
    _isDarkMode = value;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_darkModeKey, value);
  }

  Future<void> setAccentColor(Color color) async {
    if (color == _accentColor) return;
    _accentColor = color;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_accentColorKey, color.value);
  }
}
