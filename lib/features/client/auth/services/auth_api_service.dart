import '../../../../core/services/api_service.dart';

class AuthApiService {
  static Future<Map<String, dynamic>> sendOtp(String mobile) async {
    // According to api.php: Route::post('send-otp', [ClientAuthController::class, 'sendOtp']);
    // Prefix is 'client/auth'
    return await ApiService.post('/client/auth/send-otp', {'mobile': mobile});
  }

  static Future<Map<String, dynamic>> verifyOtp(
    String mobile,
    String otp,
  ) async {
    return await ApiService.post('/client/auth/verify-otp', {
      'mobile': mobile,
      'otp': otp,
    });
  }
}
