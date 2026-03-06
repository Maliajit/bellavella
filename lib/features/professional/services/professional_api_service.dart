import 'package:bellavella/core/services/api_service.dart';
import 'package:bellavella/core/services/token_manager.dart';
import 'package:bellavella/features/professional/models/professional_models.dart' as pro_models;
import 'package:bellavella/core/models/data_models.dart';
import 'package:image_picker/image_picker.dart';

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
    String? email,
    String? dob,
    String? gender,
    String? experience,
    String? languages,
    String? address,
    String? pincode,
    String? state,
    String? aadharNumber,
    String? panNumber,
    XFile? aadharFront,
    XFile? aadharBack,
    XFile? panPhoto,
    XFile? selfie,
    String? referralCode,
  }) async {
    final Map<String, String> fields = {
      'mobile': mobile,
      'name': name,
      'category': category,
      'city': city,
      if (email != null) 'email': email,
      if (dob != null) 'dob': dob,
      if (gender != null) 'gender': gender,
      if (experience != null) 'experience': experience,
      if (languages != null) 'languages': languages,
      if (address != null) 'address': address,
      if (pincode != null) 'pincode': pincode,
      if (state != null) 'state': state,
      if (aadharNumber != null) 'aadhar': aadharNumber,
      if (panNumber != null) 'pan': panNumber,
      if (referralCode != null) 'referral_code': referralCode,
    };

    final Map<String, XFile> files = {
      if (aadharFront != null) 'aadhar_front': aadharFront,
      if (aadharBack != null) 'aadhar_back': aadharBack,
      if (panPhoto != null) 'pan_photo': panPhoto,
      if (selfie != null) 'selfie': selfie,
    };

    if (files.isEmpty) {
      final response = await ApiService.post('$_prefix/register', fields);
      if (response['success'] == true && response['data'] != null) {
        final token = response['data']['access_token'];
        if (token != null) await TokenManager.setToken(token);
      }
      return response;
    }

    final response = await ApiService.multipart('$_prefix/register', fields, files);
    if (response['success'] == true && response['data'] != null) {
      final token = response['data']['access_token'];
      if (token != null) await TokenManager.setToken(token);
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

  static Future<Map<String, dynamic>> toggleAvailability(bool isOnline) async {
    return await ApiService.post('$_prefix/toggle-availability', {'is_online': isOnline});
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

  static Future<List<pro_models.ProfessionalBooking>> getBookings() async {
    final response = await ApiService.get('$_prefix/bookings');
    if (response['success'] == true) {
      return (response['data'] as List)
          .map((i) => pro_models.ProfessionalBooking.fromJson(i))
          .toList();
    }
    throw Exception(response['message'] ?? 'Failed to load bookings');
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
    return await ApiService.put('$_prefix/profile', data);
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

  static Future<Map<String, dynamic>> updateServiceArea(Map<String, dynamic> data) async {
    return await updateProfile(data);
  }

  static Future<Map<String, dynamic>> updateWorkingHours(Map<String, dynamic> data) async {
    return await updateProfile(data);
  }

  static Future<Map<String, dynamic>> updateBankDetails(Map<String, dynamic> data) async {
    return await updateProfile({'payout': data});
  }

  static Future<Map<String, dynamic>> updateUPIDetails(Map<String, dynamic> data) async {
    return await updateProfile({'payout': data});
  }

  static Future<Map<String, dynamic>> changePassword(String currentPassword, String newPassword) async {
    return await ApiService.put('$_prefix/change-password', {
      'current_password': currentPassword,
      'new_password': newPassword,
    });
  }

  static Future<Map<String, dynamic>> uploadPortfolio(Map<String, dynamic> data) async {
    return await ApiService.post('$_prefix/portfolio/upload', data);
  }

  // --- Kit Store ---
  static Future<List<Map<String, dynamic>>> getKitProducts() async {
    final response = await ApiService.get('$_prefix/kit-products');
    if (response['success'] == true) {
      return List<Map<String, dynamic>>.from(response['data']);
    }
    throw Exception(response['message'] ?? 'Failed to load kit products');
  }

  static Future<Map<String, dynamic>> placeKitOrder(int kitProductId, int quantity, {String? notes}) async {
    return await ApiService.post('$_prefix/orders', {
      'kit_product_id': kitProductId,
      'quantity': quantity,
      'notes': notes,
    });
  }

  static Future<List<Map<String, dynamic>>> getKitOrders() async {
    final response = await ApiService.get('$_prefix/orders');
    if (response['success'] == true) {
      return List<Map<String, dynamic>>.from(response['data']);
    }
    throw Exception(response['message'] ?? 'Failed to load kit orders');
  }

  static Future<Map<String, dynamic>> getKitOrderDetails(int id) async {
    final response = await ApiService.get('$_prefix/orders/$id');
    if (response['success'] == true) {
      return Map<String, dynamic>.from(response['data']);
    }
    throw Exception(response['message'] ?? 'Failed to load order details');
  }

  static Future<Map<String, dynamic>> verifyKitPayment({
    required int kitProductId,
    required int quantity,
    required String paymentId,
    String? razorpayOrderId,
    String? paymentMethod,
    String? notes,
  }) async {
    return await ApiService.post('$_prefix/payment/verify', {
      'kit_product_id': kitProductId,
      'quantity': quantity,
      'payment_id': paymentId,
      'razorpay_order_id': razorpayOrderId,
      'payment_method': paymentMethod ?? 'UPI',
      'notes': notes,
    });
  }

  // --- Refer & Earn ---
  static Future<Map<String, dynamic>> getReferralStats() async {
    final response = await ApiService.get('$_prefix/referrals');
    if (response['success'] == true) {
      return response['data'];
    }
    throw Exception(response['message'] ?? 'Failed to load referral stats');
  }
}
