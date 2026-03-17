import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class RealtimeJobService {
  static StreamSubscription<DocumentSnapshot>? _subscription;
  static String? _lastBookingId;

  static void start(String professionalId, GlobalKey<NavigatorState> navKey) {
    // Cancel existing subscription if any
    _subscription?.cancel();

    _subscription = FirebaseFirestore.instance
        .collection('job_requests')
        .doc('professional_$professionalId')
        .snapshots()
        .listen((snapshot) {
      if (!snapshot.exists) return;

      final data = snapshot.data() as Map<String, dynamic>?;
      if (data == null) return;

      if (data['status'] == 'pending') {
        // Prevent duplicate popup for the same booking
        final bookingId = data['booking_id']?.toString();
        if (_lastBookingId == bookingId) return;

        _lastBookingId = bookingId;
        _showJobPopup(navKey, data);
      } else if (data['status'] == 'idle') {
        // Reset last booking ID when status goes to idle
        _lastBookingId = null;
      }
    });
  }

  static void _showJobPopup(GlobalKey<NavigatorState> navKey, Map<String, dynamic> data) {
    final context = navKey.currentContext;
    if (context == null) return;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        title: const Text("New Service Request", style: TextStyle(fontWeight: FontWeight.bold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(data['service'] ?? "New Job Assigned", style: const TextStyle(fontSize: 18, color: Colors.blue)),
            const SizedBox(height: 10),
            if (data['client_name'] != null) Text("Client: ${data['client_name']}"),
            if (data['location'] != null) Text("Location: ${data['location']}"),
            if (data['price'] != null) Text("Earnings: ₹${data['price']}"),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              // Navigation to detail screen happens after the user responds to the popup
              // The Accept/Reject logic is handled by the API calls which then trigger status updates
            },
            child: const Text("CLOSE", style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              // Logic to handle accept API call
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
            child: const Text("ACCEPT", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  static void stop() {
    _subscription?.cancel();
    _subscription = null;
  }
}
