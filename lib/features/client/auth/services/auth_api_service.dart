import '../../../../core/services/api_service.dart';

class AuthApiService {
  static const String _prefix = '/client/auth';

  static Future<Map<String, dynamic>> sendOtp(String mobile) async {
    return await ApiService.post('$_prefix/send-otp', {
      'mobile': mobile,
    });
  }

  static Future<Map<String, dynamic>> verifyOtp(String mobile, String otp, {String? referralCode}) async {
    return await ApiService.post('$_prefix/verify-otp', {
      'mobile': mobile,
      'otp': otp,
      if (referralCode != null) 'referral_code': referralCode,
    });
  }
}
