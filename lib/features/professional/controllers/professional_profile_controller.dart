import 'dart:async';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import 'package:bellavella/core/config/app_config.dart';
import 'package:bellavella/core/models/data_models.dart';
import 'package:bellavella/core/router/professional_router.dart';
import 'package:bellavella/core/routes/app_routes.dart';
import 'package:bellavella/core/services/realtime_job_service.dart';
import 'package:bellavella/core/services/token_manager.dart';
import 'package:bellavella/features/professional/controllers/dashboard_controller.dart';
import 'package:go_router/go_router.dart';

import '../services/professional_api_service.dart';
import '../services/real_time_service.dart';

class ProfessionalProfileController extends ChangeNotifier
    with WidgetsBindingObserver {
  Professional? _profile;
  bool _isLoading = false;
  String? _error;
  bool _isOnline = false;
  bool _isSuspendedPreviously = false;
  String? _suspensionReason;
  Timer? _heartbeatTimer;
  Timer? _safetySyncTimer;

  ProfessionalProfileController() {
    WidgetsBinding.instance.addObserver(this);
    _startSafetySync();

    if (TokenManager.token != null && AppConfig.isProfessional) {
      Future.microtask(fetchProfile);
    }
  }

  Professional? get profile => _profile;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get isOnline => _isOnline;
  bool get isSuspendedPreviously => _isSuspendedPreviously;
  bool get isSuspended => _profile?.isSuspended == true || _isSuspendedPreviously;
  String? get suspensionReason => _suspensionReason ?? _profile?.suspensionReason;

  void _startSafetySync() {
    _safetySyncTimer?.cancel();
    _safetySyncTimer = Timer.periodic(const Duration(minutes: 2), (timer) {
      if (TokenManager.token != null && AppConfig.isProfessional && !isSuspended) {
        debugPrint('Safety Sync: polling backend for professional state.');
        fetchProfile();
      }
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed &&
        TokenManager.token != null &&
        AppConfig.isProfessional) {
      debugPrint('App resumed: refreshing professional profile.');
      fetchProfile();
    }
  }

  void checkDailyReset() {
    if (_profile == null) {
      return;
    }

    final String todayString = DateTime.now().toString().split(' ')[0];
    final String? lastActivityDate = _profile!.lastRejectDate?.split(' ')[0];

    if (lastActivityDate != null && lastActivityDate != todayString) {
      debugPrint('Midnight reset: clearing local rejection stats.');
      _profile = _profile!.copyWith(
        rejectCount: 0,
        lastRejectDate: todayString,
      );
      notifyListeners();
    }
  }

  Future<void> fetchProfile() async {
    if (TokenManager.token == null) {
      return;
    }

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final profile = await ProfessionalApiService.getProfile();
      final wasSuspended = isSuspended;

      _profile = profile;
      _suspensionReason = profile.suspensionReason;
      _isSuspendedPreviously = profile.isSuspended;

      if (profile.isSuspended) {
        forceSuspendFlow(reason: profile.suspensionReason, notify: false);
      } else if (wasSuspended) {
        exitSuspendFlow(notify: false);
      } else {
        _isOnline = profile.isOnline;
        _startSafetySync();
        if (_isOnline) {
          _startHeartbeat();
        } else {
          stopHeartbeat();
        }
        _startRealtimeServices();
      }

      checkDailyReset();
    } catch (e) {
      debugPrint('ProfessionalProfileController fetch error: $e');
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void forceSuspendFlow({String? reason, bool notify = true}) {
    debugPrint('Account suspended: forcing professional shutdown flow.');
    _isOnline = false;
    _isSuspendedPreviously = true;
    _suspensionReason = reason ?? _suspensionReason ?? _profile?.suspensionReason;
    _profile = _profile?.copyWith(
      isOnline: false,
      isSuspended: true,
      suspensionReason: _suspensionReason,
    );

    stopHeartbeat();
    cancelAllTimers();
    stopLocationTracking();
    clearActiveBooking();

    if (notify) {
      notifyListeners();
    }
  }

  void exitSuspendFlow({bool notify = true}) {
    debugPrint('Account restored: exiting suspended state.');
    _isOnline = false;
    _isSuspendedPreviously = false;
    _suspensionReason = null;
    _profile = _profile?.copyWith(
      isOnline: false,
      isSuspended: false,
      suspensionReason: null,
    );

    stopHeartbeat();
    _startSafetySync();
    _startRealtimeServices();

    final context = proNavigatorKey.currentContext;
    if (context != null) {
      context.go(AppRoutes.proDashboard);
    } else {
      professionalRouter.go(AppRoutes.proDashboard);
    }

    if (notify) {
      notifyListeners();
    }
  }

  void stopHeartbeat() {
    _heartbeatTimer?.cancel();
    _heartbeatTimer = null;
  }

  void cancelAllTimers() {
    stopHeartbeat();
    _safetySyncTimer?.cancel();
    _safetySyncTimer = null;
  }

  void stopLocationTracking() {
    RealTimeService.dispose();
    RealtimeJobService.stop();
    RealtimeJobService.clearCache();
  }

  void clearActiveBooking() {
    DashboardController.instance.clearJob();
  }

  void _startRealtimeServices() {
    if (_profile == null || isSuspended) {
      return;
    }

    RealTimeService.dispose();
    RealTimeService.init(_profile!.id);
  }

  Future<void> logout() async {
    cancelAllTimers();
    stopLocationTracking();
    clearActiveBooking();
    _profile = null;
    _error = null;
    _isOnline = false;
    _isSuspendedPreviously = false;
    _suspensionReason = null;
    await TokenManager.clearProfessionalToken();
    notifyListeners();
  }

  Future<bool> toggleAvailability(bool online) async {
    debugPrint('ProfessionalProfileController: toggling availability to $online');
    final previous = _isOnline;
    _error = null;
    _isOnline = online;
    notifyListeners();

    try {
      final res = await ProfessionalApiService.toggleAvailability(online);
      if (res['success'] == true) {
        if (online) {
          _startHeartbeat();
        } else {
          stopHeartbeat();
        }
        await fetchProfile();
        return true;
      } else {
        _isOnline = previous;
        _error = res['message']?.toString() ?? 'Failed to update availability';
        notifyListeners();
        return false;
      }
    } catch (e) {
      _isOnline = previous;
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  void _startHeartbeat() {
    stopHeartbeat();
    _heartbeatTimer = Timer.periodic(const Duration(seconds: 60), (timer) {
      if (_isOnline && !isSuspended) {
        ProfessionalApiService.updateOnlineStatus();
      } else {
        timer.cancel();
      }
    });
    ProfessionalApiService.updateOnlineStatus();
  }

  Future<bool> updateProfile(Map<String, dynamic> data) async =>
      _performUpdate(() => ProfessionalApiService.updateProfile(data));

  Future<bool> updateServiceArea(Map<String, dynamic> data) async =>
      _performUpdate(() => ProfessionalApiService.updateServiceArea(data));

  Future<bool> updateWorkingHours(Map<String, dynamic> data) async =>
      _performUpdate(() => ProfessionalApiService.updateWorkingHours(data));

  Future<bool> updateBankDetails(
    Map<String, String> data, {
    XFile? proofImage,
  }) async => _performUpdate(
        () => ProfessionalApiService.updateBankDetails(
          data,
          proofImage: proofImage,
        ),
      );

  Future<bool> updateUPIDetails(
    Map<String, String> data, {
    XFile? screenshot,
  }) async => _performUpdate(
        () => ProfessionalApiService.updateUPIDetails(
          data,
          screenshot: screenshot,
        ),
      );

  Future<bool> changePassword(String cur, String next) async =>
      _performUpdate(() => ProfessionalApiService.changePassword(cur, next));

  Future<bool> uploadProfileImage(XFile image) async =>
      _performUpdate(() => ProfessionalApiService.uploadProfileImage(image));

  Future<bool> _performUpdate(
    Future<Map<String, dynamic>> Function() updateCall,
  ) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      final response = await updateCall();
      if (response['success'] == true) {
        await fetchProfile();
        return true;
      } else {
        _error = response['message'] ?? 'Update failed';
        return false;
      }
    } catch (e) {
      _error = e.toString();
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void updateRejectionStats(int count, bool suspended) {
    if (_profile == null) {
      return;
    }

    if (_profile!.rejectCount != count || _profile!.isSuspended != suspended) {
      debugPrint(
        'Synchronizing rejection stats: count=$count, suspended=$suspended',
      );
      _profile = _profile!.copyWith(
        rejectCount: count,
        isSuspended: suspended,
      );
      if (suspended) {
        forceSuspendFlow(notify: false);
      }
      notifyListeners();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    cancelAllTimers();
    stopLocationTracking();
    super.dispose();
  }
}
