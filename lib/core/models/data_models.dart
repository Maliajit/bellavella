import 'package:bellavella/core/utils/parser_util.dart';

class Category {
  final String id;
  final String name;
  final String iconPath;

  Category({required this.id, required this.name, required this.iconPath});

  factory Category.fromJson(dynamic json) {
    if (json is! Map) return Category(id: '', name: '', iconPath: '');
    return Category(
      id: json['id']?.toString() ?? '',
      name: (json['name'] ?? '').toString(),
      iconPath: (json['icon_path'] ?? '').toString(),
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

  factory Service.fromJson(dynamic json) {
    if (json is! Map) {
      return Service(id: '', categoryId: '', name: '', description: '', price: 0, duration: '', includedItems: [], imageUrl: '');
    }
    return Service(
      id: json['id']?.toString() ?? '',
      categoryId: json['category_id']?.toString() ?? '',
      name: (json['name'] ?? '').toString(),
      description: (json['description'] ?? '').toString(),
      price: ParserUtil.safeParseDouble(json['price']),
      duration: (json['duration'] ?? '').toString(),
      includedItems: json['included_items'] is List 
        ? (json['included_items'] as List).map((e) => e.toString()).toList() 
        : [],
      imageUrl: (json['image_url'] ?? '').toString(),
    );
  }
}

class PayoutDetails {
  final String accountHolder;
  final String bankName;
  final String accountNumber;
  final String ifsc;
  final String branch;
  final String upiId;

  PayoutDetails({
    this.accountHolder = '',
    this.bankName = '',
    this.accountNumber = '',
    this.ifsc = '',
    this.branch = '',
    this.upiId = '',
  });

  factory PayoutDetails.fromJson(dynamic json) {
    if (json is! Map) return PayoutDetails();
    return PayoutDetails(
      accountHolder: json['account_holder']?.toString() ?? '',
      bankName: json['bank_name']?.toString() ?? '',
      accountNumber: json['account_number']?.toString() ?? '',
      ifsc: json['ifsc']?.toString() ?? '',
      branch: json['branch']?.toString() ?? '',
      upiId: json['upi_id']?.toString() ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
    'account_holder': accountHolder,
    'bank_name': bankName,
    'account_number': accountNumber,
    'ifsc': ifsc,
    'branch': branch,
    'upi_id': upiId,
  };
}

class Professional {
  final String id;
  final String name;
  final String photoUrl;
  final double rating;
  final String phone;
  final String email;
  final String status;
  final String verification;
  final String? experience;
  final String? joined;
  final String? gender;
  final String? dob;
  final String? bio;
  final List<String> languages;
  final String? city;
  final String? serviceArea;
  final double? serviceRadius;
  final List<String> portfolio;
  final PayoutDetails payout;
  final Map<String, dynamic> workingHours;
  final List<Service> services;

  Professional({
    required this.id,
    required this.name,
    required this.photoUrl,
    required this.rating,
    required this.phone,
    this.email = '',
    required this.status,
    required this.verification,
    this.experience,
    this.joined,
    this.gender,
    this.dob,
    this.bio,
    this.languages = const [],
    this.city,
    this.serviceArea,
    this.serviceRadius,
    this.portfolio = const [],
    required this.payout,
    this.workingHours = const {},
    this.services = const [],
  });

  factory Professional.fromJson(dynamic json) {
    if (json is! Map) {
      return Professional(id: '', name: 'Error Loading', photoUrl: '', rating: 0, phone: '', status: '', verification: '', payout: PayoutDetails());
    }
    
    List<Service> services = [];
    final rawServices = json['services'];
    if (rawServices is List) {
      services = rawServices
          .where((i) => i is Map)
          .map<Service>((i) => Service.fromJson(i))
          .toList();
    }

    return Professional(
      id: json['id']?.toString() ?? '',
      name: (json['name'] ?? 'Professional').toString(),
      photoUrl: (json['avatar'] ?? json['photo_url'] ?? '').toString(),
      rating: ParserUtil.safeParseDouble(json['rating']),
      phone: (json['phone'] ?? json['mobile'] ?? '').toString(),
      email: (json['email'] ?? '').toString(),
      status: (json['status'] ?? 'Active').toString(),
      verification: (json['verification'] ?? 'Pending').toString(),
      experience: json['experience']?.toString(),
      joined: json['created_at']?.toString() ?? json['joined']?.toString(),
      gender: json['gender']?.toString(),
      dob: json['dob']?.toString(),
      bio: json['bio']?.toString(),
      languages: json['languages'] is List ? (json['languages'] as List).map((e) => e.toString()).toList() : [],
      city: json['city']?.toString(),
      serviceArea: json['service_area']?.toString(),
      serviceRadius: ParserUtil.safeParseDouble(json['service_radius']),
      portfolio: json['portfolio'] is List ? (json['portfolio'] as List).map((e) => e.toString()).toList() : [],
      payout: PayoutDetails.fromJson(json['payout']),
      workingHours: json['working_hours'] is Map ? Map<String, dynamic>.from(json['working_hours']) : {},
      services: services,
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

  factory Booking.fromJson(dynamic json) {
    if (json is! Map) {
      return Booking(id: '', service: Service.fromJson({}), dateTime: DateTime.now(), address: '', status: BookingStatus.requested, totalPrice: 0);
    }
    return Booking(
      id: json['id']?.toString() ?? '',
      service: Service.fromJson(json['service']),
      dateTime: json['date_time'] != null ? DateTime.parse(json['date_time'].toString()) : DateTime.now(),
      address: (json['address'] ?? '').toString(),
      status: BookingStatus.values.firstWhere(
        (e) => e.name == json['status']?.toString(),
        orElse: () => BookingStatus.requested,
      ),
      totalPrice: ParserUtil.safeParseDouble(json['total_price']),
      professional: json['professional'] != null ? Professional.fromJson(json['professional']) : null,
      lat: ParserUtil.safeParseDouble(json['lat']),
      lng: ParserUtil.safeParseDouble(json['lng']),
      arrivalCode: json['arrival_code']?.toString(),
      paymentCode: json['payment_code']?.toString(),
    );
  }
}
