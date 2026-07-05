import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Original Musik palette — not based on any third-party streaming brand.
class AppColors {
  static const Color musikAccent = Color(0xFF7C3CFF);
  static const Color musikAccentDark = Color(0xFF5E26D9);
  static const Color musikSecondary = Color(0xFFFF6B35);
  static const Color musikViolet = Color(0xFF7C5CFC);
  static const Color musikLime = Color(0xFFE7FF39);

  static const Color _darkBackground = Color(0xFF0A0A0F);
  static const Color _darkSurface = Color(0xFF14141C);
  static const Color _darkSurfaceElevated = Color(0xFF1E1E2A);
  static const Color _darkSurfaceHighlight = Color(0xFF2D2D3D);
  static const Color _darkTextPrimary = Color(0xFFF5F5F7);
  static const Color _darkTextSecondary = Color(0xFFA8A8B3);
  static const Color _darkTextMuted = Color(0xFF6B6B78);

  static const Color _lightBackground = Color(0xFFFFFFFF);
  static const Color _lightSurface = Color(0xFFFFFFFF);
  static const Color _lightSurfaceElevated = Color(0xFFF4F1FF);
  static const Color _lightSurfaceHighlight = Color(0xFFE9E3FF);
  static const Color _lightTextPrimary = Color(0xFF16131F);
  static const Color _lightTextSecondary = Color(0xFF7B7687);

  /// Light-theme defaults for the primary mobile experience.
  static const Color background = _lightBackground;
  static const Color surface = _lightSurface;
  static const Color surfaceElevated = _lightSurfaceElevated;
  static const Color surfaceHighlight = _lightSurfaceHighlight;
  static const Color textPrimary = _lightTextPrimary;
  static const Color textSecondary = _lightTextSecondary;
  static const Color textMuted = Color(0xFFA8A3B3);
  static const Color accent = musikAccent;
}

/// Theme-aware color helpers. Use `context.theme.background` etc.
extension AppColorsTheme on BuildContext {
  Color get background => Theme.of(this).scaffoldBackgroundColor;
  Color get surface => Theme.of(this).colorScheme.surface;
  Color get surfaceElevated =>
      Theme.of(this).cardTheme.color ?? AppColors.surfaceElevated;
  Color get surfaceHighlight => Theme.of(this).dividerColor;
  Color get textPrimary => Theme.of(this).colorScheme.onSurface;
  Color get textSecondary => Theme.of(this).brightness == Brightness.dark
      ? AppColors._darkTextSecondary
      : AppColors._lightTextSecondary;
  Color get textMuted => Theme.of(this).brightness == Brightness.dark
      ? AppColors._darkTextMuted
      : AppColors.textMuted;
  Color get accent => Theme.of(this).colorScheme.primary;
}

class AppTheme {
  static ThemeData buildTheme(
      {required bool dark, Color accent = AppColors.musikAccent}) {
    final base = ThemeData(
      useMaterial3: true,
      brightness: dark ? Brightness.dark : Brightness.light,
      scaffoldBackgroundColor:
          dark ? AppColors._darkBackground : AppColors._lightBackground,
      colorScheme: dark
          ? ColorScheme.dark(
              primary: accent,
              secondary: AppColors.musikSecondary,
              surface: AppColors._darkSurface,
              onPrimary: Colors.black,
              onSecondary: Colors.black,
              onSurface: AppColors._darkTextPrimary,
            )
          : ColorScheme.light(
              primary: accent,
              secondary: AppColors.musikSecondary,
              surface: AppColors._lightSurface,
              onPrimary: Colors.white,
              onSecondary: Colors.white,
              onSurface: AppColors._lightTextPrimary,
            ),
      dividerColor: dark
          ? AppColors._darkSurfaceHighlight
          : AppColors._lightSurfaceHighlight,
      splashColor: dark ? Colors.white12 : Colors.black12,
      highlightColor: dark ? Colors.white10 : Colors.black12,
    );

    final textPrimary =
        dark ? AppColors._darkTextPrimary : AppColors._lightTextPrimary;
    final bgColor =
        dark ? AppColors._darkBackground : AppColors._lightBackground;

    return base.copyWith(
      textTheme: GoogleFonts.plusJakartaSansTextTheme(base.textTheme).apply(
        bodyColor: textPrimary,
        displayColor: textPrimary,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: bgColor,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: TextStyle(
          color: textPrimary,
          fontSize: 22,
          fontWeight: FontWeight.w700,
        ),
        iconTheme: IconThemeData(color: textPrimary),
      ),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor:
            dark ? AppColors._darkSurface : AppColors._lightSurface,
        selectedItemColor: accent,
        unselectedItemColor:
            dark ? AppColors._darkTextSecondary : AppColors._lightTextSecondary,
        type: BottomNavigationBarType.fixed,
        elevation: 0,
        selectedLabelStyle:
            const TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
        unselectedLabelStyle: const TextStyle(fontSize: 11),
      ),
      cardTheme: CardThemeData(
        color: dark
            ? AppColors._darkSurfaceElevated
            : AppColors._lightSurfaceElevated,
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
      sliderTheme: SliderThemeData(
        activeTrackColor: accent,
        inactiveTrackColor: dark
            ? AppColors._darkSurfaceHighlight
            : AppColors._lightSurfaceHighlight,
        thumbColor: accent,
        overlayColor: accent.withValues(alpha: 0.15),
        trackHeight: 4,
      ),
      iconTheme: IconThemeData(color: textPrimary),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: accent,
        foregroundColor: Colors.white,
      ),
      chipTheme: ChipThemeData(
        backgroundColor: dark
            ? AppColors._darkSurfaceElevated
            : AppColors._lightSurfaceElevated,
        selectedColor: accent,
        labelStyle: TextStyle(fontWeight: FontWeight.w600, color: textPrimary),
        shape: const StadiumBorder(),
        side: BorderSide.none,
      ),
    );
  }

  static ThemeData get darkTheme => buildTheme(dark: true);
}
