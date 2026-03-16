import 'dart:async';
import 'package:image_picker/image_picker.dart';
import 'package:flutter/material.dart';
import '../services/professional_api_service.dart';
import '../services/real_time_service.dart';
import 'package:bellavella/core/models/data_models.dart';

class ProfessionalProfileController extends ChangeNotifier {
  Professional? _profile;
  bool _isLoading = false;
  String? _error;
  bool _isOnline = false;
  Timer? _heartbeatTimer;

  Professional? get profile => _profile;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get isOnline => _isOnline;

  Future<void> fetchProfile() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _profile = await ProfessionalApiService.getProfile();
      if (_profile != null) {
        _isOnline = _profile!.isOnline; // Sync with DB state
        if (_isOnline) _startHeartbeat();

        // Initialize Real-time WebSocket Service
        RealTimeService.dispose(); // Clear any existing
        RealTimeService.init(_profile!.id);
      }
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> toggleAvailability(bool online) async {
    final previous = _isOnline;
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
      } else {
        _isOnline = previous;
        _error = res['message'];
        notifyListeners();
      }
    } catch (e) {
      _isOnline = previous;
      _error = e.toString();
      notifyListeners();
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
    // Initial update
    ProfessionalApiService.updateOnlineStatus();
  }

  @override
  void dispose() {
    _heartbeatTimer?.cancel();
    RealTimeService.dispose();
    super.dispose();
  }

  Future<bool> updateProfile(Map<String, dynamic> data) async {
    return _performUpdate(() => ProfessionalApiService.updateProfile(data));
  }

  Future<bool> updateServiceArea(Map<String, dynamic> data) async {
    return _performUpdate(() => ProfessionalApiService.updateServiceArea(data));
  }

  Future<bool> updateWorkingHours(Map<String, dynamic> data) async {
    return _performUpdate(() => ProfessionalApiService.updateWorkingHours(data));
  }

  Future<bool> updateBankDetails(Map<String, String> data, {XFile? proofImage}) async {
    return _performUpdate(() => ProfessionalApiService.updateBankDetails(data, proofImage: proofImage));
  }

  Future<bool> updateUPIDetails(Map<String, String> data, {XFile? screenshot}) async {
    return _performUpdate(() => ProfessionalApiService.updateUPIDetails(data, screenshot: screenshot));
  }

  Future<bool> changePassword(String cur, String next) async {
    return _performUpdate(() => ProfessionalApiService.changePassword(cur, next));
  }

  Future<bool> uploadProfileImage(XFile image) async {
    return _performUpdate(() => ProfessionalApiService.uploadProfileImage(image));
  }

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
}
