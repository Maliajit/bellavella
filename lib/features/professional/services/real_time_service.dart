import 'package:laravel_echo/laravel_echo.dart';
import 'package:pusher_client/pusher_client.dart';
import 'package:bellavella/core/services/token_manager.dart';
import 'package:bellavella/features/professional/controllers/dashboard_controller.dart';
import 'package:bellavella/features/professional/models/professional_models.dart';
import 'package:bellavella/core/models/data_models.dart';
import 'package:bellavella/core/config/app_config.dart';
import 'package:bellavella/core/router/professional_router.dart';
import 'package:bellavella/core/routes/app_routes.dart';
import 'package:flutter/foundation.dart';
import 'package:go_router/go_router.dart';

class RealTimeService {
  static Echo? _echo;
  static PusherClient? _pusher;

  static void init(String professionalId) {
    if (_echo != null) return;

    final token = TokenManager.token;
    if (token == null) {
      debugPrint('🔌 RealTimeService: No token found. Delaying init.');
      return;
    }

    debugPrint('🔌 RealTimeService: Initializing for professional $professionalId');

    // Reverb configuration - dynamically loaded from AppConfig
    final String host = AppConfig.host;
    final int port = 8080; // Reverb WebSockets port
    
    final options = PusherOptions(
      host: host,
      wsPort: port,
      encrypted: false,
      cluster: 'mt1',
      auth: PusherAuth(
        '${AppConfig.baseUrl}/broadcasting/auth',
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
        },
      ),
    );

    _pusher = PusherClient(
      'npbtsflanssofxfh79bf', // REVERB_APP_KEY from .env
      options,
      autoConnect: true,
      enableLogging: true,
    );

    _echo = Echo(
      client: _pusher,
      broadcaster: EchoBroadcasterType.Pusher,
    );

    // Listen to professional private channel
    _echo!.private('professionals.$professionalId')
      .listen('.JobUpdate', (data) {
        debugPrint('🔔 RealTimeService: JobUpdate Received!');
        _handleJobUpdate(data);
      });

    _pusher!.onConnectionStateChange((state) {
      debugPrint('🔌 RealTimeService: Connection State: ${state?.currentState}');
    });

    _pusher!.onConnectionError((error) {
      debugPrint('🔌 RealTimeService: Connection Error: ${error?.message}');
    });
  }

  static void _handleJobUpdate(dynamic data) {
    try {
      if (data is Map && data['booking'] != null) {
        final jobData = data['booking'];
        final job = ProfessionalBooking.fromJson(jobData);
        debugPrint('🔔 RealTimeService: Processing Job Update: ${job.id} (${job.status.name})');

        if (job.status == BookingStatus.assigned) {
          // NEW ASSIGNMENT -> Show Popup (Uber style)
          _showIncomingRequestPopup(jobData);
        } else if (job.status == BookingStatus.cancelled || job.status == BookingStatus.completed) {
          DashboardController.instance.clearJob();
        } else {
          // Accepted, OnTheWay, Arrived, Started, etc.
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
    
    // GoRouter navigation using the proNavigatorKey context
    context.pushNamed(
      AppRoutes.proIncomingRequestName,
      extra: jobData,
    );
  }

  static void dispose() {
    _echo?.disconnect();
    _pusher?.disconnect();
    _echo = null;
    _pusher = null;
  }
}
