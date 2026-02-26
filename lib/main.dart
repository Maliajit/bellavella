import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'core/config/app_config.dart';
import 'core/router/app_router.dart';
import 'core/theme/app_theme.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize flavor configuration
  if (AppConfig.type == null) {
    if (appFlavor == 'professional') {
      AppConfig.type = AppType.professional;
    } else {
      AppConfig.type = AppType.client;
    }
  }
  
  runApp(const BellavellaApp());
}

class BellavellaApp extends StatelessWidget {
  const BellavellaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: AppConfig.isProfessional ? 'Bellavella Pro' : 'Bellavella',
      theme: AppTheme.lightTheme,
      routerConfig: AppRouter, // Router will eventually be updated to be flavor-aware
      debugShowCheckedModeBanner: false,
    );
  }
}
