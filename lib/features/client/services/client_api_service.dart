import 'package:bellavella/core/services/api_service.dart';
import 'package:bellavella/features/client/services/models/service_models.dart';

class ClientApiService {
  static const String _prefix = '/client';

  // --- Category Screen ---
  static Future<CategoryPageData> getCategoryScreenData(String categorySlug) async {
    final response = await ApiService.get('$_prefix/categories/$categorySlug/screen');
    if (response['success'] == true) {
      return CategoryPageData.fromJson(response['data']);
    }
    throw Exception(response['message'] ?? 'Failed to load category screen data');
  }

  static Future<List<ServiceGroup>> getServiceGroups(String categorySlug) async {
    final response = await ApiService.get('$_prefix/categories/$categorySlug/service-groups');
    if (response['success'] == true) {
      return (response['data'] as List).map((e) => ServiceGroup.fromJson(e)).toList();
    }
    throw Exception(response['message'] ?? 'Failed to load service groups');
  }

  static Future<CategoryDetail> getCategoryDetails(String categorySlug) async {
    final response = await ApiService.get('$_prefix/categories/$categorySlug/details');
    if (response['success'] == true) {
      return CategoryDetail.fromJson(response['data']);
    }
    throw Exception(response['message'] ?? 'Failed to load category details');
  }

  static Future<ServiceHierarchyNode> getHierarchyNode({
    required String nodeKey,
    String? level,
    ServiceHierarchyNode? seedNode,
  }) async {
    final query = <String>[];
    if (level != null && level.isNotEmpty) {
      query.add('level=$level');
    }

    final endpoint = query.isEmpty
        ? '$_prefix/service-hierarchy/$nodeKey'
        : '$_prefix/service-hierarchy/$nodeKey?${query.join('&')}';

    final response = await ApiService.get(endpoint);
    if (response['success'] == true && response['data'] is Map<String, dynamic>) {
      return ServiceHierarchyNode.fromJson(response['data'] as Map<String, dynamic>);
    }

    // fallback only if explicitly intended or node metadata allows it
    if (seedNode != null && seedNode.level == 'category' && seedNode.slug.isNotEmpty && response['success'] != true) {
      try {
        final detail = await getCategoryDetails(seedNode.slug);
        return detail.toHierarchyNode();
      } catch (_) {
        // if even details fail, throw below
      }
    }

    throw Exception(response['message'] ?? 'Failed to load hierarchy node [$nodeKey]');
  }

  // --- Refer & Earn ---
  static Future<Map<String, dynamic>> getReferralStats() async {
    final response = await ApiService.get('$_prefix/referrals');
    if (response['success'] == true) {
      return response['data'];
    }
    throw Exception(response['message'] ?? 'Failed to load referral stats');
  }

  // --- Cart Checkout & Sync ---
  static Future<Map<String, dynamic>> syncCart(List<Map<String, dynamic>> items) async {
    return await ApiService.post('$_prefix/cart/sync', {'items': items});
  }

  static Future<Map<String, dynamic>> getSlotsFromCart() async {
    return await ApiService.get('$_prefix/slots-from-cart');
  }

  static Future<Map<String, dynamic>> checkoutCart(Map<String, dynamic> data) async {
    return await ApiService.post('$_prefix/cart/checkout', data);
  }

  static Future<Map<String, dynamic>> verifyCheckoutPayment({
    required int orderId,
    required String razorpayPaymentId,
    required String razorpayOrderId,
    required String razorpaySignature,
  }) async {
    return await ApiService.post('$_prefix/cart/checkout/verify', {
      'order_id': orderId,
      'razorpay_payment_id': razorpayPaymentId,
      'razorpay_order_id': razorpayOrderId,
      'razorpay_signature': razorpaySignature,
    });
  }

  // --- Reviews ---
  static Future<List<ReviewData>> getServiceReviews(int serviceId) async {
    final response = await ApiService.get('$_prefix/services/$serviceId/reviews');
    if (response['success'] == true) {
      final reviewsJson = response['data']?['data'] as List? ?? [];
      return reviewsJson
          .map((e) => ReviewData.fromJson(Map<String, dynamic>.from(e)))
          .toList();
    }
    throw Exception(response['message'] ?? 'Failed to load service reviews');
  }
}
