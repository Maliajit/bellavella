import 'package:flutter/material.dart';
import 'package:bellavella/core/services/api_service.dart';
import 'package:bellavella/core/services/promotion_service.dart';
import '../models/cart_model.dart';
import '../../home/models/home_models.dart';

class CartProvider extends ChangeNotifier {
  final Map<int, CartItem> _items = {};
  final Set<int> _syncingItemIds = {};
  double _discount = 0.0;
  double _tip = 0.0;
  Map<String, dynamic>? _appliedPromotion;
  bool _isLoading = false;
  String? _error;

  List<CartItem> get items => _items.values.toList();
  int get itemCount => _items.length;
  double get discount => _discount;
  double get tip => _tip;
  Map<String, dynamic>? get appliedPromotion => _appliedPromotion;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool isItemSyncing(int itemId) => _syncingItemIds.contains(itemId);

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

  Future<void> fetchCart() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await ApiService.get('/client/cart');
      if (response['success'] == true && response['data'] is Map<String, dynamic>) {
        final data = Map<String, dynamic>.from(response['data']);
        final rawItems = (data['items'] as List? ?? const []);
        final nextItems = <int, CartItem>{};

        for (final raw in rawItems.whereType<Map>()) {
          final item = Map<String, dynamic>.from(raw);
          final serviceId = int.tryParse(item['service_id']?.toString() ?? '');
          final variantId = int.tryParse(item['service_variant_id']?.toString() ?? '');
          final itemId = int.tryParse(item['item_id']?.toString() ?? '');
          final quantityKey = variantId ?? serviceId ?? itemId;
          final cartId = int.tryParse(item['id']?.toString() ?? '');
          if (quantityKey == null || cartId == null) {
            continue;
          }

          final title =
              item['variant_name']?.toString().isNotEmpty == true
                  ? item['variant_name'].toString()
                  : (item['display_name']?.toString() ?? item['name']?.toString() ?? 'Unknown');
          final subtitle =
              item['variant_name']?.toString().isNotEmpty == true
                  ? item['service_name']?.toString()
                  : null;

          nextItems[quantityKey] = CartItem(
            cartId: cartId,
            id: quantityKey,
            serviceId: serviceId,
            serviceVariantId: variantId,
            itemType: item['item_type']?.toString() ?? 'service',
            title: title,
            subtitle: subtitle,
            price: double.tryParse(item['unit_price']?.toString() ?? '') ?? 0,
            imageUrl: item['image']?.toString() ?? '',
            categoryName: 'Services',
            quantity: int.tryParse(item['quantity']?.toString() ?? '1') ?? 1,
          );
        }

        _items
          ..clear()
          ..addAll(nextItems);
      } else {
        _error = response['message']?.toString() ?? 'Failed to load cart.';
      }
    } catch (e) {
      _error = 'Failed to load cart.';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
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
          cartId: existingCartItem.cartId,
          id: existingCartItem.id,
          serviceId: existingCartItem.serviceId,
          serviceVariantId: existingCartItem.serviceVariantId,
          itemType: existingCartItem.itemType,
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
          cartId: 0,
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
    _updateQuantity(serviceId, (_items[serviceId]?.quantity ?? 0) + 1);
  }

  void decrementQuantity(int serviceId) {
    final item = _items[serviceId];
    if (item == null) return;
    _updateQuantity(serviceId, item.quantity - 1);
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
    await fetchCart();
    return error == null;
  }

  Future<void> _updateQuantity(int itemId, int nextQuantity) async {
    final item = _items[itemId];
    if (item == null || _syncingItemIds.contains(itemId)) {
      return;
    }

    _syncingItemIds.add(itemId);
    notifyListeners();

    try {
      if (nextQuantity <= 0) {
        final response = await ApiService.delete('/client/cart/${item.cartId}');
        if (response['success'] == true) {
          _items.remove(itemId);
        }
        return;
      }

      final response = await ApiService.put('/client/cart/${item.cartId}', {
        'quantity': nextQuantity,
      });

      if (response['success'] == true) {
        _items[itemId]!.quantity = nextQuantity;
      }
    } finally {
      _syncingItemIds.remove(itemId);
      notifyListeners();
    }
  }
}


