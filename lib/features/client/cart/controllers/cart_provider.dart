import 'package:flutter/material.dart';
import 'package:bellavella/core/services/api_service.dart';
import 'package:bellavella/core/services/promotion_service.dart';
import 'package:bellavella/core/services/token_manager.dart';
import '../models/cart_model.dart';
import '../services/guest_cart_storage.dart';
import '../../home/models/home_models.dart';

class CartProvider extends ChangeNotifier {
  final Map<int, CartItem> _items = {};
  final Set<int> _syncingItemIds = {};
  final GuestCartStorage _guestCartStorage = GuestCartStorage();
  double _discount = 0.0;
  double _tip = 0.0;
  Map<String, dynamic>? _appliedPromotion;
  bool _isLoading = false;
  String? _error;
  bool _isInitialized = false;

  CartProvider() {
    _initialize();
  }

  List<CartItem> get items => _items.values.toList();
  int get itemCount => _items.length;
  double get discount => _discount;
  double get tip => _tip;
  Map<String, dynamic>? get appliedPromotion => _appliedPromotion;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool isItemSyncing(int itemId) => _syncingItemIds.contains(itemId);
  bool get isGuestCart => !TokenManager.hasToken;

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

  Future<void> _initialize() async {
    await _loadGuestCartIntoMemory();
    _isInitialized = true;
    notifyListeners();
  }

  Future<void> _ensureInitialized() async {
    if (_isInitialized) {
      return;
    }
    await _initialize();
  }

  Future<void> _loadGuestCartIntoMemory() async {
    final localItems = await _guestCartStorage.loadItems();
    _items
      ..clear()
      ..addEntries(localItems.map((item) => MapEntry(item.quantityKey, item)));
  }

  Future<void> _persistGuestCart() async {
    await _guestCartStorage.saveItems(_items.values.toList());
  }

