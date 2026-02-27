import '../../../../core/services/api_service.dart';

class AuthApiService {
  static Future<Map<String, dynamic>> sendOtp(String mobile) async {
    // According to api.php: Route::post('send-otp', [FlutterAuthController::class, 'sendOtp']);
    // Prefix is 'flutter/auth'
    return await ApiService.post('/flutter/auth/send-otp', {
      'mobile': mobile,
    });
  }

  static Future<Map<String, dynamic>> verifyOtp(String mobile, String otp) async {
    return await ApiService.post('/flutter/auth/verify-otp', {
      'mobile': mobile,
      'otp': otp,
    });
  }
}
