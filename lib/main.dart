import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'core/config/app_config.dart';
import 'core/theme/app_theme.dart';
import 'core/router/client_router.dart';
import 'core/router/professional_router.dart';

import 'core/services/token_manager.dart';

import 'package:provider/provider.dart';
import 'features/professional/controllers/professional_profile_controller.dart';
import 'features/client/home/controllers/home_provider.dart';
import 'features/client/services/controllers/service_provider.dart';
import 'package:bellavella/features/client/cart/controllers/cart_provider.dart';

void main({RouterConfig<Object>? router}) async {
  WidgetsFlutterBinding.ensureInitialized();
  await TokenManager.init();
  
  // Initialize flavor configuration
  if (AppConfig.type == null) {
    final flavor = appFlavor ?? AppConfig.flavor;
    if (flavor == 'professional') {
      AppConfig.type = AppType.professional;
    } else {
      AppConfig.type = AppType.client;
    }
  }

  // Use provided router or fallback to the specific one based on app type
  final effectiveRouter = router ?? (AppConfig.isProfessional ? professionalRouter : clientRouter);
  
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ProfessionalProfileController()),
        ChangeNotifierProvider(create: (_) => HomeProvider()),
        ChangeNotifierProvider(create: (_) => ServiceProvider()),
        ChangeNotifierProvider(create: (_) => CartProvider()),
        // Add other providers here as needed
      ],
      child: BellavellaApp(routerConfig: effectiveRouter),
    ),
  );
}

class BellavellaApp extends StatelessWidget {
  final RouterConfig<Object>? routerConfig;

  const BellavellaApp({super.key, this.routerConfig});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: AppConfig.isProfessional ? 'Bellavella Pro' : 'Bellavella',
      theme: AppTheme.lightTheme,
      routerConfig: routerConfig, 
      debugShowCheckedModeBanner: false,
    );
  }
}
