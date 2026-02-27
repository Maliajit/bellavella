enum AppType { client, professional }

class AppConfig {
  static AppType? type;

  static bool get isClient => type == AppType.client;
  static bool get isProfessional => type == AppType.professional;

  // API Configuration
  // Note: 10.0.2.2 is the localhost address for Android Emulators
  static const String baseUrl = 'http://127.0.0.1:8000/api';
}
