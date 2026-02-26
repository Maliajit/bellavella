import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/config/app_config.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) {
        if (AppConfig.isProfessional) {
          context.go('/professional/login');
        } else {
          context.go('/onboarding');
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: AppTheme.secondaryColor.withOpacity(0.5),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.spa_rounded,
                size: 80,
                color: AppTheme.primaryColor,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Bellavella',
              style: Theme.of(context).textTheme.displayLarge?.copyWith(
                    color: AppTheme.accentColor,
                    letterSpacing: 2,
                  ),
            ),
            Text(
              'Premium Beauty Services',
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: AppTheme.primaryColor,
                    letterSpacing: 1.2,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}
