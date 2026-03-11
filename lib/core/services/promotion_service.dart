import 'api_service.dart';

class PromotionService {
  static Future<Map<String, dynamic>> getActivePromotions() async {
    return await ApiService.get('/client/promotions');
  }

  static Future<Map<String, dynamic>> validateCoupon(String code, double orderAmount) async {
    return await ApiService.post('/client/promotions/validate', {
      'code': code,
      'order_amount_paise': (orderAmount * 100).toInt(),
    });
  }
}
