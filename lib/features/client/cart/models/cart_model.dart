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
}
