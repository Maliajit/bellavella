import 'package:flutter/material.dart';
import 'core/config/app_config.dart';
import 'core/router/professional_router.dart';
import 'core/services/token_manager.dart';
import 'core/services/theme_service.dart';
import 'core/services/firebase_messaging_service.dart';
import 'main.dart' as app;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await TokenManager.init();
  await ThemeService.fetch();
  
  // Initialize FCM
  try {
    await FirebaseMessagingService.init();
  } catch (e) {
    debugPrint('🔔 FCM Init Error: $e');
  }

  AppConfig.type = AppType.professional;
  app.main(router: professionalRouter);
}
