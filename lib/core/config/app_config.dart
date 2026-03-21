import 'package:flutter/foundation.dart';

enum AppType { client, professional }

class AppConfig {
  static AppType? type;

  static bool get isClient => type == AppType.client;
  static bool get isProfessional => type == AppType.professional;

  // API Configuration
  // Use the laptop's LAN IP so Android/iOS devices on the same network can reach Laravel.
  static String get baseUrl {
    const url = 'http://192.168.1.15:8000/api';

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
