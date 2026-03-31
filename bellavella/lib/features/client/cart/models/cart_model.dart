class CartItem {
  final int cartId;
  final int id;
  final int? serviceId;
  final int? serviceVariantId;
  final int? packageId;
  final String itemType;
  final String title;
  final String? subtitle;
  final double price;
  final String imageUrl;
  final String? categoryName;
  final int? durationMinutes;
  final Map<String, dynamic>? packageConfiguration;
  final String? packageContextType;
  final int? packageContextId;
  int quantity;

  CartItem({
    required this.cartId,
    required this.id,
    this.serviceId,
    this.serviceVariantId,
    this.packageId,
    this.itemType = 'service',
    required this.title,
    this.subtitle,
    required this.price,
    required this.imageUrl,
    this.categoryName,
    this.durationMinutes,
    this.packageConfiguration,
    this.packageContextType,
    this.packageContextId,
    this.quantity = 1,
  });

  double get totalPrice => price * quantity;
  bool get isPackage => itemType == 'package';

  int get quantityKey => isPackage
      ? (cartId > 0 ? cartId : (packageId ?? id))
      : (serviceVariantId ?? serviceId ?? id);

  CartItem copyWith({
    int? cartId,
    int? id,
    int? serviceId,
    int? serviceVariantId,
    int? packageId,
    String? itemType,
    String? title,
    String? subtitle,
    double? price,
    String? imageUrl,
    String? categoryName,
    int? durationMinutes,
    Map<String, dynamic>? packageConfiguration,
    String? packageContextType,
    int? packageContextId,
    int? quantity,
  }) {
    return CartItem(
      cartId: cartId ?? this.cartId,
      id: id ?? this.id,
      serviceId: serviceId ?? this.serviceId,
      serviceVariantId: serviceVariantId ?? this.serviceVariantId,
      packageId: packageId ?? this.packageId,
      itemType: itemType ?? this.itemType,
      title: title ?? this.title,
      subtitle: subtitle ?? this.subtitle,
      price: price ?? this.price,
      imageUrl: imageUrl ?? this.imageUrl,
      categoryName: categoryName ?? this.categoryName,
      durationMinutes: durationMinutes ?? this.durationMinutes,
      packageConfiguration:
          packageConfiguration ?? this.packageConfiguration,
      packageContextType: packageContextType ?? this.packageContextType,
      packageContextId: packageContextId ?? this.packageContextId,
      quantity: quantity ?? this.quantity,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'cart_id': cartId,
      'id': id,
      'service_id': serviceId,
      'service_variant_id': serviceVariantId,
      'package_id': packageId,
      'item_type': itemType,
      'title': title,
      'subtitle': subtitle,
      'price': price,
      'image_url': imageUrl,
      'category_name': categoryName,
      'duration_minutes': durationMinutes,
      'package_configuration': packageConfiguration,
      'package_context_type': packageContextType,
      'package_context_id': packageContextId,
      'quantity': quantity,
    };
  }

  factory CartItem.fromJson(Map<String, dynamic> json) {
    return CartItem(
      cartId: int.tryParse(json['cart_id']?.toString() ?? '') ?? 0,
      id: int.tryParse(json['id']?.toString() ?? '') ?? 0,
      serviceId: int.tryParse(json['service_id']?.toString() ?? ''),
      serviceVariantId: int.tryParse(
        json['service_variant_id']?.toString() ?? '',
      ),
      packageId: int.tryParse(json['package_id']?.toString() ?? ''),
      itemType: json['item_type']?.toString() ?? 'service',
      title: json['title']?.toString() ?? '',
      subtitle: json['subtitle']?.toString(),
      price: double.tryParse(json['price']?.toString() ?? '') ?? 0,
      imageUrl: json['image_url']?.toString() ?? '',
      categoryName: json['category_name']?.toString(),
      durationMinutes: int.tryParse(json['duration_minutes']?.toString() ?? ''),
      packageConfiguration:
          json['package_configuration'] is Map<String, dynamic>
              ? json['package_configuration'] as Map<String, dynamic>
              : json['package_configuration'] is Map
                  ? Map<String, dynamic>.from(json['package_configuration'] as Map)
                  : null,
      packageContextType: json['package_context_type']?.toString(),
      packageContextId: int.tryParse(
        json['package_context_id']?.toString() ?? '',
      ),
      quantity: int.tryParse(json['quantity']?.toString() ?? '') ?? 1,
    );
  }
}
