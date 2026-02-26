class Category {
  final String id;
  final String name;
  final String iconPath;

  Category({required this.id, required this.name, required this.iconPath});
}

class Service {
  final String id;
  final String categoryId;
  final String name;
  final String description;
  final double price;
  final String duration;
  final List<String> includedItems;
  final String imageUrl;

  Service({
    required this.id,
    required this.categoryId,
    required this.name,
    required this.description,
    required this.price,
    required this.duration,
    required this.includedItems,
    required this.imageUrl,
  });
}

class Professional {
  final String id;
  final String name;
  final String photoUrl;
  final double rating;
  final String phone;

  Professional({
    required this.id,
    required this.name,
    required this.photoUrl,
    required this.rating,
    required this.phone,
  });
}

enum BookingStatus { requested, accepted, onTheWay, arrived, started, completed, cancelled }

class Booking {
  final String id;
  final Service service;
  final DateTime dateTime;
  final String address;
  final BookingStatus status;
  final double totalPrice;
  final Professional? professional;
  final double? lat;
  final double? lng;
  final String? arrivalCode;
  final String? paymentCode;

  Booking({
    required this.id,
    required this.service,
    required this.dateTime,
    required this.address,
    required this.status,
    required this.totalPrice,
    this.professional,
    this.lat,
    this.lng,
    this.arrivalCode,
    this.paymentCode,
  });
}
