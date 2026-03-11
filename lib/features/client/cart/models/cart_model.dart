class CartItem {
  final int id;
  final String title;
  final String? subtitle;
  final double price;
  final String imageUrl;
  final String? categoryName;
  int quantity;

  CartItem({
    required this.id,
    required this.title,
    this.subtitle,
    required this.price,
    required this.imageUrl,
    this.categoryName,
    this.quantity = 1,
  });

  double get totalPrice => price * quantity;
}
