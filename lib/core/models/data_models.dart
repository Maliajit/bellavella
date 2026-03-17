import 'package:bellavella/core/utils/parser_util.dart';
import 'package:bellavella/core/config/app_config.dart';

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
      includedItems: (json['included_items'] as List? ?? []).map((e) => e.toString()).toList(),
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
  final String verificationStatus;
  final String? bankProofImage;
  final String? upiScreenshot;

  PayoutDetails({
    this.accountHolder = '',
    this.bankName = '',
    this.accountNumber = '',
    this.ifsc = '',
    this.branch = '',
    this.upiId = '',
    this.verificationStatus = 'Pending',
    this.bankProofImage,
    this.upiScreenshot,
  });

  factory PayoutDetails.fromJson(dynamic json, {String verificationStatus = 'Pending', String? bankProofImage, String? upiScreenshot}) {
    if (json is! Map) return PayoutDetails(
      verificationStatus: verificationStatus,
      bankProofImage: bankProofImage,
      upiScreenshot: upiScreenshot,
    );
    return PayoutDetails(
      accountHolder: json['account_holder']?.toString() ?? '',
      bankName: json['bank_name']?.toString() ?? '',
      accountNumber: json['account_number']?.toString() ?? '',
      ifsc: json['ifsc']?.toString() ?? '',
      branch: json['branch']?.toString() ?? '',
      upiId: json['upi_id']?.toString() ?? '',
      verificationStatus: verificationStatus,
      bankProofImage: bankProofImage,
      upiScreenshot: upiScreenshot,
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
  // KYC document URLs
  final String? aadhaarFront;
  final String? aadhaarBack;
  final String? panImg;
  final String? certificateImg;
  final String? selfieUrl;
  final bool isOnline;


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
    this.aadhaarFront,
    this.aadhaarBack,
    this.panImg,
    this.certificateImg,
    this.selfieUrl,
    this.isOnline = false,
  });

  factory Professional.fromJson(dynamic json) {
    if (json is! Map) {
      return Professional(id: '', name: 'Error Loading', photoUrl: '', rating: 0, phone: '', status: '', verification: '', payout: PayoutDetails(), isOnline: false);
    }
    
    List<Service> services = [];
    final rawServices = json['services'];
    if (rawServices is List) {
      services = rawServices
          .where((i) => i is Map)
          .map<Service>((i) => Service.fromJson(i))
          .toList();
    }

    String rawAvatar = (json['avatar'] ?? json['photo_url'] ?? '').toString();
    if (rawAvatar.isNotEmpty) {
      if (rawAvatar.contains('/storage/') || rawAvatar.startsWith('storage/')) {
        final cleanPath = rawAvatar.split('/storage/').last;
        rawAvatar = '${AppConfig.baseUrl}/images/$cleanPath';
      } else if (!rawAvatar.startsWith('http')) {
        final hostUrl = AppConfig.baseUrl.replaceAll(RegExp(r'/api.*'), '');
        if (!rawAvatar.startsWith('/')) rawAvatar = '/$rawAvatar';
        rawAvatar = '$hostUrl$rawAvatar';
      }
    }

    return Professional(
      id: json['id']?.toString() ?? '',
      name: (json['name'] ?? 'Professional').toString(),
      photoUrl: rawAvatar,
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
      payout: PayoutDetails.fromJson(
        json['payout'],
        verificationStatus: json['payout_verification_status']?.toString() ?? 'Pending',
        bankProofImage: _resolveDocUrl(json['bank_proof_image']?.toString()),
        upiScreenshot: _resolveDocUrl(json['upi_screenshot']?.toString()),
      ),
      workingHours: json['working_hours'] is Map ? Map<String, dynamic>.from(json['working_hours']) : {},
      services: services,
      aadhaarFront: _resolveDocUrl(json['aadhaar_front']?.toString()),
      aadhaarBack: _resolveDocUrl(json['aadhaar_back']?.toString()),
      panImg: _resolveDocUrl(json['pan_img']?.toString()),
      certificateImg: _resolveDocUrl(json['certificate_img']?.toString()),
      selfieUrl: _resolveDocUrl(json['selfie']?.toString()),
      isOnline: json['is_online'] == true || json['is_online'] == 1,
    );
  }

  static String? _resolveDocUrl(String? raw) {
    if (raw == null || raw.isEmpty) return null;
    if (raw.startsWith('http')) return raw;
    
    // Normalize path: remove public/ or storage/ if they exist at the start to avoid duplication
    String path = raw;
    if (path.startsWith('public/')) path = path.substring(7);
    if (path.startsWith('/public/')) path = path.substring(8);
    if (path.startsWith('storage/')) path = path.substring(8);
    if (path.startsWith('/storage/')) path = path.substring(9);
    if (path.startsWith('/')) path = path.substring(1);

    final hostUrl = AppConfig.baseUrl.replaceAll(RegExp(r'/api.*'), '');
    return '$hostUrl/storage/$path';
  }
}

