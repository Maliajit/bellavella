import 'package:bellavella/core/services/token_manager.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:bellavella/core/theme/app_theme.dart';
import 'package:bellavella/core/config/app_config.dart';
import 'package:bellavella/core/router/route_names.dart';
import '../../professional/services/professional_api_service.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(seconds: 2), () async {
      if (mounted) {
        if (AppConfig.isProfessional) {
          // Professional Flow
          if (TokenManager.hasToken) {
            try {
              final profile = await ProfessionalApiService.getProfile();
              if (mounted) {
                if (profile.verification == 'Verified') {
                  context.go(AppRoutes.proDashboard);
                } else {
                  context.go(AppRoutes.proVerificationStatus, extra: profile.name);
                }
              }
            } catch (e) {
              if (mounted) context.go(AppRoutes.proLogin);
            }
          } else {
            context.go(AppRoutes.proLogin);
          }
        } else {
          // Client Flow
          // 1. Check Onboarding (First Experience - Client Only)
          if (!TokenManager.isOnboardingComplete) {
            context.go(AppRoutes.onboarding);
            return;
          }

          if (!TokenManager.hasToken) {
            context.go(AppRoutes.clientLogin);
          } else if (!TokenManager.hasLocation) {
            context.go(AppRoutes.clientLocationPicker);
          } else {
            context.go(AppRoutes.clientHome);
          }
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
                color: AppTheme.secondaryColor.withValues(alpha: 0.5),
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
