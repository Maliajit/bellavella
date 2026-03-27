import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'core/config/app_config.dart';
import 'core/router/professional_router.dart';
import 'core/services/firebase_messaging_service.dart';
import 'core/services/notification_service.dart';
import 'core/services/theme_service.dart';
import 'core/services/token_manager.dart';
import 'main.dart' as app;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await TokenManager.init();
  await ThemeService.fetch();

  // flutter_local_notifications is mobile-only.
  if (!kIsWeb) {
    try {
      await NotificationService().init();
    } catch (e) {
      debugPrint('Notification init error: $e');
    }
  } else {
    debugPrint('Notification init skipped on web.');
  }

  // Firebase Messaging itself can still run on supported platforms.
  try {
    await FirebaseMessagingService.init();
  } catch (e) {
    debugPrint('FCM init error: $e');
  }

  AppConfig.type = AppType.professional;
  app.main(router: professionalRouter);
}