enum BookingStatus {
  requested,  // client created booking
  assigned,   // admin dispatched to professional — NOT yet accepted
  accepted,   // professional accepted
  onTheWay,   // professional started journey
  arrived,    // professional arrived
  scanKit,    // scanning professional's kit
  inProgress, // service in progress (started)
  paymentPending, // service finished, waiting for payment
  completed,  // service finished and paid
  cancelled,  // cancelled / rejected
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

  static BookingStatus _parseStatus(String? status) {
    if (status == null) return BookingStatus.requested;
    // Map snake_case from backend to CamelCase enum names
    switch (status) {
      case 'on_the_way': return BookingStatus.onTheWay;
      case 'in_progress': return BookingStatus.inProgress;
      case 'payment_pending': return BookingStatus.paymentPending;
      default:
        return BookingStatus.values.firstWhere(
          (e) => e.name == status,
          orElse: () => BookingStatus.requested,
        );
    }
  }

  factory Booking.fromJson(dynamic json) {
    if (json is! Map) {
      return Booking(id: '', service: Service.fromJson({}), dateTime: DateTime.now(), address: '', status: BookingStatus.requested, totalPrice: 0);
    }
    return Booking(
      id: json['id']?.toString() ?? '',
      service: Service.fromJson(json['service'] ?? {}),
      dateTime: json['date_time'] != null ? DateTime.parse(json['date_time'].toString()) : DateTime.now(),
      address: (json['address'] ?? '').toString(),
      status: _parseStatus(json['status']?.toString()),
      totalPrice: ParserUtil.safeParseDouble(json['total_price']),
      professional: json['professional'] != null
          ? Professional.fromJson(json['professional'])
          : null,
      lat: ParserUtil.safeParseDouble(json['lat']),
      lng: ParserUtil.safeParseDouble(json['lng']),
      arrivalCode: json['arrival_code']?.toString(),
      paymentCode: json['payment_code']?.toString(),
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
  final double? latitude;
  final double? longitude;

  Address({
    required this.id,
    required this.label,
    required this.houseNumber,
    required this.area,
    required this.landmark,
    required this.city,
    required this.pincode,
    required this.phone,
    this.latitude,
    this.longitude,
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
      latitude: ParserUtil.safeParseDouble(
        json['latitude'] ?? json['lat'] ?? json['address_latitude'],
      ),
      longitude: ParserUtil.safeParseDouble(
        json['longitude'] ?? json['lng'] ?? json['address_longitude'],
      ),
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

  String get shortPreview {
    final parts = <String>[];
    if (area.isNotEmpty) parts.add(area);
    if (city.isNotEmpty) parts.add(city);
    if (pincode.isNotEmpty) parts.add(pincode);
    final preview = parts.join(', ');
    return preview.isEmpty ? fullAddress : preview;
  }
}
