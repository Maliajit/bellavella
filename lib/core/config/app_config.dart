import 'package:flutter/foundation.dart';

enum AppType { client, professional }

class AppConfig {
  static AppType? type;

  static bool get isClient => type == AppType.client;
  static bool get isProfessional => type == AppType.professional;

  // API Configuration
<<<<<<< Updated upstream
  // Use the laptop's LAN IP so Android/iOS devices on the same network can reach Laravel.
  static String get baseUrl {
    const url = 'http://192.168.1.15:8000/api';
=======
  // IMPORTANT: 10.0.2.2 is for Android Emulators
  // For Web, we use 127.0.0.1 (safer for CORS than 'localhost')
  static String get baseUrl {
    final url = kIsWeb
        ? 'http://127.0.0.1:8000/api'
        : 'http://10.0.2.2:8000/api';
>>>>>>> Stashed changes

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

  static String get googleMapsApiKey =>
      const String.fromEnvironment('GOOGLE_MAPS_API_KEY');
}