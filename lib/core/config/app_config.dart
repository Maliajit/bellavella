import 'package:flutter/foundation.dart';

enum AppType { client, professional }

class AppConfig {
  static AppType? type;

  static bool get isClient => type == AppType.client;
  static bool get isProfessional => type == AppType.professional;

  // API Configuration
  // IMPORTANT: 10.0.2.2 is for Android Emulators
  // For Web, we use 127.0.0.1 (safer for CORS than 'localhost')
  // Since nothing is on port 8000, we are using port 80 (XAMPP default)
  static String get baseUrl {
    String host;
    if (kIsWeb) {
      host = 'http://127.0.0.1:8000';
    } else {
      host = 'http://10.0.2.2:8000';
    }

    // Assuming we use php artisan serve -> port 8000 -> /api
    final url = '$host/api';

    debugPrint('AppConfig: Resolved baseUrl: $url');
    return url;
  }

  // Get flavor from environment
  static String get flavor => const String.fromEnvironment('APP_FLAVOR');

  // Public client-side keys only. Secrets must stay on the backend.
  static String get razorpayKeyId => const String.fromEnvironment(
    'RAZORPAY_KEY_ID',
    defaultValue: 'rzp_test_S7dlJIqMvrpcaj',
  );

  static String get googleMapsApiKey => const String.fromEnvironment(
    'GOOGLE_MAPS_API_KEY',
  );
}
