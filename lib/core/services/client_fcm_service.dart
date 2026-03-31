import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:bellavella/features/client/profile/services/client_profile_api_service.dart';
import 'package:bellavella/core/router/client_router.dart';

class ClientFcmService {
  static final FirebaseMessaging _messaging = FirebaseMessaging.instance;

  static Future<void> init() async {
    // 1. Request Permissions
    NotificationSettings settings = await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    if (settings.authorizationStatus == AuthorizationStatus.authorized) {
      debugPrint('🔔 Client FCM: User granted permission');
    }

    // 2. Get Token & Sync with Backend
    try {
      String? token = await _messaging.getToken();
      if (token != null) {
        debugPrint('🔔 Client FCM Token: $token');
        // Update token on backend (silent)
        await ClientProfileApiService.updateFcmToken(token);
      }
    } catch (e) {
      debugPrint('❌ Client FCM: Failed to sync token: $e');
    }

    // 3. Setup Listeners
    FirebaseMessaging.onMessage.listen(_handleForegroundMessage);
    FirebaseMessaging.onMessageOpenedApp.listen(_handleMessageOpenedApp);

    // Initial message if app was opened from terminated state
    RemoteMessage? initialMessage = await _messaging.getInitialMessage();
    if (initialMessage != null) {
      _handleMessageOpenedApp(initialMessage);
    }
  }

  static void _handleForegroundMessage(RemoteMessage message) {
    debugPrint('📩 Client FCM Foreground: ${message.notification?.title}');
    // Show a snackbar or local notification if desired
  }

  static void _handleMessageOpenedApp(RemoteMessage message) {
    debugPrint('🎯 Client FCM Tapped: ${message.data}');
    
    final String type = message.data['type'] ?? '';
    if (type == 'scratch_card') {
      // Navigate to wallet
      clientRouter.pushReplacement('/wallet');
    }
  }
}
