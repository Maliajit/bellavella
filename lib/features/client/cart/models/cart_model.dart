class CartItem {
  final int cartId;
  final int id;
  final int? serviceId;
  final int? serviceVariantId;
  final String itemType;
  final String title;
  final String? subtitle;
  final double price;
  final String imageUrl;
  final String? categoryName;
  int quantity;

  CartItem({
    required this.cartId,
    required this.id,
    this.serviceId,
    this.serviceVariantId,
    this.itemType = 'service',
    required this.title,
    this.subtitle,
    required this.price,
    required this.imageUrl,
    this.categoryName,
    this.quantity = 1,
  });

  double get totalPrice => price * quantity;

  int get quantityKey => serviceVariantId ?? serviceId ?? id;

  CartItem copyWith({
    int? cartId,
    int? id,
    int? serviceId,
    int? serviceVariantId,
    String? itemType,
    String? title,
    String? subtitle,
    double? price,
    String? imageUrl,
    String? categoryName,
    int? quantity,
  }) {
    return CartItem(
      cartId: cartId ?? this.cartId,
      id: id ?? this.id,
      serviceId: serviceId ?? this.serviceId,
      serviceVariantId: serviceVariantId ?? this.serviceVariantId,
      itemType: itemType ?? this.itemType,
      title: title ?? this.title,
      subtitle: subtitle ?? this.subtitle,
      price: price ?? this.price,
      imageUrl: imageUrl ?? this.imageUrl,
      categoryName: categoryName ?? this.categoryName,
      quantity: quantity ?? this.quantity,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'cart_id': cartId,
      'id': id,
      'service_id': serviceId,
      'service_variant_id': serviceVariantId,
      'item_type': itemType,
      'title': title,
      'subtitle': subtitle,
      'price': price,
      'image_url': imageUrl,
      'category_name': categoryName,
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
      itemType: json['item_type']?.toString() ?? 'service',
      title: json['title']?.toString() ?? '',
      subtitle: json['subtitle']?.toString(),
      price: double.tryParse(json['price']?.toString() ?? '') ?? 0,
      imageUrl: json['image_url']?.toString() ?? '',
      categoryName: json['category_name']?.toString(),
      quantity: int.tryParse(json['quantity']?.toString() ?? '') ?? 1,
    );
  }
}
