import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:bellavella/core/routes/app_routes.dart';
import 'package:bellavella/core/widgets/job_request_popup.dart';
import 'package:bellavella/features/professional/services/professional_api_service.dart';

class RealtimeJobService {
  static StreamSubscription? _subscription;
  static final Set<String> shownBookings = {};

  static void clearCache() {
    shownBookings.clear();
    debugPrint('🔥 RealtimeJobService: Cleared shownBookings cache');
  }

  static void start(dynamic professionalId, GlobalKey<NavigatorState> navKey) {
    if (_subscription != null) return;
    
    debugPrint("🔥 Realtime listener started (Professional ID = $professionalId)");

    _subscription = FirebaseFirestore.instance
        .collection('job_requests')
        .doc('professional_$professionalId')
        .snapshots()
        .listen((snapshot) {

      if (!snapshot.exists) {
        debugPrint('🔥 RealtimeJobService: No document found for professional_$professionalId');
        return;
      }

      final data = snapshot.data();
      debugPrint('🔥 RealtimeJobService: Received data: $data');

      if (data?['status'] == 'pending') {
        _showJobPopup(navKey, data!);
      }
    }, onError: (error) {
      debugPrint('🔥 RealtimeJobService Error: $error');
    });
  }

  static void _showJobPopup(GlobalKey<NavigatorState> navKey, Map<String, dynamic> data) {
    final context = navKey.currentContext;
    if (context == null) return;

    final String bookingId = data['booking_id']?.toString() ?? '';
    if (bookingId.isEmpty) return;

    if (shownBookings.contains(bookingId)) {
      debugPrint('🔥 RealtimeJobService: Already shown booking $bookingId');
      return;
    }

    debugPrint('🔥 RealtimeJobService: Navigating to IncomingRequestScreen for booking $bookingId');
    shownBookings.add(bookingId);
    
    context.pushNamed(
      AppRoutes.proIncomingRequestName,
      extra: data,
    );
  }

  static void updateStatus(String professionalId, String status) {
    FirebaseFirestore.instance
        .collection('job_requests')
        .doc('professional_$professionalId')
        .set({
      'status': status,
      'updated_at': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
    debugPrint('🔥 RealtimeJobService: Updated status to $status for professional_$professionalId');
  }

  static void stop() {
    _subscription?.cancel();
    _subscription = null;
    debugPrint('🔥 RealtimeJobService Stopped');
  }
}
