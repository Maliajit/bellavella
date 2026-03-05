class Category {
  final String id;
  final String name;
  final String iconPath;

  Category({required this.id, required this.name, required this.iconPath});

  factory Category.fromJson(Map<String, dynamic> json) {
    return Category(
      id: json['id']?.toString() ?? '',
      name: json['name'] ?? '',
      iconPath: json['icon_path'] ?? '',
    );
  }
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

  factory Service.fromJson(Map<String, dynamic> json) {
    return Service(
      id: json['id']?.toString() ?? '',
      categoryId: json['category_id']?.toString() ?? '',
      name: json['name'] ?? '',
      description: json['description'] ?? '',
      price: (json['price'] ?? 0.0).toDouble(),
      duration: json['duration'] ?? '',
      includedItems: (json['included_items'] as List? ?? []).map((e) => e.toString()).toList(),
      imageUrl: json['image_url'] ?? '',
    );
  }
}

class Professional {
  final String id;
  final String name;
  final String photoUrl;
  final double rating;
  final String phone;
  final List<Service> services;

  Professional({
    required this.id,
    required this.name,
    required this.photoUrl,
    required this.rating,
    required this.phone,
    this.services = const [],
  });

  factory Professional.fromJson(Map<String, dynamic> json) {
    return Professional(
      id: json['id']?.toString() ?? '',
      name: json['name'] ?? 'Professional',
      photoUrl: json['photo_url'] ?? '',
      rating: (json['rating'] ?? 0.0).toDouble(),
      phone: json['phone'] ?? '',
      services: (json['services'] as List? ?? [])
          .map((i) => Service.fromJson(i))
          .toList(),
    );
  }
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

  factory Booking.fromJson(Map<String, dynamic> json) {
    return Booking(
      id: json['id']?.toString() ?? '',
      service: Service.fromJson(json['service'] ?? {}),
      dateTime: json['date_time'] != null ? DateTime.parse(json['date_time']) : DateTime.now(),
      address: json['address'] ?? '',
      status: BookingStatus.values.firstWhere(
        (e) => e.name == json['status'],
        orElse: () => BookingStatus.requested,
      ),
      totalPrice: (json['total_price'] ?? 0.0).toDouble(),
      professional: json['professional'] != null ? Professional.fromJson(json['professional']) : null,
      lat: (json['lat'] ?? 0.0).toDouble(),
      lng: (json['lng'] ?? 0.0).toDouble(),
      arrivalCode: json['arrival_code'],
      paymentCode: json['payment_code'],
    );
  }
}
