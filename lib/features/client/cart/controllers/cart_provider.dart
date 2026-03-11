import 'package:flutter/material.dart';
import 'package:bellavella/core/services/promotion_service.dart';
import '../models/cart_model.dart';
import '../../home/models/home_models.dart';
import '../../services/client_api_service.dart';

class CartProvider extends ChangeNotifier {
  final Map<int, CartItem> _items = {};
  double _discount = 0.0;
  double _tip = 0.0;
  Map<String, dynamic>? _appliedPromotion;

  List<CartItem> get items => _items.values.toList();
  int get itemCount => _items.length;
  double get discount => _discount;
  double get tip => _tip;
  Map<String, dynamic>? get appliedPromotion => _appliedPromotion;

  double get subtotal {
    var total = 0.0;
    _items.forEach((key, cartItem) {
      final itemTotal = cartItem.price * cartItem.quantity;
      if (!itemTotal.isNaN) {
        total += itemTotal;
      }
    });
    return total;
  }

  double get totalAfterDiscount {
    final val = subtotal - _discount;
    return (val.isNaN || val < 0) ? 0.0 : val;
  }

  double get totalAmount {
    final val = totalAfterDiscount + _tip;
    return val.isNaN ? 0.0 : val;
  }

  void setTip(double amount) {
    _tip = amount;
    notifyListeners();
  }

  void addItem(HomeService service, {String? categoryName}) {
    if (_items.containsKey(service.id)) {
      _items.update(
        service.id,
        (existingCartItem) => CartItem(
          id: existingCartItem.id,
          title: existingCartItem.title,
          subtitle: existingCartItem.subtitle,
          price: existingCartItem.price,
          imageUrl: existingCartItem.imageUrl,
          categoryName: existingCartItem.categoryName,
          quantity: existingCartItem.quantity + 1,
        ),
      );
    } else {
      _items.putIfAbsent(
        service.id,
        () => CartItem(
          id: service.id,
          title: service.title,
          subtitle: service.subtitle,
          price: service.price,
          imageUrl: service.imageUrl,
          categoryName: categoryName ?? 'Service',
        ),
      );
    }
    notifyListeners();
  }

  void removeItem(int serviceId) {
    _items.remove(serviceId);
    notifyListeners();
  }

  void incrementQuantity(int serviceId) {
    if (_items.containsKey(serviceId)) {
      _items[serviceId]!.quantity++;
      notifyListeners();
    }
  }

  void decrementQuantity(int serviceId) {
    if (_items.containsKey(serviceId)) {
      if (_items[serviceId]!.quantity > 1) {
        _items[serviceId]!.quantity--;
      } else {
        _items.remove(serviceId);
      }
      notifyListeners();
    }
  }

  void clear() {
    _items.clear();
    _discount = 0.0;
    _appliedPromotion = null;
    notifyListeners();
  }

  Future<String?> applyPromotion(String code) async {
    try {
      final response = await PromotionService.validateCoupon(code, subtotal);
      if (response['success'] == true) {
        final data = response['data'];
        final discountPaise = data['discount_paise'];
        _discount = (discountPaise != null ? (discountPaise as num).toDouble() : 0.0) / 100.0;
        _appliedPromotion = data;
        notifyListeners();
        return null; // No error
      } else {
        return response['message'] ?? 'Failed to apply coupon.';
      }
    } catch (e) {
      return 'An error occurred while applying the coupon.';
    }
  }

  void removePromotion() {
    _discount = 0.0;
    _appliedPromotion = null;
    notifyListeners();
  }

  Future<bool> syncCartWithBackend() async {
    try {
      final List<Map<String, dynamic>> syncItems = items.map((e) => {
        'item_type': 'service', // Assuming only services are added for now, adjust if packages added
        'item_id': e.id,
        'quantity': e.quantity,
      }).toList();

      if (syncItems.isEmpty) return true; // Nothing to sync

      final response = await ClientApiService.syncCart(syncItems);
      return response['success'] == true;
    } catch (e) {
      return false;
    }
  }
}


