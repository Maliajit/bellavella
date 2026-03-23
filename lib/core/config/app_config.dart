import 'package:flutter/foundation.dart';

enum AppType { client, professional }

class AppConfig {
  static AppType? type;
  static const String _apiBaseUrlDefine = String.fromEnvironment('API_BASE_URL', defaultValue: 'http://192.168.1.6:8000/api');
  static const String _razorpayKeyDefine = String.fromEnvironment(
    'RAZORPAY_KEY_ID',
  );
  static const String _googleMapsApiKeyDefine = String.fromEnvironment(
    'GOOGLE_MAPS_API_KEY',
  );

  static bool get isClient => type == AppType.client;
  static bool get isProfessional => type == AppType.professional;

  static String get baseUrl {
    final url = _normalizedApiBaseUrl;
    debugPrint('AppConfig: Resolved baseUrl: $url');
    return url;
  }

  static String get host {
    final parsed = Uri.tryParse(_normalizedApiBaseUrl);
    return parsed?.host ?? 'localhost';
  }

  static int get port {
    final parsed = Uri.tryParse(_normalizedApiBaseUrl);
    return parsed?.port ?? 8000;
  }

  static String get origin {
    final uri = Uri.parse(baseUrl);
    return uri.replace(path: '', query: '', fragment: '').toString();
  }

  static String get flavor => const String.fromEnvironment('APP_FLAVOR');

  static String get razorpayKeyId {
    if (_razorpayKeyDefine.isEmpty) {
      throw StateError(
        'Missing RAZORPAY_KEY_ID. Pass it with --dart-define=RAZORPAY_KEY_ID=...',
      );
    }
    return _razorpayKeyDefine;
  }

  static String get googleMapsApiKey => _googleMapsApiKeyDefine;

  static String get _normalizedApiBaseUrl {
    final raw = _sanitizeApiBaseUrl(_apiBaseUrlDefine);
    if (raw.isEmpty) {
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

    return parsed.replace(path: normalizedPath, query: '', fragment: '').toString();
  }

  static String _sanitizeApiBaseUrl(String raw) {
    var sanitized = raw.trim();
    while (sanitized.endsWith('/')) {
      sanitized = sanitized.substring(0, sanitized.length - 1);
    }
    while (
        sanitized.endsWith('?') ||
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
