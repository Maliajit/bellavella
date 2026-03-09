import 'package:image_picker/image_picker.dart';
import 'package:flutter/material.dart';
import '../services/professional_api_service.dart';
import 'package:bellavella/core/models/data_models.dart';

class ProfessionalProfileController extends ChangeNotifier {
  Professional? _profile;
  bool _isLoading = false;
  String? _error;

  Professional? get profile => _profile;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> fetchProfile() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _profile = await ProfessionalApiService.getProfile();
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
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

  Future<bool> updateBankDetails(Map<String, dynamic> data) async {
    return _performUpdate(() => ProfessionalApiService.updateBankDetails(data));
  }

  Future<bool> updateUPIDetails(Map<String, dynamic> data) async {
    return _performUpdate(() => ProfessionalApiService.updateUPIDetails(data));
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
