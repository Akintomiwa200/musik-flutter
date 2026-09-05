import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum ThemeModePreference { system, light, dark }

class ThemeService extends ChangeNotifier {
  static const _darkModeKey = 'dark_mode';
  static const _themeModeKey = 'theme_mode';
  static const _accentColorKey = 'accent_color';

  ThemeModePreference _preference = ThemeModePreference.system;
  bool _systemDark = false;
  Color _accentColor = const Color(0xFF00C9A7);

  bool get isDarkMode {
    return switch (_preference) {
      ThemeModePreference.light => false,
      ThemeModePreference.dark => true,
      ThemeModePreference.system => _systemDark,
    };
  }

  ThemeModePreference get preference => _preference;
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

    // Read the system brightness live
    _systemDark =
        WidgetsBinding.instance.platformDispatcher.platformBrightness ==
            Brightness.dark;
    WidgetsBinding.instance.platformDispatcher.onPlatformBrightnessChanged =
        _handleSystemBrightness;

    // Restore user preference
    final savedPref = prefs.getString(_themeModeKey);
    if (savedPref != null) {
      _preference = switch (savedPref) {
        'light' => ThemeModePreference.light,
        'dark' => ThemeModePreference.dark,
        _ => ThemeModePreference.system,
      };
    } else {
      // Legacy: old app stored a bool under dark_mode
      final legacyDark = prefs.getBool(_darkModeKey);
      if (legacyDark != null) {
        _preference = legacyDark
            ? ThemeModePreference.dark
            : ThemeModePreference.light;
      }
    }

    final savedAccent = prefs.getInt(_accentColorKey);
    if (savedAccent != null) {
      _accentColor = Color(savedAccent);
    }
    notifyListeners();
  }

  void _handleSystemBrightness() {
    _systemDark =
        WidgetsBinding.instance.platformDispatcher.platformBrightness ==
            Brightness.dark;
    // Only notify if we're currently following the system
    if (_preference == ThemeModePreference.system) {
      notifyListeners();
    }
  }

  /// Sets the theme mode. [mode] null resets back to following the system.
  void setThemeMode(ThemeModePreference mode) {
    if (mode == _preference) return;
    _preference = mode;
    notifyListeners();
    _persist();
  }

  void setDarkMode(bool value) {
    setThemeMode(value ? ThemeModePreference.dark : ThemeModePreference.light);
  }

  void followSystem() {
    setThemeMode(ThemeModePreference.system);
  }

  Future<void> setAccentColor(Color color) async {
    if (color == _accentColor) return;
    _accentColor = color;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_accentColorKey, color.value);
  }

  void _persist() {
    final value = switch (_preference) {
      ThemeModePreference.light => 'light',
      ThemeModePreference.dark => 'dark',
      ThemeModePreference.system => 'system',
    };
    SharedPreferences.getInstance().then((prefs) => prefs.setString(
        _themeModeKey, value));
  }

  @override
  void dispose() {
    WidgetsBinding.instance.platformDispatcher.onPlatformBrightnessChanged =
        null;
    super.dispose();
  }
}
