import 'package:bellavella/core/services/api_service.dart';
import 'package:bellavella/core/services/token_manager.dart';
import 'package:bellavella/features/professional/models/professional_models.dart' as pro_models;
import 'package:bellavella/core/models/data_models.dart';

class ProfessionalApiService {
  static const String _prefix = '/professional';

  // --- Auth ---
  static Future<Map<String, dynamic>> sendOtp(String mobile) async {
    return await ApiService.post('$_prefix/send-otp', {
      'mobile': mobile,
    });
  }

  static Future<Map<String, dynamic>> verifyOtp(String mobile, String otp) async {
    final response = await ApiService.post('$_prefix/verify-otp', {
      'mobile': mobile,
      'otp': otp,
    });
    
    if (response['success'] == true && response['data'] != null) {
      final token = response['data']['access_token'];
      if (token != null) {
        await TokenManager.setToken(token);
      }
    }
    
    return response;
  }

  static Future<Map<String, dynamic>> register({
    required String mobile,
    required String name,
    required String category,
    required String city,
  }) async {
    final response = await ApiService.post('$_prefix/register', {
      'mobile': mobile,
      'name': name,
      'category': category,
      'city': city,
    });

    if (response['success'] == true && response['data'] != null) {
      final token = response['data']['access_token'];
      if (token != null) {
        await TokenManager.setToken(token);
      }
    }

    return response;
  }

  // --- Dashboard ---
  static Future<pro_models.ProfessionalDashboardStats> getDashboardStats() async {
    final response = await ApiService.get('$_prefix/dashboard');
    if (response['success'] == true) {
      return pro_models.ProfessionalDashboardStats.fromJson(response['data']);
    }
    throw Exception(response['message'] ?? 'Failed to load dashboard stats');
  }

  static Future<Map<String, dynamic>> toggleAvailability() async {
    return await ApiService.post('$_prefix/toggle-availability', {});
  }

  // --- Bookings & Jobs ---
  static Future<List<pro_models.ProfessionalBooking>> getBookingRequests() async {
    final response = await ApiService.get('$_prefix/booking-requests');
    if (response['success'] == true) {
      return (response['data'] as List)
          .map((i) => pro_models.ProfessionalBooking.fromJson(i))
          .toList();
    }
    throw Exception(response['message'] ?? 'Failed to load booking requests');
  }

  static Future<Map<String, dynamic>> acceptBooking(String id) async {
    return await ApiService.post('$_prefix/bookings/$id/accept', {});
  }

  static Future<Map<String, dynamic>> jobArrived(String id) async {
    return await ApiService.post('$_prefix/jobs/$id/arrived', {});
  }

  static Future<Map<String, dynamic>> jobStartService(String id) async {
    return await ApiService.post('$_prefix/jobs/$id/start-service', {});
  }

  static Future<Map<String, dynamic>> jobComplete(String id) async {
    return await ApiService.post('$_prefix/jobs/$id/complete', {});
  }

  // --- Wallet ---
  static Future<pro_models.ProfessionalWallet> getWallet() async {
    final response = await ApiService.get('$_prefix/wallet');
    if (response['success'] == true) {
      return pro_models.ProfessionalWallet.fromJson(response['data']);
    }
    throw Exception(response['message'] ?? 'Failed to load wallet');
  }

  static Future<Map<String, dynamic>> requestWithdrawal(double amount, String method) async {
    return await ApiService.post('$_prefix/request-withdrawal', {
      'amount': amount,
      'payment_method': method,
    });
  }

  // --- Profile ---
  static Future<Professional> getProfile() async {
    final response = await ApiService.get('$_prefix/profile');
    if (response['success'] == true) {
      return Professional.fromJson(response['data']);
    }
    throw Exception(response['message'] ?? 'Failed to load profile');
  }

  // Note: Profile update usually requires multipart for images, 
  // ApiService might need extension if it doesn't support multipart.
  // For now, following the simple POST structure.
  static Future<Map<String, dynamic>> updateProfile(Map<String, dynamic> data) async {
    return await ApiService.post('$_prefix/profile', data);
  }

  // --- Notifications ---
  static Future<List<Map<String, dynamic>>> getNotifications() async {
    final response = await ApiService.get('$_prefix/notifications');
    if (response['success'] == true) {
      return List<Map<String, dynamic>>.from(response['data']);
    }
    throw Exception(response['message'] ?? 'Failed to load notifications');
  }

  static Future<Map<String, dynamic>> markAllNotificationsRead() async {
    return await ApiService.post('$_prefix/notifications/read-all', {});
  }
}
