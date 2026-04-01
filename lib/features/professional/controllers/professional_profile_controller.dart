import 'dart:async';
import 'package:image_picker/image_picker.dart';
import 'package:flutter/material.dart';
import '../services/professional_api_service.dart';
import '../services/real_time_service.dart';
import 'package:bellavella/core/models/data_models.dart';

class ProfessionalProfileController extends ChangeNotifier with WidgetsBindingObserver {
  Professional? _profile;
  bool _isLoading = false;
  String? _error;
  bool _isOnline = false;
  Timer? _heartbeatTimer;

  ProfessionalProfileController() {
    // 📡 REGISTER LIFECYCLE OBSERVER: For sync-on-resume
    WidgetsBinding.instance.addObserver(this);
  }

  Professional? get profile => _profile;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get isOnline => _isOnline;

  // 🔄 SYNC ON RESUME: Elite reliability for bad networks
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      debugPrint('📡 App Resumed: Refreshing professional profile for state sync.');
      fetchProfile();
    }
  }

  // ⏱️ MIDNIGHT RESET: Prevent "Ghost Suspensions"
  void checkDailyReset() {
    if (_profile == null) return;
    
    final String todayString = DateTime.now().toString().split(' ')[0];
    final String? lastActivityDate = _profile!.lastRejectDate?.split(' ')[0];

    if (lastActivityDate != null && lastActivityDate != todayString) {
      debugPrint('🌑 Midnight Reset: Clearing local rejection stats for new day ($todayString)');
      _profile = _profile!.copyWith(
        rejectCount: 0,
        isSuspended: false,
        lastRejectDate: todayString,
      );
      notifyListeners();
    }
  }

  Future<void> fetchProfile() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final newProfile = await ProfessionalApiService.getProfile();
      if (newProfile != null) {
        // ... (existing online sync logic)
        if (_isOnline) {
          debugPrint('🌐 ProfessionalProfileController: Syncing profile while ONLINE. (Backend says: ${newProfile.isOnline})');
        } else {
          _isOnline = newProfile.isOnline;
          debugPrint('🌐 ProfessionalProfileController: Syncing profile while OFFLINE. Updated to: $_isOnline');
        }

        _profile = newProfile;
        
        // ⏱️ Run Daily Reset check right after fetch
        checkDailyReset();
        
        if (_isOnline) _startHeartbeat();

        // Initialize Real-time WebSocket Service
        RealTimeService.dispose(); 
        RealTimeService.init(_profile!.id);
      }
    } catch (e) {
      debugPrint('❌ ProfessionalProfileController Search Error: $e');
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // ... (toggleAvailability rest remains same)
  // (updateRejectionStats rest remains same)

  @override
  void dispose() {
    // 📡 UNREGISTER OBSERVER: Prevent leaks
    WidgetsBinding.instance.removeObserver(this);
    _heartbeatTimer?.cancel();
    RealTimeService.dispose();
    super.dispose();
  }
  
  // (Full file content continued for context)
  Future<bool> toggleAvailability(bool online) async {
    debugPrint('🔘 ProfessionalProfileController: Toggling Availability to: $online');
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
          _heartbeatTimer?.cancel();
        }
        await fetchProfile(); // Refresh profile to get updated stats
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
    _heartbeatTimer?.cancel();
    _heartbeatTimer = Timer.periodic(const Duration(seconds: 60), (timer) {
      if (_isOnline) {
        ProfessionalApiService.updateOnlineStatus();
      } else {
        timer.cancel();
      }
    });
    ProfessionalApiService.updateOnlineStatus();
  }

  Future<bool> updateProfile(Map<String, dynamic> data) async => _performUpdate(() => ProfessionalApiService.updateProfile(data));
  Future<bool> updateServiceArea(Map<String, dynamic> data) async => _performUpdate(() => ProfessionalApiService.updateServiceArea(data));
  Future<bool> updateWorkingHours(Map<String, dynamic> data) async => _performUpdate(() => ProfessionalApiService.updateWorkingHours(data));
  Future<bool> updateBankDetails(Map<String, String> data, {XFile? proofImage}) async => _performUpdate(() => ProfessionalApiService.updateBankDetails(data, proofImage: proofImage));
  Future<bool> updateUPIDetails(Map<String, String> data, {XFile? screenshot}) async => _performUpdate(() => ProfessionalApiService.updateUPIDetails(data, screenshot: screenshot));
  Future<bool> changePassword(String cur, String next) async => _performUpdate(() => ProfessionalApiService.changePassword(cur, next));
  Future<bool> uploadProfileImage(XFile image) async => _performUpdate(() => ProfessionalApiService.uploadProfileImage(image));

  Future<bool> _performUpdate(Future<Map<String, dynamic>> Function() updateCall) async {
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
    if (_profile == null) return;
    if (_profile!.rejectCount != count || _profile!.isSuspended != suspended) {
      debugPrint('🔄 Synchronizing Rejection Stats: count=$count, suspended=$suspended');
      _profile = _profile!.copyWith(rejectCount: count, isSuspended: suspended);
      notifyListeners();
    }
  }
}
