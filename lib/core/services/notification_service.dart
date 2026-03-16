import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import '../services/token_manager.dart';
import '../../features/professional/services/professional_api_service.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _notificationsPlugin = FlutterLocalNotificationsPlugin();

  Future<void> init() async {
    // 1. Android Initialization Settings
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    // 2. iOS Initialization Settings
    const DarwinInitializationSettings initializationSettingsDarwin =
        DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
    );

    // 3. Overall Initialization Settings
    const InitializationSettings initializationSettings = InitializationSettings(
      android: initializationSettingsAndroid,
      iOS: initializationSettingsDarwin,
    );

    await _notificationsPlugin.initialize(
      settings: initializationSettings,
      onDidReceiveNotificationResponse: (details) {
        // Handle notification tap
      },
    );

    // Create a special channel for custom sounds (Android 8.0+)
    const AndroidNotificationChannel channel = AndroidNotificationChannel(
      'high_importance_channel', // id
      'High Importance Notifications', // title
      description: 'This channel is used for important notifications with custom sounds.', // description
      importance: Importance.max,
      playSound: true,
      sound: RawResourceAndroidNotificationSound('notification_sound'),
    );

    await _notificationsPlugin
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(channel);

    // 4. FCM Initialization
    await _initFcm();
  }

  Future<void> _initFcm() async {
    FirebaseMessaging messaging = FirebaseMessaging.instance;

    // Request permissions (especially for iOS)
    NotificationSettings settings = await messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    if (settings.authorizationStatus == AuthorizationStatus.authorized) {
      debugPrint('User granted permission');
    }

    // Foreground messages
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      debugPrint('Message received in foreground: ${message.notification?.title}');
      if (message.notification != null) {
        showNotification(
          id: message.hashCode,
          title: message.notification!.title ?? 'New Message',
          body: message.notification!.body ?? '',
        );
      }
    });

    // Background message callback is usually set in main.dart or here
  }

  Future<String?> getFcmToken() async {
    try {
      String? token = await FirebaseMessaging.instance.getToken();
      debugPrint('FCM Token: $token');
      return token;
    } catch (e) {
      debugPrint('Error getting FCM token: $e');
      return null;
    }
  }

  Future<void> registerFcmToken() async {
    final token = await getFcmToken();
    final authToken = TokenManager.token;
    if (token != null && authToken != null) {
      await ProfessionalApiService.updateFcmToken(token);
      debugPrint('FCM Token registered with backend');
    }
  }

  Future<void> showNotification({
    required int id,
    required String title,
    required String body,
    String? payload,
  }) async {
    final AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      'high_importance_channel',
      'High Importance Notifications',
      channelDescription: 'This channel is used for important notifications with custom sounds.',
      importance: Importance.max,
      priority: Priority.high,
      playSound: true,
      sound: const RawResourceAndroidNotificationSound('notification_sound'),
    );

    const DarwinNotificationDetails iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
      sound: 'notification_sound.mp3',
    );

    final NotificationDetails notificationDetails = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _notificationsPlugin.show(
      id: id,
      title: title,
      body: body,
      notificationDetails: notificationDetails,
      payload: payload,
    );
  }

  Future<void> showLoginSuccess() async {
    await showNotification(
      id: 100,
      title: 'Login Successful! 🎉',
      body: 'Welcome back to BellaVella. Enjoy your premium salon experience.',
    );
  }
}
