import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../config/app_config.dart';
import '../theme/theme_colors.dart';

class ThemeService {
  static ThemeColors _current = ThemeColors.fallback();

  /// The live colors. Always populated (falls back to defaults if fetch fails).
  static ThemeColors get current => _current;

  /// Notifier so that widgets can react to color changes without restart.
  static final ValueNotifier<ThemeColors> notifier =
      ValueNotifier(ThemeColors.fallback());

  /// Call this once at app startup (before runApp) to load colors from server.
  static Future<void> fetch() async {
    try {
      final uri = Uri.parse('${AppConfig.baseUrl}/theme');
      final response = await http.get(uri, headers: {
        'Accept': 'application/json',
      }).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        _current = ThemeColors.fromJson(data);
        notifier.value = _current;
        debugPrint('[ThemeService] Loaded: primary=${_current.primary}');
      }
    } catch (e) {
      debugPrint('[ThemeService] Fetch failed, using defaults. Error: $e');
      // Keep the fallback colours — the app still works offline
    }
  }
}
