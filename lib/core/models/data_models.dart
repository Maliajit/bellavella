import 'package:bellavella/core/utils/parser_util.dart';

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
      price: ParserUtil.safeParseDouble(json['price']),
      duration: json['duration'] ?? '',
      includedItems: (json['included_items'] as List? ?? [])
          .map((e) => e.toString())
          .toList(),
      imageUrl: json['image_url'] ?? '',
    );
  }
}

class Customer {
  final String id;
  final String name;
  final String? email;
  final String mobile;
  final String? avatar;
  final String? dateOfBirth;
  final String status;
  final String? joined;
  final String? referralCode;

  Customer({
    required this.id,
    required this.name,
    this.email,
    required this.mobile,
    this.avatar,
    this.dateOfBirth,
    this.status = 'Active',
    this.joined,
    this.referralCode,
  });

  factory Customer.fromJson(Map<String, dynamic> json) {
    return Customer(
      id: json['id']?.toString() ?? '',
      name: json['name'] ?? '',
      email: json['email'],
      mobile: json['mobile'] ?? '',
      avatar: json['avatar'],
      dateOfBirth: json['date_of_birth'],
      status: json['status'] ?? 'Active',
      joined: json['joined'] ?? json['created_at'],
      referralCode: json['referral_code'],
    );
  }
}

class Professional {
  final String id;
  final String name;
  final String photoUrl;
  final double rating;
  final String phone;
  final String status;
  final String verification;
  final String? experience;
  final String? joined;
  final bool docs;
  final List<Service> services;

  Professional({
    required this.id,
    required this.name,
    required this.photoUrl,
    required this.rating,
    required this.phone,
    required this.status,
    required this.verification,
    this.experience,
    this.joined,
    this.docs = false,
    this.services = const [],
  });

  factory Professional.fromJson(Map<String, dynamic> json) {
    // Backend returns 'avatar' for photo, not 'photo_url'
    // Backend 'services' column is cast as array in Laravel,
    // it might be a list of strings/ints or maps.
    List<Service> services = [];
    final rawServices = json['services'];
    if (rawServices is List) {
      services = rawServices
          .whereType<Map<String, dynamic>>()
          .map<Service>((i) => Service.fromJson(i))
          .toList();
    }

    return Professional(
      id: json['id']?.toString() ?? '',
      name: json['name'] ?? 'Professional',
      photoUrl: json['avatar'] ?? json['photo_url'] ?? '',
      rating: ParserUtil.safeParseDouble(json['rating']),
      phone: json['phone'] ?? json['mobile'] ?? '',
      status: json['status'] ?? 'Active',
      verification: json['verification'] ?? 'Pending',
      experience: json['experience']?.toString(),
      joined: json['created_at']?.toString() ?? json['joined']?.toString(),
      docs: json['docs'] == true || json['docs'] == 1,
      services: services,
    );
  }
}

enum BookingStatus {
  requested,
  accepted,
  onTheWay,
  arrived,
  started,
  completed,
  cancelled,
}

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
      dateTime: json['date_time'] != null
          ? DateTime.parse(json['date_time'])
          : DateTime.now(),
      address: json['address'] ?? '',
      status: BookingStatus.values.firstWhere(
        (e) => e.name == json['status'],
        orElse: () => BookingStatus.requested,
      ),
      totalPrice: ParserUtil.safeParseDouble(json['total_price']),
      professional: json['professional'] != null
          ? Professional.fromJson(json['professional'])
          : null,
      lat: ParserUtil.safeParseDouble(json['lat']),
      lng: ParserUtil.safeParseDouble(json['lng']),
      arrivalCode: json['arrival_code'],
      paymentCode: json['payment_code'],
    );
  }
}

class Wallet {
  final int balance;
  final String walletType;
  final String currencyLabel;
  final String exchangeRate;
  final List<Transaction> transactions;

  Wallet({
    required this.balance,
    this.walletType = 'coin',
    this.currencyLabel = 'BellaVella Coins',
    this.exchangeRate = '1 Coin = ₹1.00',
    required this.transactions,
  });

  factory Wallet.fromJson(Map<String, dynamic> json) {
    return Wallet(
      balance: json['balance'] is num
          ? (json['balance'] as num).toInt()
          : int.tryParse(json['balance'].toString()) ?? 0,
       walletType: json['wallet_type']?.toString() ?? 'coin',
      currencyLabel: json['currency_label']?.toString() ?? 'BellaVella Coins',
      exchangeRate: json['exchange_rate']?.toString() ?? '1 Coin = ₹1.00',
      transactions: (json['transactions'] as List? ?? [])
          .map((e) => Transaction.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
}

class Transaction {
  final String id;
  final String title;
  final String date;
  final int amount;
  final String type; // 'credit' or 'debit'

  Transaction({
    required this.id,
    required this.title,
    required this.date,
    required this.amount,
    required this.type,
  });

  factory Transaction.fromJson(Map<String, dynamic> json) {
    return Transaction(
      id: json['id']?.toString() ?? '',
      title: json['title']?.toString() ?? 'Transaction',
      date: json['date']?.toString() ?? '',
      amount: json['amount'] is num
          ? (json['amount'] as num).toInt()
          : int.tryParse(json['amount'].toString()) ?? 0,
      type: json['type']?.toString().toLowerCase() ?? 'credit',
    );
  }
}

class Address {
  final String id;
  final String label;
  final String houseNumber;
  final String area;
  final String landmark;
  final String city;
  final String pincode;
  final String phone;

  Address({
    required this.id,
    required this.label,
    required this.houseNumber,
    required this.area,
    required this.landmark,
    required this.city,
    required this.pincode,
    required this.phone,
  });

  factory Address.fromJson(Map<String, dynamic> json) {
    return Address(
      id: json['id']?.toString() ?? '',
      label: json['label'] ?? 'Home',
      houseNumber: json['house_number'] ?? '',
      area: json['address'] ?? '', // Map address to area
      landmark: json['landmark'] ?? '',
      city: json['city'] ?? '',
      pincode: json['pincode'] ?? '',
      phone: json['phone'] ?? '',
    );
  }

  String get fullAddress {
    List<String> parts = [];
    if (houseNumber.isNotEmpty) parts.add(houseNumber);
    if (area.isNotEmpty) parts.add(area);
    if (landmark.isNotEmpty) parts.add(landmark);
    if (city.isNotEmpty) parts.add(city);
    if (pincode.isNotEmpty) parts.add(pincode);
    return parts.join(', ');
  }
}
