import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:pusher_channels_flutter/pusher_channels_flutter.dart';
import 'package:bellavella/core/config/app_config.dart';
import 'package:bellavella/core/models/data_models.dart';
import 'package:bellavella/core/router/professional_router.dart';
import 'package:bellavella/core/routes/app_routes.dart';
import 'package:bellavella/features/professional/controllers/dashboard_controller.dart';
import 'package:bellavella/features/professional/controllers/professional_profile_controller.dart';
import 'package:bellavella/features/professional/models/professional_models.dart';

class RealTimeService {
  static PusherChannelsFlutter? _pusher;
  static String? _currentChannel;

  static Future<void> init(String professionalId) async {
    if (_pusher != null) return;

    debugPrint('🔌 RealTimeService: Initializing for professional $professionalId via Reverb PUSHER');

    _pusher = PusherChannelsFlutter.getInstance();
    try {
      await _pusher!.init(
        apiKey: "local-key",
        cluster: "mt1",
        useTLS: false,
        onConnectionStateChange: _onConnectionStateChange,
        onError: _onError,
        onEvent: _onEvent,
        onSubscriptionSucceeded: _onSubscriptionSucceeded,
        onSubscriptionError: _onSubscriptionError,
      );

      await _pusher!.connect();

      _currentChannel = "professional.$professionalId";
      await _pusher!.subscribe(
        channelName: _currentChannel!,
      );

    } catch (e) {
      debugPrint("🔌 RealTimeService Error: $e");
    }
  }

  static void _onEvent(PusherEvent event) {
    debugPrint("🔔 RealTimeService Received Event: ${event.eventName}");
    debugPrint("EVENT RECEIVED: ${event.data}");
    
    try {
      if (event.data == null) return;
      
      final dataStr = event.data.toString();
      final decodedData = jsonDecode(dataStr);
      
      if (event.eventName == "StatusUpdated" || event.eventName == r"App\Events\StatusUpdated") {
         _handleStatusUpdated(decodedData);
      } else if (event.eventName == "JobUpdate" || event.eventName == r"App\Events\JobUpdate") {
         _handleJobUpdate(decodedData);
      }
    } catch (e) {
      debugPrint("❌ RealTimeService Parsing Error for ${event.eventName}: $e");
    }
  }

  static void _handleStatusUpdated(Map<String, dynamic> data) {
    final context = proNavigatorKey.currentContext;
    if (context != null) {
      final controller = Provider.of<ProfessionalProfileController>(context, listen: false);
      controller.updateRealtimeStatus(data);
    } else {
      debugPrint("⚠️ RealTimeService: Could not find navigator context for StatusUpdated dispatch.");
    }
  }

  static void _handleJobUpdate(dynamic data) {
    try {
      if (data is Map && data['booking'] != null) {
        final jobData = data['booking'];
        final job = ProfessionalBooking.fromJson(jobData);
        debugPrint('🔔 RealTimeService: Processing Job Update: ${job.id} (${job.status.name})');

        if (job.status == BookingStatus.assigned) {
          _showIncomingRequestPopup(jobData);
        } else if (job.status == BookingStatus.cancelled) {
          DashboardController.instance.clearJob();
        } else {
          DashboardController.instance.updateJob(job);
        }
      }
    } catch (e) {
      debugPrint('❌ RealTimeService: Error parsing job update: $e');
    }
  }

  static void _showIncomingRequestPopup(Map<String, dynamic> jobData) {
    final context = proNavigatorKey.currentContext;
    if (context == null) {
      debugPrint('⚠️ RealTimeService: Cannot show popup, navigator context is null.');
      return;
    }

    debugPrint('🚀 RealTimeService: Triggering Incoming Request Popup');
    
    context.pushNamed(
      AppRoutes.proIncomingRequestName,
      extra: jobData,
    );
  }

  static void _onConnectionStateChange(dynamic currentState, dynamic previousState) {
    debugPrint("🔌 Connection: $currentState");
  }

  static void _onError(String message, int? code, dynamic e) {
    debugPrint("🔌 Error: $message code: $code e: $e");
  }

  static void _onSubscriptionSucceeded(String channelName, dynamic data) {
    debugPrint("🔌 Subscribed to $channelName");
  }

  static void _onSubscriptionError(String message, dynamic e) {
    debugPrint("🔌 Subscription Error: $message");
  }

  static Future<void> dispose() async {
    if (_pusher != null && _currentChannel != null) {
      await _pusher!.unsubscribe(channelName: _currentChannel!);
      await _pusher!.disconnect();
    }
    _pusher = null;
    _currentChannel = null;
  }
}
