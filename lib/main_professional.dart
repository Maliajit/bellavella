import 'package:flutter/material.dart';
import 'core/config/app_config.dart';
import 'core/router/professional_router.dart';
import 'core/services/token_manager.dart';
import 'main.dart' as app;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await TokenManager.init();
  AppConfig.type = AppType.professional;
  app.main(router: professionalRouter);
}
