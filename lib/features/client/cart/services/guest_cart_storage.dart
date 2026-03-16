import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/cart_model.dart';

class GuestCartStorage {
  static const String _guestCartKey = 'guest_cart_items';

  Future<List<CartItem>> loadItems() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_guestCartKey);
    if (raw == null || raw.isEmpty) {
      return const [];
    }

    try {
      final decoded = jsonDecode(raw);
      if (decoded is! List) {
        return const [];
      }

      return decoded
          .whereType<Map>()
          .map((item) => CartItem.fromJson(Map<String, dynamic>.from(item)))
          .toList();
    } catch (_) {
      return const [];
    }
  }

  Future<void> saveItems(List<CartItem> items) async {
    final prefs = await SharedPreferences.getInstance();
    final payload = items.map((item) => item.toJson()).toList();
    await prefs.setString(_guestCartKey, jsonEncode(payload));
  }

  Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_guestCartKey);
  }
}
