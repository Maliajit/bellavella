import 'package:flutter/foundation.dart';
import 'package:bellavella/core/services/api_service.dart';
import 'package:bellavella/core/services/token_manager.dart';
import 'package:bellavella/features/professional/models/professional_models.dart' as pro_models;
import 'package:bellavella/features/professional/models/professional_models.dart';
import 'package:bellavella/core/models/data_models.dart';
import 'package:image_picker/image_picker.dart';

class ProfessionalApiService {
  static const String _prefix = '/professional';

  static Future<Map<String, dynamic>> updateFcmToken(String token) async {
    return await ApiService.post('$_prefix/update-fcm-token', {
      'fcm_token': token,
    });
  }

  static Future<List<Map<String, dynamic>>> getNotifications() async {
    final response = await ApiService.get('$_prefix/notifications');
    if (response['success'] == true && response['data'] != null) {
      if (response['data'] is List) {
        return List<Map<String, dynamic>>.from(response['data']);
      } else if (response['data'] is Map && response['data']['data'] is List) {
        return List<Map<String, dynamic>>.from(response['data']['data']);
      }
    }
    return [];
  }

  static Future<Map<String, dynamic>> markNotificationAsRead(String id) async {
    return await ApiService.post('$_prefix/notifications/$id/read', {});
  }

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
    XFile? certificate,
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
      if (certificate != null) 'certificate': certificate,
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

  // --- Bookings ---
  static Future<Map<String, dynamic>> acceptBooking(String id) async {
    return await ApiService.post('$_prefix/bookings/$id/accept', {});
  }

