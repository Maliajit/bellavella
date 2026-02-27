import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'core/config/app_config.dart';
import 'core/theme/app_theme.dart';

void main({RouterConfig<Object>? router}) {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize flavor configuration
  if (AppConfig.type == null) {
    if (appFlavor == 'professional') {
      AppConfig.type = AppType.professional;
    } else {
      AppConfig.type = AppType.client;
    }
  }
  
  runApp(BellavellaApp(routerConfig: router));
}

class BellavellaApp extends StatelessWidget {
  final RouterConfig<Object>? routerConfig;

  const BellavellaApp({super.key, this.routerConfig});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: AppConfig.isProfessional ? 'Bellavella Pro' : 'Bellavella',
      theme: AppTheme.lightTheme,
      routerConfig: routerConfig!, 
      debugShowCheckedModeBanner: false,
    );
  }
}
