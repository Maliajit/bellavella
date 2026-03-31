import 'package:flutter/material.dart';

class ThemeColors {
  final Color primary;
  final Color secondary;
  final Color background;

  const ThemeColors({
    required this.primary,
    required this.secondary,
    required this.background,
  });

  /// Default fallback colours (same as the original hardcoded values)
  factory ThemeColors.fallback() => const ThemeColors(
        primary: Color(0xFFFF4D7D),
        secondary: Color(0xFF6B7280),
        background: Color(0xFFF6F7F9),
      );

  /// Parse a 6-char hex string (with or without #) into a Flutter Color
  static Color _fromHex(String hex) {
    final clean = hex.replaceAll('#', '').trim();
    if (clean.length == 6) {
      return Color(int.parse('FF$clean', radix: 16));
    }
    return const Color(0xFFFF4D7D); // safety fallback
  }

  factory ThemeColors.fromJson(Map<String, dynamic> json) => ThemeColors(
        primary: _fromHex(json['primary_color'] ?? '#FF4D7D'),
        secondary: _fromHex(json['secondary_color'] ?? '#6B7280'),
        background: _fromHex(json['background_color'] ?? '#F6F7F9'),
      );
}
