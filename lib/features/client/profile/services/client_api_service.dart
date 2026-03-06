import 'package:bellavella/core/services/api_service.dart';
import 'package:bellavella/core/models/data_models.dart';

class ClientApiService {
  static const String _prefix = '/client';

  /// Fetch the profile of the currently authenticated customer.
  static Future<Customer> getProfile() async {
    final response = await ApiService.get('$_prefix/profile');
    if (response['success'] == true) {
      return Customer.fromJson(response['data']);
    }
    throw Exception(response['message'] ?? 'Failed to load profile');
  }

  /// Update profile fields. Backend expects form-data when sending avatar, but
  /// a simple JSON post works for text-only updates.
  static Future<Map<String, dynamic>> updateProfile(
    Map<String, dynamic> data,
  ) async {
    // route defined as POST /client/profile/update
    return await ApiService.post('$_prefix/profile/update', data);
  }

  /// Fetch wallet data including balance and transactions.
  static Future<Map<String, dynamic>> getWallet() async {
    final response = await ApiService.get('$_prefix/wallet');
    if (response['success'] == true) {
      return response['data'] as Map<String, dynamic>;
    }
    throw Exception(response['message'] ?? 'Failed to load wallet');
  }

  /// Fetch list of user addresses.
  static Future<List<dynamic>> getAddresses() async {
    final response = await ApiService.get('$_prefix/addresses');
    if (response['success'] == true) {
      return response['data'] as List<dynamic>;
    }
    throw Exception(response['message'] ?? 'Failed to load addresses');
  }

  /// Submit user rating and feedback.
  static Future<Map<String, dynamic>> submitRating(
    int rating,
    String feedback,
  ) async {
    final response = await ApiService.post('$_prefix/rate', {
      'rating': rating,
      'feedback': feedback,
    });
    if (response['success'] == true) {
      return response['data'] as Map<String, dynamic>;
    }
    throw Exception(response['message'] ?? 'Failed to submit rating');
  }

  /// Submit overall app feedback.
  static Future<Map<String, dynamic>> submitAppFeedback(
    int rating,
    String feedback, {
    String? deviceInfo,
    String? appVersion,
  }) async {
    final response = await ApiService.post('$_prefix/app-feedback', {
      'rating': rating,
      'feedback': feedback,
      if (deviceInfo != null) 'device_info': deviceInfo,
      if (appVersion != null) 'app_version': appVersion,
    });
    if (response['success'] == true) {
      return response['data'] as Map<String, dynamic>;
    }
    throw Exception(response['message'] ?? 'Failed to submit feedback');
  }

  /// Fetch user's referral code and stats.
  static Future<Map<String, dynamic>> getReferralData() async {
    final response = await ApiService.get('$_prefix/referral-code');
    if (response['success'] == true) {
      return response['data'] as Map<String, dynamic>;
    }
    throw Exception(response['message'] ?? 'Failed to load referral data');
  }

  /// Add a new address.
  static Future<Map<String, dynamic>> addAddress(
    Map<String, dynamic> addressData,
  ) async {
    final response = await ApiService.post('$_prefix/addresses', addressData);
    if (response['success'] == true) {
      return response['data'] as Map<String, dynamic>;
    }
    throw Exception(response['message'] ?? 'Failed to add address');
  }

  /// Update an existing address.
  static Future<Map<String, dynamic>> updateAddress(
    String addressId,
    Map<String, dynamic> addressData,
  ) async {
    // RESTful update via PATCH to satisfy apiResource routes
    final response = await ApiService.patch(
      '$_prefix/addresses/$addressId',
      addressData,
    );
    if (response['success'] == true) {
      return response['data'] as Map<String, dynamic>;
    }
    throw Exception(response['message'] ?? 'Failed to update address');
  }

  /// Delete an address.
  ///
  /// Returns true on success. The backend returns `data: null` so we don't
  /// attempt to cast it to a map.
  static Future<bool> deleteAddress(String addressId) async {
    final response = await ApiService.delete('$_prefix/addresses/$addressId');
    if (response['success'] == true) {
      return true;
    }
    throw Exception(response['message'] ?? 'Failed to delete address');
  }
}