  CartItem? _cartItemFromBackend(Map<String, dynamic> item) {
    final serviceId = int.tryParse(item['service_id']?.toString() ?? '');
    final variantId = int.tryParse(item['service_variant_id']?.toString() ?? '');
    final itemId = int.tryParse(item['item_id']?.toString() ?? '');
    final quantityKey = variantId ?? serviceId ?? itemId;
    final cartId = int.tryParse(item['id']?.toString() ?? '');
    if (quantityKey == null || cartId == null) {
      return null;
    }

    final title =
        item['variant_name']?.toString().isNotEmpty == true
            ? item['variant_name'].toString()
            : (item['display_name']?.toString() ??
                item['name']?.toString() ??
                'Unknown');
    final subtitle =
        item['variant_name']?.toString().isNotEmpty == true
            ? item['service_name']?.toString()
            : null;

    return CartItem(
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

  Map<String, dynamic> _buildCreatePayload(CartItem item, {int? quantity}) {
    final payload = <String, dynamic>{
      'item_type': item.serviceVariantId != null ? 'variant' : item.itemType,
      'item_id': item.serviceVariantId ?? item.serviceId ?? item.id,
      'service_id': item.serviceId ?? item.id,
      'quantity': quantity ?? item.quantity,
    };
    if (item.serviceVariantId != null) {
      payload['service_variant_id'] = item.serviceVariantId;
      payload['bookable_type'] = 'variant';
    }
    return payload;
  }

  Future<void> fetchCart() async {
    await _ensureInitialized();
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      if (!TokenManager.hasToken) {
        await _loadGuestCartIntoMemory();
        return;
      }

      await syncGuestCartToBackend();

      final response = await ApiService.get('/client/cart');
      if (response['success'] == true && response['data'] is Map<String, dynamic>) {
        final data = Map<String, dynamic>.from(response['data']);
        final rawItems = (data['items'] as List? ?? const []);
        final nextItems = <int, CartItem>{};

        for (final raw in rawItems.whereType<Map>()) {
          final item = Map<String, dynamic>.from(raw);
          final cartItem = _cartItemFromBackend(item);
          if (cartItem == null) continue;
          nextItems[cartItem.quantityKey] = cartItem;
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

  Future<String?> addItem(HomeService service, {String? categoryName}) async {
    final item = CartItem(
      cartId: 0,
      id: service.id,
      serviceId: service.id,
      itemType: 'service',
      title: service.title,
      subtitle: service.subtitle,
      price: service.price,
      imageUrl: service.imageUrl,
      categoryName: categoryName ?? 'Service',
      quantity: 1,
    );
    return addOrUpdateLocalOrRemoteItem(item, nextQuantityDelta: 1);
  }

  Future<String?> addOrUpdateLocalOrRemoteItem(
    CartItem item, {
    int nextQuantityDelta = 1,
  }) async {
    await _ensureInitialized();

    final itemKey = item.quantityKey;
    final existingItem = _items[itemKey];
    final nextQuantity = (existingItem?.quantity ?? 0) + nextQuantityDelta;

    if (!TokenManager.hasToken) {
      if (nextQuantity <= 0) {
        _items.remove(itemKey);
      } else {
        _items[itemKey] = (existingItem ?? item).copyWith(
          quantity: nextQuantity,
          cartId: 0,
        );
      }
      await _persistGuestCart();
      notifyListeners();
      return null;
    }

    _syncingItemIds.add(itemKey);
    notifyListeners();
    try {
      if (existingItem != null && existingItem.cartId > 0) {
        if (nextQuantity <= 0) {
          final response = await ApiService.delete(
            '/client/cart/${existingItem.cartId}',
          );
          if (response['success'] == true) {
            _items.remove(itemKey);
            return null;
          }
          return response['message']?.toString() ?? 'Failed to update cart.';
        } else {
          final response = await ApiService.put(
            '/client/cart/${existingItem.cartId}',
            {'quantity': nextQuantity},
          );
          if (response['success'] == true) {
            _items[itemKey] = existingItem.copyWith(quantity: nextQuantity);
            return null;
          }
          return response['message']?.toString() ?? 'Failed to update cart.';
        }
      } else if (nextQuantity > 0) {
        final response = await ApiService.post(
          '/client/cart',
          _buildCreatePayload(item, quantity: nextQuantity),
        );
        if (response['success'] == true && response['data'] is Map<String, dynamic>) {
          final data = Map<String, dynamic>.from(response['data']);
          final createdItem = CartItem(
            cartId: int.tryParse(data['id']?.toString() ?? '') ?? 0,
            id: item.id,
            serviceId: item.serviceId,
            serviceVariantId: item.serviceVariantId,
            itemType: item.itemType,
            title: item.title,
            subtitle: item.subtitle,
            price: item.price,
            imageUrl: item.imageUrl,
            categoryName: item.categoryName,
            quantity: int.tryParse(data['quantity']?.toString() ?? '') ??
                nextQuantity,
          );
          _items[itemKey] = createdItem;
          return null;
        }

        final errors = response['errors'];
        if (errors is Map && errors.isNotEmpty) {
          final firstFieldErrors = errors.values.first;
          if (firstFieldErrors is List && firstFieldErrors.isNotEmpty) {
            return firstFieldErrors.first?.toString() ??
                response['message']?.toString() ??
                'Failed to add item to cart.';
          }
        }

        return response['message']?.toString() ?? 'Failed to add item to cart.';
      }
      return null;
    } finally {
      _syncingItemIds.remove(itemKey);
      notifyListeners();
    }
  }

  Future<void> removeItem(int serviceId) async {
    await _updateQuantity(serviceId, 0);
  }

  Future<void> incrementQuantity(int serviceId) async {
    await _updateQuantity(serviceId, (_items[serviceId]?.quantity ?? 0) + 1);
  }

  Future<void> decrementQuantity(int serviceId) async {
    final item = _items[serviceId];
    if (item == null) return;
    await _updateQuantity(serviceId, item.quantity - 1);
  }

  Future<void> clear() async {
    _items.clear();
    _discount = 0.0;
    _appliedPromotion = null;
    if (!TokenManager.hasToken) {
      await _guestCartStorage.clear();
    }
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
    await _ensureInitialized();
    if (!TokenManager.hasToken) {
      await _persistGuestCart();
      return true;
    }

    await syncGuestCartToBackend();
    await fetchCart();
    return error == null;
  }

  Future<bool> syncGuestCartToBackend() async {
    await _ensureInitialized();
    if (!TokenManager.hasToken) {
      return false;
    }

    final guestItems = await _guestCartStorage.loadItems();
    if (guestItems.isEmpty) {
      return true;
    }

    final response = await ApiService.get('/client/cart');
    if (response['success'] != true || response['data'] is! Map<String, dynamic>) {
      return false;
    }

    final data = Map<String, dynamic>.from(response['data']);
    final rawItems = (data['items'] as List? ?? const []);
    final remoteItems = <int, CartItem>{};
    for (final raw in rawItems.whereType<Map>()) {
      final item = _cartItemFromBackend(Map<String, dynamic>.from(raw));
      if (item == null) continue;
      remoteItems[item.quantityKey] = item;
    }

    for (final guestItem in guestItems) {
      final remoteItem = remoteItems[guestItem.quantityKey];
      if (remoteItem != null && remoteItem.cartId > 0) {
        await ApiService.put('/client/cart/${remoteItem.cartId}', {
          'quantity': remoteItem.quantity + guestItem.quantity,
        });
      } else {
        await ApiService.post(
          '/client/cart',
          _buildCreatePayload(guestItem),
        );
      }
    }

    await _guestCartStorage.clear();
    return true;
  }

  Future<void> _updateQuantity(int itemId, int nextQuantity) async {
    await _ensureInitialized();
    final item = _items[itemId];
    if (item == null || _syncingItemIds.contains(itemId)) {
      return;
    }

    if (!TokenManager.hasToken) {
      if (nextQuantity <= 0) {
        _items.remove(itemId);
      } else {
        _items[itemId] = item.copyWith(quantity: nextQuantity, cartId: 0);
      }
      await _persistGuestCart();
      notifyListeners();
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


