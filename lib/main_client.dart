import 'package:flutter/material.dart';
import 'core/config/app_config.dart';
import 'core/router/client_router.dart';
import 'core/services/theme_service.dart';
import 'main.dart' as app;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await ThemeService.fetch();
  AppConfig.type = AppType.client;
  app.main(router: clientRouter);
}
