import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/services.dart';
import 'core/config/app_config.dart';
import 'core/theme/app_theme.dart';
import 'core/router/client_router.dart';
import 'core/router/professional_router.dart';
import 'core/services/token_manager.dart';
import 'package:provider/provider.dart';
import 'features/professional/controllers/professional_profile_controller.dart';
import 'features/professional/controllers/dashboard_controller.dart';
import 'features/client/home/controllers/home_provider.dart';
import 'features/client/services/controllers/service_provider.dart';
import 'package:bellavella/features/client/cart/controllers/cart_provider.dart';

void main({RouterConfig<Object>? router}) async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize Firebase
  try {
    if (kIsWeb) {
      await Firebase.initializeApp(
        options: const FirebaseOptions(
          apiKey: "AIzaSyA-2aHswGGpbN4dL2Q7oFWjyv5TEiz5d7M",
          authDomain: "bellavella-68c59.firebaseapp.com",
          projectId: "bellavella-68c59",
          storageBucket: "bellavella-68c59.firebasestorage.app",
          messagingSenderId: "639709879636",
          appId: "1:639709879636:web:7030ca092280a6c6d23cc1",
          measurementId: "G-BF9BPY0047",
        ),
      );
    } else {
      await Firebase.initializeApp();
    }
    debugPrint('🔥 Firebase Initialized Successfully');
    
    FirebaseFirestore.instance.collection('job_requests').snapshots().listen((event) {
      debugPrint("🔥 FIRESTORE REALTIME WORKING");
      debugPrint("Job Requests Count: ${event.docs.length}");
    });

    FirebaseFirestore.instance.collection("test").snapshots().listen((event) {
      debugPrint("🔥 REALTIME TEST SUCCESS");
    });
  } catch (e) {
    debugPrint('❌ Firebase Initialization Error: $e');
    debugPrint('💡 TIP: If on Web, run "flutterfire configure" to generate lib/firebase_options.dart');
  }

  await TokenManager.init();
  
  if (AppConfig.type == null) {
    final flavor = appFlavor ?? AppConfig.flavor;
    if (flavor == 'professional') {
      AppConfig.type = AppType.professional;
    } else {
      AppConfig.type = AppType.client;
    }
  }

  final effectiveRouter = router ?? (AppConfig.isProfessional ? professionalRouter : clientRouter);
  
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ProfessionalProfileController()),
        // Single source of truth for the professional's active accepted job
        ChangeNotifierProvider(create: (_) => DashboardController.instance),
        ChangeNotifierProvider(create: (_) => HomeProvider()),
        ChangeNotifierProvider(create: (_) => ServiceProvider()),
        ChangeNotifierProvider(create: (_) => CartProvider()),
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
