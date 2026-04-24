import 'dart:async';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../services/professional_api_service.dart';
import '../models/professional_models.dart';
import 'package:bellavella/core/models/data_models.dart';

class ProfessionalProfileController extends ChangeNotifier {
  Professional? _profile;
  bool _isLoading = false;
  String? _error;
  bool _isOnline = false;
  
  // Authoritative Countdown State
  int _remainingSeconds = 0;
  DateTime? _lastSyncTime;
  Timer? _heartbeatTimer;
  Timer? _localDecrementTimer;

  Professional? get profile => _profile;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get isOnline => _isOnline;
  int get remainingSeconds => _remainingSeconds;

  ProfessionalProfileController() {
    _startLocalDecrement();
  }

  @override
  void dispose() {
    _heartbeatTimer?.cancel();
    _localDecrementTimer?.cancel();
    super.dispose();
  }

  /// Authoritative Local Ticker: Ticks down locally for UI smoothness,
  /// but will be corrected by server heartbeats.
  void _startLocalDecrement() {
    _localDecrementTimer?.cancel();
    _localDecrementTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_isOnline && _remainingSeconds > 0) {
        _remainingSeconds--;
        notifyListeners();
      }
    });
  }

  Future<void> fetchProfile() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final res = await ProfessionalApiService.getProfile();
      _profile = res;
      _isOnline = _profile?.isOnline ?? false;
      
      // Authoritative initial sync
      final stats = await ProfessionalApiService.getDashboardStats();
      _remainingSeconds = stats.remainingSeconds;
      _lastSyncTime = DateTime.now();

      if (_isOnline) {
        _startHeartbeat();
      }
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> toggleAvailability(bool value) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final res = await ProfessionalApiService.toggleAvailability(value);
      if (res['success'] == true) {
        _isOnline = value;
        
        // Sync authoritative time from the toggle response
        if (res['data'] != null && res['data']['remaining_seconds'] != null) {
          _remainingSeconds = int.tryParse(res['data']['remaining_seconds'].toString()) ?? _remainingSeconds;
          _lastSyncTime = DateTime.now();
        }

        if (_isOnline) {
          _startHeartbeat();
        } else {
          _heartbeatTimer?.cancel();
        }
        return true;
      }
      _error = res['message'] ?? 'Failed to update status';
      return false;
    } catch (e) {
      _error = e.toString();
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void _startHeartbeat() {
    _heartbeatTimer?.cancel();
    _heartbeatTimer = Timer.periodic(const Duration(seconds: 60), (timer) async {
      if (_isOnline) {
        final res = await ProfessionalApiService.updateOnlineStatus();
        if (res != null && res['remaining_seconds'] != null) {
            _remainingSeconds = int.tryParse(res['remaining_seconds'].toString()) ?? _remainingSeconds;
            _lastSyncTime = DateTime.now();
            notifyListeners();
        }
      } else {
        timer.cancel();
      }
    });
    // Fire once immediately
    ProfessionalApiService.updateOnlineStatus();
  }

  // --- Profile Management ---

  Future<bool> updateProfile(Map<String, dynamic> data) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final res = await ProfessionalApiService.updateProfile(data);
      if (res['success'] == true) {
        await fetchProfile(); // Refresh
        return true;
      }
      _error = res['message'] ?? 'Failed to update profile';
      return false;
    } catch (e) {
      _error = e.toString();
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> uploadProfileImage(XFile image) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final res = await ProfessionalApiService.uploadProfileImage(image);
      if (res['success'] == true) {
        await fetchProfile();
        return true;
      }
      _error = res['message'] ?? 'Failed to upload image';
      return false;
    } catch (e) {
      _error = e.toString();
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> updateBankDetails(Map<String, String> data, {XFile? proofImage}) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final res = await ProfessionalApiService.updateBankDetails(data, proofImage: proofImage);
      if (res['success'] == true) {
        await fetchProfile();
        return true;
      }
      _error = res['message'] ?? 'Failed to update bank details';
      return false;
    } catch (e) {
      _error = e.toString();
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> updateUPIDetails(Map<String, String> data, {XFile? screenshot}) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final res = await ProfessionalApiService.updateUPIDetails(data, screenshot: screenshot);
      if (res['success'] == true) {
        await fetchProfile();
        return true;
      }
      _error = res['message'] ?? 'Failed to update UPI details';
      return false;
    } catch (e) {
      _error = e.toString();
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> changePassword(String currentPassword, String newPassword) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final res = await ProfessionalApiService.changePassword(currentPassword, newPassword);
      if (res['success'] == true) return true;
      _error = res['message'] ?? 'Failed to change password';
      return false;
    } catch (e) {
      _error = e.toString();
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> updateServiceArea(Map<String, dynamic> data) async {
    return await updateProfile(data);
  }

  Future<bool> updateWorkingHours(Map<String, dynamic> data) async {
    return await updateProfile(data);
  }

  // --- Realtime & Rejections ---

  void updateRejectionStats(int count, bool isSuspended) {
    if (_profile != null) {
      _profile = _profile!.copyWith(
        rejectCount: count,
        status: isSuspended ? 'suspended' : _profile!.status,
      );
      notifyListeners();
    }
  }

  void updateRealtimeStatus(Map<String, dynamic> data) {
    if (data['is_online'] != null) {
      _isOnline = data['is_online'] == true || data['is_online'] == 1;
      if (_isOnline) {
        _startHeartbeat();
      } else {
        _heartbeatTimer?.cancel();
      }
    }
    if (data['remaining_seconds'] != null) {
      _remainingSeconds = int.tryParse(data['remaining_seconds'].toString()) ?? _remainingSeconds;
    }
    notifyListeners();
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }
}
