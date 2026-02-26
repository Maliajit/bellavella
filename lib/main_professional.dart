import 'package:flutter/material.dart';
import 'core/config/app_config.dart';
import 'main.dart' as app;

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  AppConfig.type = AppType.professional;
  app.main();
}
