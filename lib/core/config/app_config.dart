enum AppType { client, professional }

class AppConfig {
  static AppType? type;

  static bool get isClient => type == AppType.client;
  static bool get isProfessional => type == AppType.professional;

  // API Configuration
  // Note: 10.0.2.2 is the localhost address for Android Emulators
  // API Configuration
  // Note: 10.0.2.2 is the localhost address for Android Emulators
  // Use your computer's IP address (e.g., 192.168.1.x) for physical device testing
  static const String baseUrl = 'http://10.0.2.2:8000/api';
  
  // Get flavor from environment
  static String get flavor => const String.fromEnvironment('APP_FLAVOR');
}
