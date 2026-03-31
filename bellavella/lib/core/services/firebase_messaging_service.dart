import 'dart:convert';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:go_router/go_router.dart';
import 'package:bellavella/core/router/professional_router.dart';
import 'package:bellavella/core/routes/app_routes.dart';
import 'package:bellavella/core/services/realtime_job_service.dart';
import 'package:bellavella/features/professional/controllers/dashboard_controller.dart';
import 'package:bellavella/features/professional/services/professional_api_service.dart';
import 'notification_service.dart';

class FirebaseMessagingService {
  static final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  static final FlutterLocalNotificationsPlugin _localNotifications = FlutterLocalNotificationsPlugin();

  static Future<void> init() async {
    // 1. Request Permissions
    NotificationSettings settings = await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    if (settings.authorizationStatus == AuthorizationStatus.authorized) {
      debugPrint('🔔 FCM: User granted permission');
    }

    // 2. Get Token
    String? token = await _messaging.getToken();
    if (token != null) {
      debugPrint('🔔 FCM Token: $token');
      // Update token on backend (silent)
      await ProfessionalApiService.updateFcmToken(token);
    }

    // 3. Setup Listeners
    FirebaseMessaging.onMessage.listen(_handleForegroundMessage);
    FirebaseMessaging.onMessageOpenedApp.listen(_handleMessageOpenedApp);
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

    // Initial message if app was opened from terminated state
    RemoteMessage? initialMessage = await _messaging.getInitialMessage();
    if (initialMessage != null) {
      _handleMessageOpenedApp(initialMessage);
    }
  }

  static Future<void> _handleForegroundMessage(RemoteMessage message) async {
    debugPrint('🔔 FCM Foreground Message: ${message.data}');
    
    final String type = message.data['type'] ?? '';
    
    if (type == 'booking_assigned' || type == 'incoming_request') {
      final String bookingId = message.data['booking_id']?.toString() ?? '';
      if (bookingId.isNotEmpty && RealtimeJobService.shownBookings.contains(bookingId)) {
        debugPrint('🔔 FCM: Already showing booking $bookingId, skipping duplicate');
        return;
      }
      
      if (bookingId.isNotEmpty) RealtimeJobService.shownBookings.add(bookingId);

      // Direct navigation to IncomingRequestScreen using global navigator key
      proNavigatorKey.currentContext?.pushNamed(
        AppRoutes.proIncomingRequestName,
        extra: message.data,
      );
    } else if (type == 'job_status_updated') {
      // Refresh active job in controller
      final job = await ProfessionalApiService.getActiveJob();
      if (job != null) {
        DashboardController.instance.setActiveJob(job);
      }
    }
  }

  static void _handleMessageOpenedApp(RemoteMessage message) {
    debugPrint('🔔 FCM Message Opened App: ${message.data}');
    final String type = message.data['type'] ?? '';
    
    if (type == 'booking_assigned' || type == 'incoming_request') {
      final String bookingId = message.data['booking_id']?.toString() ?? '';
      if (bookingId.isNotEmpty) RealtimeJobService.shownBookings.add(bookingId);

      proNavigatorKey.currentContext?.pushNamed(
        AppRoutes.proIncomingRequestName,
        extra: message.data,
      );
    }
  }
}

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  debugPrint('🔔 FCM Background Message: ${message.messageId}');
  final String type = message.data['type'] ?? '';
  if (type == 'incoming_request' || type == 'booking_assigned') {
    await NotificationService.showIncomingCallNotification(message);
  }
}
