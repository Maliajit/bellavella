import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/theme_service.dart';

class AppTheme {
  // ──────────────────────────────────────────────────────────────────
  // Dynamic brand colors — fetched from the admin panel via /api/theme
  // Falls back to hardcoded defaults when offline.
  // ──────────────────────────────────────────────────────────────────
  static Color get primaryColor    => ThemeService.current.primary;
  static Color get secondaryColor  => ThemeService.current.secondary;
  static Color get backgroundColor => ThemeService.current.background;

  // Static colours that never change (always hardcoded)
  static const Color accentColor   = Color(0xFF1F2937); // Primary Text
  static const Color surfaceColor  = Colors.white;
  static const Color errorColor    = Color(0xFFEF4444);
  static const Color successColor  = Color(0xFF22C55E);
  static const Color greyText      = Color(0xFF6B7280);
  static const Color dividerColor  = Color(0xFFE5E7EB);

  /// Call this to build a fresh ThemeData with the current fetched colors.
  static ThemeData get lightTheme {
    final primary    = primaryColor;
    final secondary  = secondaryColor;
    final background = backgroundColor;

    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: primary,
        primary: primary,
        secondary: secondary,
        surface: surfaceColor,
        error: errorColor,
      ),
      scaffoldBackgroundColor: background,
      textTheme: GoogleFonts.poppinsTextTheme().copyWith(
        displayLarge: GoogleFonts.poppins(
          fontWeight: FontWeight.bold,
          color: accentColor,
        ),
        titleLarge: GoogleFonts.poppins(
          fontWeight: FontWeight.w700,
          color: accentColor,
          fontSize: 18,
        ),
        bodyLarge: GoogleFonts.poppins(
          color: greyText,
          fontSize: 14,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primary,
          foregroundColor: Colors.white,
          disabledBackgroundColor: const Color(0xFFD9D9D9),
          disabledForegroundColor: const Color(0xFF9E9E9E),
          minimumSize: const Size(double.infinity, 56),
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          textStyle: GoogleFonts.outfit(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            letterSpacing: 0.5,
          ),
        ),
      ),
    );
  }
}
