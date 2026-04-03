import 'package:flutter/foundation.dart';

enum AppType { client, professional }

class AppConfig {
  static AppType? type;

  static const String _apiBaseUrlDefine = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: '',
  );

  /// Optional debug-only override for physical device testing.
  /// For example: --dart-define=API_BASE_URL_DEBUG=http://192.168.1.100:8000/api
  static const String _apiBaseUrlDebugDefine = String.fromEnvironment(
    'API_BASE_URL_DEBUG',
    defaultValue: '',
  );

  static const String _razorpayKeyDefine = String.fromEnvironment(
    'RAZORPAY_KEY_ID',
    defaultValue: '',
  );

  static const String _googleMapsApiKeyDefine = String.fromEnvironment(
    'GOOGLE_MAPS_API_KEY',
    defaultValue: '',
  );

  static bool get isClient => type == AppType.client;
  static bool get isProfessional => type == AppType.professional;

  static String get baseUrl {
    final raw = _sanitizeApiBaseUrl(_apiBaseUrlDefine);
    if (raw.isEmpty) {
      if (kDebugMode) {
        final debugOverride = _sanitizeApiBaseUrl(_apiBaseUrlDebugDefine);
        if (debugOverride.isNotEmpty) {
          return debugOverride;
        }

        // Fallback for local development
        if (kIsWeb) {
          return 'http://localhost:8000/api/v1';
        }
        // For Android Emulator, use 10.0.2.2
        return 'http://10.0.2.2:8000/api/v1';
      }
      throw StateError(
        'Missing API_BASE_URL. Pass it with --dart-define=API_BASE_URL=http://host:8000/api',
      );
    }

    final parsed = Uri.tryParse(raw);
    if (parsed == null || !parsed.hasScheme || parsed.host.isEmpty) {
      throw StateError('Invalid API_BASE_URL: $raw');
    }

    final normalizedPath = parsed.path.endsWith('/')
        ? parsed.path.substring(0, parsed.path.length - 1)
        : parsed.path;

    final normalized = parsed
        .replace(path: normalizedPath, query: '', fragment: '')
        .toString();

    debugPrint('AppConfig: Resolved baseUrl: $normalized');
    return normalized;
  }

  static String get host {
    final parsed = Uri.parse(baseUrl);
    if (parsed.host.isEmpty) {
      throw StateError('Invalid host in baseUrl: $baseUrl');
    }
    return parsed.host;
  }

  static int get port {
    final parsed = Uri.parse(baseUrl);
    return parsed.hasPort ? parsed.port : (parsed.scheme == 'https' ? 443 : 80);
  }

  static String get origin {
    final parsed = Uri.parse(baseUrl);
    final portPart = parsed.hasPort ? ':${parsed.port}' : '';
    return '${parsed.scheme}://${parsed.host}$portPart';
  }

  static String get flavor =>
      const String.fromEnvironment('APP_FLAVOR', defaultValue: '');

  static String get razorpayKeyId {
    if (_razorpayKeyDefine.isEmpty) {
      if (kDebugMode) {
        return 'rzp_test_S7dlJIqMvrpcaj'; // Default test key for local development
      }
      throw StateError(
        'Missing RAZORPAY_KEY_ID. Pass it with --dart-define=RAZORPAY_KEY_ID=...',
      );
    }
    return _razorpayKeyDefine;
  }

  static String get googleMapsApiKey => _googleMapsApiKeyDefine;

  static String _sanitizeApiBaseUrl(String raw) {
    var sanitized = raw.trim();
    while (sanitized.endsWith('/')) {
      sanitized = sanitized.substring(0, sanitized.length - 1);
    }
    while (sanitized.endsWith('?') ||
        sanitized.endsWith('#') ||
        sanitized.endsWith('/?') ||
        sanitized.endsWith('/#')) {
      sanitized = sanitized.substring(0, sanitized.length - 1);
      while (sanitized.endsWith('/')) {
        sanitized = sanitized.substring(0, sanitized.length - 1);
      }
    }
    return sanitized;
  }
}
