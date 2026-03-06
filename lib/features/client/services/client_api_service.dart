import 'package:bellavella/core/services/api_service.dart';

class ClientApiService {
  static const String _prefix = '/client';

  // --- Refer & Earn ---
  static Future<Map<String, dynamic>> getReferralStats() async {
    final response = await ApiService.get('$_prefix/referrals');
    if (response['success'] == true) {
      return response['data'];
    }
    throw Exception(response['message'] ?? 'Failed to load referral stats');
  }
}
