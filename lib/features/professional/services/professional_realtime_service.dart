import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:bellavella/core/routes/app_routes.dart';
import 'package:bellavella/core/widgets/job_request_popup.dart';
import 'package:bellavella/features/professional/services/professional_api_service.dart';
import 'package:bellavella/core/utils/toast_util.dart';
import 'package:bellavella/core/services/notification_service.dart';
import 'package:bellavella/core/router/professional_router.dart';

class ProfessionalRealtimeService {
  static StreamSubscription<DocumentSnapshot>? _jobSubscription;
  static StreamSubscription<DocumentSnapshot>? _notifSubscription;
  static StreamSubscription<DocumentSnapshot>? _callSubscription;

  static void startAllListeners(dynamic professionalId) {
    _listenJobs(professionalId);
    _listenNotifications(professionalId);
    _listenCalls(professionalId);
  }

  static void stopAllListeners() {
    _jobSubscription?.cancel();
    _notifSubscription?.cancel();
    _callSubscription?.cancel();
    _jobSubscription = null;
    _notifSubscription = null;
    _callSubscription = null;
  }

  /// 1. REAL-TIME JOBS
  static void _listenJobs(dynamic professionalId) {
    if (_jobSubscription != null) return;
    debugPrint('Starting Real-time Job Listener: $professionalId');

    _jobSubscription = FirebaseFirestore.instance
        .collection('job_requests')
        .doc('professional_$professionalId')
        .snapshots()
        .listen((snapshot) {
      debugPrint("🔥 FIRESTORE REALTIME: Job snapshot received");
      if (!snapshot.exists) {
        debugPrint("Snapshot does not exist for professional_$professionalId");
        return;
      }

      final data = snapshot.data() as Map<String, dynamic>?;
      debugPrint("Job Status: ${data?['status']}");
      if (data != null && data['status'] == 'pending') {
        debugPrint("🔥 NEW JOB ARRIVED - Triggering Popup");
        final context = proNavigatorKey.currentContext;
        if (context != null) _handleNewJob(context, data, snapshot.id);
      }
    });
  }

  /// 2. REAL-TIME NOTIFICATIONS (Calls the read API instantly)
  static void _listenNotifications(dynamic professionalId) {
    if (_notifSubscription != null) return;
    debugPrint('Starting Real-time Notification Listener: $professionalId');

    _notifSubscription = FirebaseFirestore.instance
        .collection('notifications')
        .doc('professional_$professionalId')
        .snapshots()
        .listen((snapshot) async {
      debugPrint("🔥 FIRESTORE REALTIME: Notification snapshot received");
      if (!snapshot.exists) return;

      final data = snapshot.data() as Map<String, dynamic>?;
      debugPrint("Notification Status: ${data?['status']}");
      if (data != null && data['status'] == 'unread') {
        debugPrint("🔥 NEW NOTIFICATION RECEIVED");
        _handleNewNotification(data, snapshot.id);
      }
    });
  }

  /// 3. REAL-TIME CALLS
  static void _listenCalls(dynamic professionalId) {
    if (_callSubscription != null) return;
    debugPrint('Starting Real-time Call Listener: $professionalId');

    _callSubscription = FirebaseFirestore.instance
        .collection('calls')
        .doc('professional_$professionalId')
        .snapshots()
        .listen((snapshot) {
      if (!snapshot.exists) return;

      final data = snapshot.data() as Map<String, dynamic>?;
      if (data != null && data['status'] == 'incoming') {
        _handleIncomingCall(data, snapshot.id);
      }
    });
  }

  static Future<void> _handleNewJob(BuildContext context, Map<String, dynamic> jobData, String docId) async {
    if (!context.mounted) return;

    NotificationService().showNotification(
      id: 999,
      title: 'New Job Request! 📢',
      body: 'You have a new ${jobData['service']} request at ${jobData['location']}.',
    );

    final result = await context.pushNamed(
      AppRoutes.proIncomingRequestName,
      extra: jobData,
    );

    // After the full-screen dialog closes, mark the Firestore job request as processed/idle
    _markStatus(docId, 'job_requests', 'idle');

    if (result == true) {
      // If user accepted via the screen, ensure they are on the right workflow step
      // The screen already called acceptBooking API, so we just navigate
      if (context.mounted) {
        context.pushNamed(
          AppRoutes.proArriveName, 
          pathParameters: {'id': jobData['booking_id'].toString()},
          // Pass the data we already have to avoid a flicker/fetch if possible
          extra: jobData 
        );
      }
    }
  }

  static void _handleNewNotification(Map<String, dynamic> data, String docId) {
    // Show in-app notification
    NotificationService().showNotification(
      id: 888,
      title: data['title'] ?? 'Notification',
      body: data['body'] ?? '',
    );

    // If there's a notification ID from the backend, mark it as read immediately
    if (data['id'] != null) {
      ProfessionalApiService.markNotificationAsRead(data['id'].toString());
    }

    // Mark Firestore doc as read
    _markStatus(docId, 'notifications', 'read');
  }

  static void _handleIncomingCall(Map<String, dynamic> data, String docId) {
     final context = proNavigatorKey.currentContext;
     if (context == null || !context.mounted) return;

     // Navigate to call screen or show call overlay
     debugPrint('INCOMING CALL FROM: ${data['caller_name']}');
     // TODO: context.pushNamed(AppRoutes.proCallName, extra: data);
  }

  static void _markStatus(String docId, String collection, String status) {
    FirebaseFirestore.instance.collection(collection).doc(docId).update({
      'status': status,
      'processed_at': FieldValue.serverTimestamp(),
    });
  }
}
