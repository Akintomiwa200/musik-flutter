import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Original Musik palette — not based on any third-party streaming brand.
class AppColors {
  static const Color musikAccent = Color(0xFF00C9A7);
  static const Color musikAccentDark = Color(0xFF00A88A);
  static const Color musikSecondary = Color(0xFFFF6B35);
  static const Color musikViolet = Color(0xFF7C5CFC);
  static const Color background = Color(0xFF0A0A0F);
  static const Color surface = Color(0xFF14141C);
  static const Color surfaceElevated = Color(0xFF1E1E2A);
  static const Color surfaceHighlight = Color(0xFF2D2D3D);
  static const Color textPrimary = Color(0xFFF5F5F7);
  static const Color textSecondary = Color(0xFFA8A8B3);
  static const Color textMuted = Color(0xFF6B6B78);
  static const Color accent = musikAccent;
}

class AppTheme {
  static ThemeData get darkTheme {
    final base = ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: AppColors.background,
      colorScheme: const ColorScheme.dark(
        primary: AppColors.musikAccent,
        secondary: AppColors.musikSecondary,
        surface: AppColors.surface,
        onPrimary: Colors.black,
        onSecondary: Colors.black,
        onSurface: AppColors.textPrimary,
      ),
      dividerColor: AppColors.surfaceHighlight,
      splashColor: Colors.white12,
      highlightColor: Colors.white10,
    );

    return base.copyWith(
      textTheme: GoogleFonts.plusJakartaSansTextTheme(base.textTheme).apply(
        bodyColor: AppColors.textPrimary,
        displayColor: AppColors.textPrimary,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.background,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: TextStyle(
          color: AppColors.textPrimary,
          fontSize: 22,
          fontWeight: FontWeight.w700,
        ),
        iconTheme: IconThemeData(color: AppColors.textPrimary),
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: AppColors.surface,
        selectedItemColor: AppColors.musikAccent,
        unselectedItemColor: AppColors.textSecondary,
        type: BottomNavigationBarType.fixed,
        elevation: 0,
        selectedLabelStyle: TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
        unselectedLabelStyle: TextStyle(fontSize: 11),
      ),
      cardTheme: CardThemeData(
        color: AppColors.surfaceElevated,
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
      sliderTheme: SliderThemeData(
        activeTrackColor: AppColors.musikAccent,
        inactiveTrackColor: AppColors.surfaceHighlight,
        thumbColor: AppColors.musikAccent,
        overlayColor: AppColors.musikAccent.withValues(alpha: 0.15),
        trackHeight: 4,
      ),
      iconTheme: const IconThemeData(color: AppColors.textPrimary),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: AppColors.musikAccent,
        foregroundColor: Colors.black,
      ),
      chipTheme: ChipThemeData(
        backgroundColor: AppColors.surfaceElevated,
        selectedColor: AppColors.musikAccent,
        labelStyle: const TextStyle(fontWeight: FontWeight.w600),
        shape: const StadiumBorder(),
        side: BorderSide.none,
      ),
    );
  }
}
