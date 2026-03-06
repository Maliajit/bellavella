import '../../../../core/services/api_service.dart';
import '../../../../core/services/token_manager.dart';

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
    final response = await ApiService.post('/client/auth/verify-otp', {
      'mobile': mobile,
      'otp': otp,
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
