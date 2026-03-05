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
      host = 'http://127.0.0.1';
    } else {
      host = 'http://10.0.2.2';
    }
    
    // Path: /bellavella/public/api (XAMPP structure)
    // If you run 'php artisan serve', change this back to :8000/api
    final url = '$host/bellavella/public/api';
    
    debugPrint('AppConfig: Resolved baseUrl: $url');
    return url;
  }
  
  // Get flavor from environment
  static String get flavor => const String.fromEnvironment('APP_FLAVOR');
}
