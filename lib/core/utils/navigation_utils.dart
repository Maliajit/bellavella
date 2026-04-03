import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/routes/app_routes.dart';

/// 🌍 SafeNavigation (Expert Synchronization)
/// 
/// Centralizes the expert 300ms "Safe Navigation" pattern 
/// to resolve Flutter's Navigator race conditions (GlobalKey conflicts).
///
/// Use this pattern when moving from a Modal/BottomSheet/Dialog to a new Screen.
class SafeNavigation {
  
  /// 🎯 To Dashboard (Expert Pattern)
  /// 
  /// 1. Waits for modal animations to conclude (300ms)
  /// 2. Ensures the underlying Navigator key is fully released
  /// 3. Validates context safety (mounted check)
  /// 4. Executes GoRouter navigation
  static Future<void> toDashboard(BuildContext context) async {
    // 🛡️ Safe Point: Wait for animation + Navigator cleanup
    // Material bottom sheets typically take ~300ms to fully dispose
    await Future.delayed(const Duration(milliseconds: 300));
    
    if (!context.mounted) return;
    
    debugPrint("🚀 Safe Navulating to Dashboard...");
    
    // Using context.go for Top-Level dashboard navigation (Resetting stack)
    context.go(AppRoutes.proDashboard);
  }

  /// 🛡️ Generic Safe Navigation
  /// 
  /// Reusable wrapper for any navigation that needs a safety release
  static Future<void> safeAction(BuildContext context, VoidCallback action) async {
    await Future.delayed(const Duration(milliseconds: 300));
    if (context.mounted) {
      action();
    }
  }
}