  static Future<Map<String, dynamic>> rejectBooking(String id) async {
    return await ApiService.post('$_prefix/bookings/$id/reject', {});
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
      final rawData = response['data'];
      List listData = [];
      if (rawData is List) {
        listData = rawData;
      } else if (rawData is Map && rawData['data'] is List) {
        listData = rawData['data'];
      }
      return listData.map((i) => pro_models.ProfessionalBooking.fromJson(i)).toList();
    }
    throw Exception(response['message'] ?? 'Failed to load booking requests');
  }

  static Future<List<pro_models.ProfessionalBooking>> getBookings() async {
    final response = await ApiService.get('$_prefix/bookings');
    if (response['success'] == true) {
      final rawData = response['data'];
      List listData = [];
      if (rawData is List) {
        listData = rawData;
      } else if (rawData is Map && rawData['data'] is List) {
        listData = rawData['data'];
      }
      return listData.map((i) => pro_models.ProfessionalBooking.fromJson(i)).toList();
    }
    throw Exception(response['message'] ?? 'Failed to load bookings');
  }

  static Future<pro_models.ProfessionalBooking> getBookingDetail(String id) async {
    final response = await ApiService.get('$_prefix/bookings/$id');
    if (response['success'] == true && response['data'] != null) {
      return pro_models.ProfessionalBooking.fromJson(response['data']);
    }
    throw Exception(response['message'] ?? 'Failed to load booking details');
  }

  static Future<Map<String, dynamic>> jobStartJourney(String id) async {
    return await ApiService.post('$_prefix/jobs/$id/start-journey', {});
  }

  static Future<Map<String, dynamic>> jobArrived(String id) async {
    return await ApiService.post('$_prefix/jobs/$id/arrived', {});
  }

  static Future<Map<String, dynamic>> jobStartService(String id) async {
    return await ApiService.post('$_prefix/jobs/$id/start-service', {});
  }

  static Future<Map<String, dynamic>> jobFinishService(String id) async {
    return await ApiService.post('$_prefix/jobs/$id/finish-service', {});
  }

  static Future<pro_models.ProfessionalBooking?> getActiveJob() async {
    try {
      final response = await ApiService.get('$_prefix/active-job');
      if (response['success'] == true && response['data'] != null) {
        final job = pro_models.ProfessionalBooking.fromJson(response['data']);
        debugPrint('📋 getActiveJob: ${job.id} (${job.status.name})');
        return job;
      }
    } catch (e) {
      debugPrint('⚠️ getActiveJob error: $e');
    }
    debugPrint('📋 getActiveJob: null (no active job)');
    return null;
  }

  static Future<Map<String, dynamic>> jobComplete(String id) async {
    return await ApiService.post('$_prefix/jobs/$id/complete', {});
  }

  // --- Job Payment (Razorpay) ---
  static Future<Map<String, dynamic>> createJobPaymentOrder(String id) async {
    final response = await ApiService.post('$_prefix/jobs/$id/payment/create-order', {});
    if (response['success'] == true && response['data'] != null) {
      return response['data'];
    }
    throw Exception(response['message'] ?? 'Failed to create job payment order');
  }

  static Future<Map<String, dynamic>> verifyJobPayment({
    required String id,
    required String razorpayPaymentId,
    required String razorpayOrderId,
    required String razorpaySignature,
  }) async {
    final response = await ApiService.post('$_prefix/jobs/$id/payment/verify', {
      'razorpay_payment_id': razorpayPaymentId,
      'razorpay_order_id': razorpayOrderId,
      'razorpay_signature': razorpaySignature,
    });

    // Note: success with null data is valid — the endpoint returns success:true
    // with no data payload. Throwing on null data would show a false error.
    if (response['success'] == true) {
      return response['data'] ?? {};
    }
    throw Exception(response['message'] ?? 'Payment verification failed');
  }

  // --- Wallet ---
  static Future<pro_models.ProfessionalWallet> getWallet({String tab = 'earnings'}) async {
    final response = await ApiService.get('$_prefix/wallet?tab=$tab');
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

  static Future<Map<String, dynamic>> getWithdrawalHistory() async {
    return await ApiService.get('$_prefix/withdrawals/history');
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

  static Future<Map<String, dynamic>> uploadProfileImage(XFile image) async {
    return await ApiService.multipart('$_prefix/upload-profile-image', {}, {'image': image});
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

  static Future<Map<String, dynamic>> updateBankDetails(Map<String, String> data, {XFile? proofImage}) async {
    final Map<String, XFile> files = {};
    if (proofImage != null) {
      files['bank_proof_image'] = proofImage;
    }
    return await ApiService.multipart('$_prefix/update-bank-details', data, files);
  }

  static Future<Map<String, dynamic>> updateUPIDetails(Map<String, String> data, {XFile? screenshot}) async {
    final Map<String, XFile> files = {};
    if (screenshot != null) {
      files['upi_screenshot'] = screenshot;
    }
    return await ApiService.multipart('$_prefix/update-upi-details', data, files);
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
  static Future<List<pro_models.KitProductModel>> getKitProducts() async {
    final response = await ApiService.get('/professional/kit-products');
    final List data = response['data'] ?? [];
    return data.map((e) => pro_models.KitProductModel.fromJson(e)).toList();
  }

  /// Step 1: Create Razorpay Order on Backend
  static Future<Map<String, dynamic>> createKitPaymentOrder(int productId, int quantity) async {
    final response = await ApiService.post('/professional/payment/create-order', {
      'kit_product_id': productId,
      'quantity': quantity,
    });
    
    if (response['success'] == true && response['data'] != null) {
      return response['data'];
    }
    throw Exception(response['message'] ?? 'Failed to create kit payment order');
  }

  /// Step 2: Verify Razorpay Payment Signature on Backend
  static Future<Map<String, dynamic>> verifyKitPayment({
    required int kitProductId,
    required int quantity,
    required String razorpayPaymentId,
    required String razorpayOrderId,
    required String razorpaySignature,
  }) async {
    final response = await ApiService.post('/professional/payment/verify', {
      'kit_product_id': kitProductId,
      'quantity': quantity,
      'razorpay_payment_id': razorpayPaymentId,
      'razorpay_order_id': razorpayOrderId,
      'razorpay_signature': razorpaySignature,
    });

    if (response['success'] == true && response['data'] != null) {
      return response['data'];
    }
    throw Exception(response['message'] ?? 'Payment verification failed');
  }

  // --- Wallet Deposit ---
  static Future<Map<String, dynamic>> createWalletDepositOrder(double amount) async {
    final response = await ApiService.post('$_prefix/wallet/deposit/create-order', {
      'amount': amount,
    });
    
    if (response['success'] == true && response['data'] != null) {
      return response['data'];
    }
    throw Exception(response['message'] ?? 'Failed to create deposit order');
  }

  static Future<Map<String, dynamic>> verifyWalletDeposit({
    required double amount,
    required String razorpayPaymentId,
    required String razorpayOrderId,
    required String razorpaySignature,
  }) async {
    final response = await ApiService.post('$_prefix/wallet/deposit/verify', {
      'amount': amount,
      'razorpay_payment_id': razorpayPaymentId,
      'razorpay_order_id': razorpayOrderId,
      'razorpay_signature': razorpaySignature,
    });

    if (response['success'] == true) {
      return response['data'] ?? {};
    }
    throw Exception(response['message'] ?? 'Deposit verification failed');
  }

  /// Legacy / Wallet Order
  static Future<Map<String, dynamic>> placeKitOrder(int productId, int quantity) async {
    final response = await ApiService.post('/professional/orders', {
      'kit_product_id': productId,
      'quantity': quantity,
    });
    return response;
  }

  static Future<List<Map<String, dynamic>>> getKitOrders() async {
    final response = await ApiService.get('$_prefix/orders');
    if (response['success'] == true) {
      final data = response['data'];
      if (data is List) {
        return List<Map<String, dynamic>>.from(data);
      } else if (data is Map && data.containsKey('data')) {
        return List<Map<String, dynamic>>.from(data['data']);
      }
      return [];
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

  // --- Refer & Earn ---
  static Future<Map<String, dynamic>> getReferralStats() async {
    final response = await ApiService.get('$_prefix/referrals');
    if (response['success'] == true) {
      return response['data'];
    }
    throw Exception(response['message'] ?? 'Failed to load referral stats');
  }

  /// Heartbeat to keep professional online
  static Future<void> updateOnlineStatus() async {
    try {
      await ApiService.post('$_prefix/update-online-status', {});
    } catch (e) {
      // Quietly fail as it's a heartbeat
      debugPrint('Heartbeat failed: $e');
    }
  }
  // --- Schedule ---
  static Future<Map<String, dynamic>> getSchedule(String date) async {
    return await ApiService.get('$_prefix/schedule?date=$date');
  }

  static Future<Map<String, dynamic>> updateSlots({
    bool? morning,
    bool? afternoon,
    bool? evening,
  }) async {
    final body = <String, dynamic>{};
    if (morning != null) body['morning'] = morning;
    if (afternoon != null) body['afternoon'] = afternoon;
    if (evening != null) body['evening'] = evening;
    return await ApiService.post('$_prefix/schedule/slots', body);
  }

  // --- Leave Requests ---
  static Future<Map<String, dynamic>> getLeaves() async {
    return await ApiService.get('$_prefix/leaves');
  }

  static Future<Map<String, dynamic>> applyLeave({
    required String leaveType,
    required String startDate,
    required String endDate,
    required String reason,
  }) async {
    return await ApiService.post('$_prefix/leaves', {
      'leave_type': leaveType,
      'start_date': startDate,
      'end_date': endDate,
      'reason': reason,
    });
  }

  static Future<Map<String, dynamic>> cancelLeave(int id) async {
    return await ApiService.delete('$_prefix/leaves/$id');
  }
}
