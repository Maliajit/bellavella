import 'package:flutter/material.dart';
import 'core/config/app_config.dart';
import 'core/router/client_router.dart';
import 'main.dart' as app;

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  AppConfig.type = AppType.client;
  app.main(router: clientRouter);
}
