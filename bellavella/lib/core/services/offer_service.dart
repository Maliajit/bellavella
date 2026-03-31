import 'api_service.dart';

class OfferService {
  static Future<Map<String, dynamic>> getActiveOffers() async {
    return await ApiService.get('/client/offers');
  }

  static Future<Map<String, dynamic>> validateCoupon(String code, double orderAmount) async {
    return await ApiService.post('/client/offers/validate', {
      'code': code,
      'order_amount_paise': (orderAmount * 100).toInt(),
    });
  }
}
