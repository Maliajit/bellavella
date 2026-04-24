import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:dart_pusher_channels/dart_pusher_channels.dart';
import 'package:bellavella/core/models/data_models.dart';
import 'package:bellavella/core/router/professional_router.dart';
import 'package:bellavella/core/routes/app_routes.dart';
import 'package:bellavella/features/professional/controllers/dashboard_controller.dart';
import 'package:bellavella/features/professional/controllers/professional_profile_controller.dart';
import 'package:bellavella/features/professional/models/professional_models.dart';

class RealTimeService {
  static PusherChannelsClient? _pusher;
  static String? _currentChannelName;
  static final List<StreamSubscription> _subscriptions = [];

  static Future<void> init(String professionalId) async {
    if (_pusher != null) return;

    debugPrint('🔌 RealTimeService: Initializing for professional $professionalId via DART_PUSHER_CHANNELS');

    // Use a custom host/port for Laravel Reverb
    // In production/APK, this should probably come from AppConfig or dart-define
    final options = PusherChannelsOptions.fromHost(
      scheme: 'ws',
      host: "192.168.1.6", // Using the IP from your build command for network access
      port: 8081,
      key: "local-key", // Your Pusher/Reverb key
      shouldSupplyMetadataQueries: true,
      metadata: PusherChannelsOptionsMetadata.byDefault(),
    );

    _pusher = PusherChannelsClient.websocket(
      options: options,
      connectionErrorHandler: (exception, trace, refresh) {
        debugPrint('🔌 RealTimeConnection Error: $exception');
        // Auto-refresh is usually handled by the client, but we can log it
      },
    );

    try {
      _currentChannelName = "professional.$professionalId";
      final channel = _pusher!.publicChannel(_currentChannelName!);

      // Binding multiple events
      _subscriptions.add(channel.bind("StatusUpdated").listen((event) => _onEvent(event)));
      _subscriptions.add(channel.bind(r"App\Events\StatusUpdated").listen((event) => _onEvent(event)));
      _subscriptions.add(channel.bind("JobUpdate").listen((event) => _onEvent(event)));
      _subscriptions.add(channel.bind(r"App\Events\JobUpdate").listen((event) => _onEvent(event)));

      _subscriptions.add(_pusher!.lifecycleStream.listen((state) {
        debugPrint("🔌 RealTime Connection: $state");
      }));

      await _pusher!.connect();

    } catch (e) {
      debugPrint("🔌 RealTimeService Error: $e");
    }
  }

  static void _onEvent(PusherChannelsReadEvent event) {
    debugPrint("🔔 RealTimeService Received Event: ${event.name}");
    debugPrint("EVENT DATA: ${event.data}");
    
    try {
      final dynamic rawData = event.data;
      if (rawData == null) return;

      final dynamic decodedData;
      if (rawData is String) {
        decodedData = jsonDecode(rawData);
      } else {
        decodedData = rawData;
      }
      
      if (event.name == "StatusUpdated" || event.name == r"App\Events\StatusUpdated") {
         _handleStatusUpdated(decodedData);
      } else if (event.name == "JobUpdate" || event.name == r"App\Events\JobUpdate") {
         _handleJobUpdate(decodedData);
      }
    } catch (e) {
      debugPrint("❌ RealTimeService Parsing Error for ${event.name}: $e");
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

  static Future<void> dispose() async {
    for (var sub in _subscriptions) {
      sub.cancel();
    }
    _subscriptions.clear();
    
    if (_pusher != null) {
      _pusher!.disconnect();
    }
    _pusher = null;
    _currentChannelName = null;
  }
}
