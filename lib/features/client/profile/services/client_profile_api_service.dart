import 'package:bellavella/core/services/api_service.dart';
import 'package:bellavella/core/models/data_models.dart';
import 'package:image_picker/image_picker.dart';

class ClientProfileApiService {
  static const String _prefix = '/client';

  /// Fetch the profile of the currently authenticated customer.
  static Future<Customer> getProfile() async {
    final response = await ApiService.get('$_prefix/profile');
    if (response['success'] == true) {
      return Customer.fromJson(response['data']);
    }
    throw Exception(response['message'] ?? 'Failed to load profile');
  }

  /// Update profile text fields only.
  static Future<Map<String, dynamic>> updateProfile({
    required String name,
    String? email,
    String? dateOfBirth,
  }) async {
    final data = <String, dynamic>{
      'name': name,
      if (email != null && email.trim().isNotEmpty) 'email': email.trim(),
      if (dateOfBirth != null && dateOfBirth != 'Select Date') 'date_of_birth': dateOfBirth,
    };
    return await ApiService.post('$_prefix/profile/update', data);
  }

  /// Upload a new avatar image. Sends multipart form-data with the image file.
  static Future<Map<String, dynamic>> uploadAvatar(XFile imageFile) async {
    return await ApiService.multipart(
      '$_prefix/profile/update',
      {},                                    // no extra text fields — text fields updated separately
      {'avatar_file': imageFile},
    );
  }


  /// Fetch wallet data including balance and transactions.
  static Future<Map<String, dynamic>> getWallet() async {
    final response = await ApiService.get('$_prefix/wallet');
    if (response['success'] == true) {
      return response['data'] as Map<String, dynamic>;
    }
    throw Exception(response['message'] ?? 'Failed to load wallet');
  }

  /// Fetch available scratch cards.
  static Future<List<dynamic>> getScratchCards() async {
    final response = await ApiService.get('$_prefix/scratch-cards');
    if (response['success'] == true) {
      return response['data'] as List<dynamic>;
    }
    throw Exception(response['message'] ?? 'Failed to load scratch cards');
  }

  /// Mark a scratch card as scratched and reveal/credit reward.
  static Future<Map<String, dynamic>> scratchCard(String id) async {
    final response = await ApiService.post('$_prefix/scratch-cards/$id/scratch', {});
    if (response['success'] == true) {
      return response['data'] as Map<String, dynamic>;
    }
    throw Exception(response['message'] ?? 'Failed to process scratch card');
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
  static Future<Map<String, dynamic>> getReferralStats() async {
    final response = await ApiService.get('$_prefix/referrals');
    if (response['success'] == true) {
      return response['data'] as Map<String, dynamic>;
    }
    throw Exception(response['message'] ?? 'Failed to load referral data');
  }

  /// Add a new address.
  static Future<Map<String, dynamic>> addAddress({
    required String label,
    required String houseNumber,
    required String address,
    required String city,
    required String pincode,
    required String phone,
    String? landmark,
  }) async {
    final addressData = {
      'label': label,
      'house_number': houseNumber,
      'address': address,
      if (landmark != null && landmark.trim().isNotEmpty) 'landmark': landmark.trim(),
      'city': city,
      'pincode': pincode,
      'phone': phone,
    };
    final response = await ApiService.post('$_prefix/addresses', addressData);
    if (response['success'] == true) {
      return response['data'] as Map<String, dynamic>;
    }
    throw Exception(response['message'] ?? 'Failed to add address');
  }

  /// Update an existing address.
  static Future<Map<String, dynamic>> updateAddress({
    required String addressId,
    required String label,
    required String houseNumber,
    required String address,
    required String city,
    required String pincode,
    required String phone,
    String? landmark,
  }) async {
    final addressData = {
      'label': label,
      'house_number': houseNumber,
      'address': address,
      if (landmark != null && landmark.trim().isNotEmpty) 'landmark': landmark.trim(),
      'city': city,
      'pincode': pincode,
      'phone': phone,
    };
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
