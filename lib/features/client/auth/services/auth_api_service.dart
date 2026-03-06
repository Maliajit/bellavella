import '../../../../core/services/api_service.dart';
import '../../../../core/services/token_manager.dart';

class AuthApiService {
  static const String _prefix = '/client/auth';

  static Future<Map<String, dynamic>> sendOtp(String mobile) async {
    return await ApiService.post('$_prefix/send-otp', {
      'mobile': mobile,
    });
  }

  static Future<Map<String, dynamic>> verifyOtp(String mobile, String otp, {String? referralCode}) async {
    final response = await ApiService.post('$_prefix/verify-otp', {
      'mobile': mobile,
      'otp': otp,
      if (referralCode != null) 'referral_code': referralCode,
    });

    // store token when available so authenticated routes work
    if (response['success'] == true && response['data'] != null) {
      final token = response['data']['access_token'];
      if (token != null) {
        await TokenManager.setToken(token);
      }
    }

    return response;
  }
}
