import 'package:bellavella/core/models/data_models.dart';
import 'package:bellavella/core/utils/parser_util.dart';

enum JobStep {
  arrived,
  scanKit,
  service,
  payment,
  complete
}

class ProfessionalBooking {
  final String id;
  final String clientName;
  final String serviceName;
  final String time;
  final String date;
  final double totalPrice;
  final String address;
  final BookingStatus status;
  final String currentStep; // Added field
  final DateTime? serviceStartedAt;
  final DateTime? acceptedAt;
  final DateTime? assignedAt;
  final DateTime? onTheWayAt;
  final DateTime? arrivedAt;
  final DateTime? completedAt;
  final DateTime? cancelledAt;
  final double? lat;
  final double? lng;
  final String phone; // Customer's phone number for the Call button

  ProfessionalBooking({
    required this.id,
    required this.clientName,
    required this.serviceName,
    required this.time,
    required this.date,
    required this.totalPrice,
    required this.address,
    required this.status,
    this.currentStep = '', // Added to constructor
    this.serviceStartedAt,
    this.acceptedAt,
    this.assignedAt,
    this.onTheWayAt,
    this.arrivedAt,
    this.completedAt,
    this.cancelledAt,
    this.lat,
    this.lng,
    this.phone = '',
  });

  ProfessionalBooking copyWith({
    String? id,
    String? clientName,
    String? serviceName,
    String? time,
    String? date,
    double? totalPrice,
    String? address,
    BookingStatus? status,
    String? currentStep, // Added to copyWith
    DateTime? serviceStartedAt,
    DateTime? acceptedAt,
    DateTime? assignedAt,
    DateTime? onTheWayAt,
    DateTime? arrivedAt,
    DateTime? completedAt,
    DateTime? cancelledAt,
    double? lat,
    double? lng,
    String? phone,
  }) {
    return ProfessionalBooking(
      id: id ?? this.id,
      clientName: clientName ?? this.clientName,
      serviceName: serviceName ?? this.serviceName,
      time: time ?? this.time,
      date: date ?? this.date,
      totalPrice: totalPrice ?? this.totalPrice,
      address: address ?? this.address,
      status: status ?? this.status,
      currentStep: currentStep ?? this.currentStep, // Added to copyWith return
      serviceStartedAt: serviceStartedAt ?? this.serviceStartedAt,
      acceptedAt: acceptedAt ?? this.acceptedAt,
      assignedAt: assignedAt ?? this.assignedAt,
      onTheWayAt: onTheWayAt ?? this.onTheWayAt,
      arrivedAt: arrivedAt ?? this.arrivedAt,
      completedAt: completedAt ?? this.completedAt,
      cancelledAt: cancelledAt ?? this.cancelledAt,
      lat: lat ?? this.lat,
      lng: lng ?? this.lng,
      phone: phone ?? this.phone,
    );
  }

  bool get isActive {
    // A job is active only if it is in an ongoing workflow state
    final activeStatuses = [
      BookingStatus.assigned,
      BookingStatus.accepted,
      BookingStatus.onTheWay,
      BookingStatus.arrived,
      BookingStatus.scanKit,
      BookingStatus.inProgress,
      BookingStatus.paymentPending,
    ];
    return activeStatuses.contains(status);
  }

  bool get isToday {
    try {
      if (date.isEmpty) return false;
      final now = DateTime.now();
      final bookingDate = DateTime.parse(date);
      return bookingDate.year == now.year &&
             bookingDate.month == now.month &&
             bookingDate.day == now.day;
    } catch (e) {
      // Fallback if date string is not ISO format (e.g. contains "Today")
      return date.toLowerCase().contains('today') || time.toLowerCase().contains('today');
    }
  }

  factory ProfessionalBooking.empty() => ProfessionalBooking(
    id: '', 
    clientName: 'Unknown', 
    serviceName: 'Service', 
    time: '', 
    date: '', 
    totalPrice: 0, 
    address: '', 
    status: BookingStatus.requested,
    currentStep: '', // Added to empty factory
    serviceStartedAt: null,
    acceptedAt: null,
    assignedAt: null,
    onTheWayAt: null,
    arrivedAt: null,
    completedAt: null,
    cancelledAt: null,
    lat: null,
    lng: null,
  );

  factory ProfessionalBooking.fromJson(dynamic json) {
    if (json is! Map) {
      return ProfessionalBooking(id: '', clientName: 'Unknown', serviceName: 'Service', time: '', date: '', totalPrice: 0, address: '', status: BookingStatus.requested, currentStep: '');
    }
    // Backend uses 'customer_name', 'slot' as time, 'price' as total_price
    String statusStr = (json['status'] ?? '').toString().toLowerCase().trim().replaceAll(' ', '_');
    BookingStatus status = BookingStatus.requested;
    
    switch (statusStr) {
      case 'assigned':
        status = BookingStatus.assigned;        // Dispatched but NOT yet accepted
        break;
      case 'confirmed':
      case 'accepted':
        status = BookingStatus.accepted;        // Professional accepted ✅ show job card
        break;
      case 'on_the_way':
      case 'on_way':
      case 'started_journey':
        status = BookingStatus.onTheWay;        // Journey started ✅ show job card
        break;
      case 'arrived':
        status = BookingStatus.arrived;         // At location ✅ show job card
        break;
      case 'scan_kit':
      case 'kit_scan':
      case 'scanning_kit':
        status = BookingStatus.scanKit;         // Scanning kit ✅ show job card
        break;
      case 'in_progress':
      case 'inprogress':
      case 'service_started':
        status = BookingStatus.inProgress;         // Service underway ✅ show job card
        break;
      case 'payment_pending':
      case 'paymentpending':
        status = BookingStatus.paymentPending;  // Service done, wait for payment ✅ show job card
        break;
      case 'completed':
        status = BookingStatus.completed;       // Done — remove card
        break;
      case 'rejected':
      case 'cancelled':
      case 'canceled':
        status = BookingStatus.cancelled;       // Rejected/cancelled — no card
        break;
      default:
        status = BookingStatus.requested;
        break;
    }


    return ProfessionalBooking(
      id: json['id']?.toString() ?? '',
      clientName: (json['customer_name'] ?? json['client_name'] ?? 'Unknown').toString(),
      serviceName: (json['service_name'] ?? 'Service').toString(),
      time: (json['slot'] ?? json['time'] ?? 'Asap').toString(),
      date: (json['booking_date'] ?? json['date'] ?? '').toString(),
      totalPrice: ParserUtil.safeParseDouble(json['price'] ?? json['total_price']),
      address: (json['address'] ?? json['city'] ?? 'No address provided').toString(),
      status: status,
      currentStep: (json['current_step'] ?? '').toString(), // Added to fromJson
      serviceStartedAt: json['service_started_at'] != null 
          ? DateTime.tryParse(json['service_started_at'].toString()) 
          : null,
      acceptedAt: json['accepted_at'] != null
          ? DateTime.tryParse(json['accepted_at'].toString())
          : null,
      assignedAt: json['assigned_at'] != null
          ? DateTime.tryParse(json['assigned_at'].toString())
          : null,
      onTheWayAt: json['on_the_way_at'] != null
          ? DateTime.tryParse(json['on_the_way_at'].toString())
          : null,
      arrivedAt: json['arrived_at'] != null
          ? DateTime.tryParse(json['arrived_at'].toString())
          : null,
      completedAt: json['completed_at'] != null
          ? DateTime.tryParse(json['completed_at'].toString())
          : null,
      cancelledAt: json['cancelled_at'] != null
          ? DateTime.tryParse(json['cancelled_at'].toString())
          : null,
      lat: ParserUtil.safeParseDouble(json['lat']),
      lng: ParserUtil.safeParseDouble(json['lng']),
      phone: (json['customer_phone'] ?? json['phone'] ?? '').toString(),
    );
  }
}

class ShiftInfo {
  final DateTime? startTime;
  final DateTime? endTime;
  final int remainingSeconds;
  final bool isActive;
  final double progress;

  ShiftInfo({
    this.startTime,
    this.endTime,
    this.remainingSeconds = 0,
    this.isActive = false,
    this.progress = 0,
  });

  factory ShiftInfo.fromJson(dynamic json) {
    if (json is! Map) return ShiftInfo();
    return ShiftInfo(
      startTime: json['start_time'] != null ? DateTime.tryParse(json['start_time'].toString()) : null,
      endTime: json['end_time'] != null ? DateTime.tryParse(json['end_time'].toString()) : null,
      remainingSeconds: int.tryParse(json['remaining_seconds']?.toString() ?? '0') ?? 0,
      isActive: json['is_active'] == true,
      progress: ParserUtil.safeParseDouble(json['progress']),
    );
  }
}

class ProfessionalDashboardStats {
  final double todayEarnings;
  final double totalEarnings;
  final double walletBalance;
  final int totalBookings;
  final double rating;
  final int activeJobsCount;
  final int kitCount;
  final double distanceToJob;
  final String? activeJobStatus;
  final bool isOnline;
  final int remainingSeconds;
  final double shiftProgress;
  final int shiftDuration;
  final String? sessionId;
  final ShiftInfo? shiftInfo;
  final double availableBalance;
  final double pendingBalance;
  final int withdrawDelayDays;
  final List<ProfessionalBooking> recentBookings;

  ProfessionalDashboardStats({
    required this.todayEarnings,
    required this.totalEarnings,
    this.walletBalance = 0,
    required this.totalBookings,
    required this.rating,
    required this.activeJobsCount,
    this.kitCount = 0,
    required this.distanceToJob,
    this.activeJobStatus,
    this.isOnline = false,
    this.remainingSeconds = 0,
    this.shiftProgress = 0,
    this.shiftDuration = 480,
    this.sessionId,
    this.shiftInfo,
    this.availableBalance = 0,
    this.pendingBalance = 0,
    this.withdrawDelayDays = 3,
    required this.recentBookings,
  });

  factory ProfessionalDashboardStats.fromJson(dynamic json) {
    if (json is! Map) {
      return ProfessionalDashboardStats(todayEarnings: 0, totalEarnings: 0, totalBookings: 0, rating: 0, activeJobsCount: 0, distanceToJob: 0, recentBookings: []);
    }
    // Safe parsing for recent bookings (handle both List and Paginated Map)
    List<ProfessionalBooking> bookingsList = [];
    final jsonBookings = json['todays_bookings'] ?? json['recent_bookings'];
    
    if (jsonBookings is List) {
      bookingsList = jsonBookings.map((i) => ProfessionalBooking.fromJson(i)).toList();
    } else if (jsonBookings is Map && jsonBookings['data'] is List) {
      bookingsList = (jsonBookings['data'] as List).map((i) => ProfessionalBooking.fromJson(i)).toList();
    }

    return ProfessionalDashboardStats(
      todayEarnings: ParserUtil.safeParseDouble(json['todays_earnings'] ?? json['today_earnings']),
      totalEarnings: ParserUtil.safeParseDouble(json['total_earnings'] ?? json['earnings']),
      walletBalance: ParserUtil.safeParseDouble(json['wallet_balance']),
      totalBookings: int.tryParse((json['total_orders'] ?? json['total_bookings'])?.toString() ?? '0') ?? 0,
      rating: ParserUtil.safeParseDouble(json['rating']),
      activeJobsCount: int.tryParse((json['pending_requests'] ?? json['active_jobs_count'])?.toString() ?? '0') ?? 0,
      kitCount: int.tryParse(json['kit_count']?.toString() ?? '0') ?? 0,
      distanceToJob: ParserUtil.safeParseDouble(json['distance_to_job']),
      activeJobStatus: json['status']?.toString(),
      isOnline: json['is_online'] == true,
      remainingSeconds: json['shift_info'] != null 
          ? (int.tryParse(json['shift_info']['remaining_seconds']?.toString() ?? '0') ?? 0)
          : (int.tryParse(json['remaining_seconds']?.toString() ?? '0') ?? 0),
      shiftProgress: json['shift_info'] != null 
          ? ParserUtil.safeParseDouble(json['shift_info']['progress'])
          : ParserUtil.safeParseDouble(json['shift_progress']),
      shiftDuration: int.tryParse(json['shift_duration']?.toString() ?? '480') ?? 480,
      sessionId: json['session_id']?.toString(),
      shiftInfo: json['shift_info'] != null ? ShiftInfo.fromJson(json['shift_info']) : null,
      availableBalance: ParserUtil.safeParseDouble(json['available_balance']),
      pendingBalance: ParserUtil.safeParseDouble(json['pending_balance']),
      withdrawDelayDays: int.tryParse(json['withdraw_delay_days']?.toString() ?? '3') ?? 3,
      recentBookings: bookingsList,
    );
  }
}

class WalletTransaction {
  final String id;
  final String description;
  final String date;
  final double amount;
  final String type;
  final String displayAmount;
  final DateTime? createdAt;

  WalletTransaction({
    required this.id,
    required this.description,
    required this.date,
    required this.amount,
    required this.type,
    this.displayAmount = '',
    this.createdAt,
  });

  factory WalletTransaction.fromJson(dynamic json) {
    if (json is! Map) {
      return WalletTransaction(
        id: '',
        description: 'Transaction',
        date: '',
        amount: 0,
        type: 'credit',
      );
    }

    return WalletTransaction(
      id: (json['id'] ?? '').toString(),
      description: (json['title'] ?? json['description'] ?? 'Transaction').toString(),
      date: (json['subtitle'] ?? json['date'] ?? '').toString(),
      amount: ParserUtil.safeParseDouble(json['amount']),
      type: (json['type'] ?? 'credit').toString(),
      displayAmount: (json['display_amount'] ?? '').toString(),
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'].toString())
          : null,
    );
  }
}

class ProfessionalWallet {
  final double cashBalance;
  final double availableBalance;
  final double pendingBalance;
  final double depositBalance;
  final double earningsBalance;
  final double totalBalance;
  final int withdrawDelayDays;
  final bool canWithdraw;
  final DateTime? nextWithdrawalAt;
  final int remainingSeconds;
  final int coinBalance;
  final double activeBalance;
  final double todayEarnings;
  final double weeklyEarnings;
  final double monthlyEarnings;
  final int totalCompletedJobs;
  final List<WalletTransaction> transactions;
  final List<WalletTransaction> kitOrders;

  ProfessionalWallet({
    this.cashBalance = 0,
    this.availableBalance = 0,
    this.pendingBalance = 0,
    this.depositBalance = 0,
    this.earningsBalance = 0,
    this.totalBalance = 0,
    this.withdrawDelayDays = 7,
    this.canWithdraw = true,
    this.nextWithdrawalAt,
    this.remainingSeconds = 0,
    this.coinBalance = 0,
    this.activeBalance = 0,
    this.todayEarnings = 0,
    this.weeklyEarnings = 0,
    this.monthlyEarnings = 0,
    this.totalCompletedJobs = 0,
    this.transactions = const [],
    this.kitOrders = const [],
  });

  double get lockedBalance => pendingBalance;
  int get totalJobs => totalCompletedJobs;
  int get coins => coinBalance;
  int get kits => kitOrders.fold<int>(0, (sum, item) => sum + item.amount.toInt());

  factory ProfessionalWallet.fromJson(dynamic json) {
    if (json is! Map) {
      return ProfessionalWallet();
    }

    final txList = json['transactions'] is List ? json['transactions'] as List : const [];
    final kitOrderList = json['kit_orders'] is List ? json['kit_orders'] as List : const [];

    return ProfessionalWallet(
      cashBalance: ParserUtil.safeParseDouble(json['cash_balance'] ?? json['total_balance']),
      availableBalance: ParserUtil.safeParseDouble(json['available_balance']),
      pendingBalance: ParserUtil.safeParseDouble(json['pending_balance'] ?? json['locked_balance']),
      depositBalance: ParserUtil.safeParseDouble(json['deposit_balance']),
      earningsBalance: ParserUtil.safeParseDouble(json['earnings_balance']),
      totalBalance: ParserUtil.safeParseDouble(json['total_balance'] ?? json['cash_balance']),
      withdrawDelayDays: int.tryParse(json['withdraw_delay_days']?.toString() ?? '7') ?? 7,
      canWithdraw: json['can_withdraw'] == true,
      nextWithdrawalAt: json['next_withdrawal_at'] != null
          ? DateTime.tryParse(json['next_withdrawal_at'].toString())
          : null,
      remainingSeconds: int.tryParse(json['remaining_seconds']?.toString() ?? '0') ?? 0,
      coinBalance: int.tryParse((json['coin_balance'] ?? json['coins_balance'])?.toString() ?? '0') ?? 0,
      activeBalance: ParserUtil.safeParseDouble(json['active_balance']),
      todayEarnings: ParserUtil.safeParseDouble(json['today_earnings']),
      weeklyEarnings: ParserUtil.safeParseDouble(json['weekly_earnings']),
      monthlyEarnings: ParserUtil.safeParseDouble(json['monthly_earnings']),
      totalCompletedJobs: int.tryParse(json['total_completed_jobs']?.toString() ?? '0') ?? 0,
      transactions: txList.map((e) => WalletTransaction.fromJson(e)).toList(),
      kitOrders: kitOrderList.map((e) {
        if (e is! Map) {
          return WalletTransaction(
            id: '',
            description: 'Kit Assigned',
            date: '',
            amount: 0,
            type: 'credit',
          );
        }

        return WalletTransaction(
          id: (e['id'] ?? '').toString(),
          description: (e['title'] ?? e['description'] ?? 'Kit Assigned').toString(),
          date: (e['created_at'] ?? e['date'] ?? '').toString(),
          amount: ParserUtil.safeParseDouble(e['quantity'] ?? e['amount']),
          type: 'credit',
        );
      }).toList(),
    );
  }
}

class LeaderboardItem {
  final int id;
  final String name;
  final String role;
  final String image;
  final int completedJobs;
  final int rank;

  LeaderboardItem({
    required this.id,
    required this.name,
    required this.role,
    required this.image,
    required this.completedJobs,
    required this.rank,
  });

  factory LeaderboardItem.fromJson(Map<String, dynamic> json) {
    return LeaderboardItem(
      id: int.tryParse(json['id']?.toString() ?? '0') ?? 0,
      name: (json['name'] ?? 'Professional').toString(),
      role: (json['role'] ?? 'Partner').toString(),
      image: (json['image'] ?? '').toString(),
      completedJobs: int.tryParse(json['completed_jobs_count']?.toString() ?? '0') ?? 0,
      rank: int.tryParse(json['rank']?.toString() ?? '0') ?? 0,
    );
  }
}



class KitProductModel {
  final int id;
  final String name;
  final String category;
  final double price;
  final String description;
  final String image;
  final String? icon;
  final bool isPremium;
  final int stock;

  KitProductModel({
    required this.id,
    required this.name,
    required this.category,
    required this.price,
    required this.description,
    required this.image,
    this.icon,
    this.isPremium = false,
    required this.stock,
  });

  factory KitProductModel.fromJson(Map<String, dynamic> json) {
    return KitProductModel(
      id: int.tryParse(json['id']?.toString() ?? '0') ?? 0,
      name: json['name'] ?? 'Unknown Kit',
      category: json['category']?['name'] ?? 'General',
      price: ParserUtil.safeParseDouble(json['price']),
      description: json['description'] ?? (json['brand'] != null ? 'Brand: ${json['brand']}' : 'No description available.'),
      image: json['image_url'] ?? 'https://plus.unsplash.com/premium_photo-1661340702301-53a479f3781f?q=80\u0026w=1486\u0026auto=format\u0026fit=crop',
      icon: json['icon'] ?? '✨',
      isPremium: (json['price'] != null && ParserUtil.safeParseDouble(json['price']) > 800),
      stock: int.tryParse(json['total_stock']?.toString() ?? '0') ?? 0,
    );
  }
}

class KitOrderModel {
  final int id;
  final int quantity;
  final String status;
  final String? notes;
  final String assignedAt;
  final String productName;
  final String productImage;
  final double productPrice;
  final double totalAmount;
  final String paymentId;
  final String paymentStatus;
  final String paymentMethod;
  final String orderStatus;

  KitOrderModel({
    required this.id,
    required this.quantity,
    required this.status,
    this.notes,
    required this.assignedAt,
    required this.productName,
    required this.productImage,
    required this.productPrice,
    this.totalAmount = 0,
    this.paymentId = '',
    this.paymentStatus = 'Pending',
    this.paymentMethod = '',
    this.orderStatus = 'Processing',
  });

  factory KitOrderModel.fromJson(dynamic json) {
    if (json is! Map) {
      return KitOrderModel(id: 0, quantity: 1, status: 'Pending', assignedAt: '', productName: 'Unknown', productImage: '', productPrice: 0);
    }
    final product = json['product'] ?? {};
    return KitOrderModel(
      id: int.tryParse(json['id']?.toString() ?? '0') ?? 0,
      quantity: int.tryParse(json['quantity']?.toString() ?? '1') ?? 1,
      status: (json['status'] ?? 'Pending').toString(),
      notes: json['notes']?.toString(),
      assignedAt: (json['assigned_at'] ?? json['created_at'] ?? '').toString(),
      productName: (product['name'] ?? 'Unknown Kit').toString(),
      productImage: (product['image_url'] ?? '').toString(),
      productPrice: ParserUtil.safeParseDouble(product['price']),
      totalAmount: ParserUtil.safeParseDouble(json['total_amount'] ?? product['price']),
      paymentId: (json['payment_id'] ?? '').toString(),
      paymentStatus: (json['payment_status'] ?? 'Pending').toString(),
      paymentMethod: (json['payment_method'] ?? '').toString(),
      orderStatus: (json['order_status'] ?? 'Processing').toString(),
    );
  }
}

class ReferralStats {
  final String referralCode;
  final int totalReferrals;
  final double totalEarnings;
  final int pendingReferrals;
  final int referrerReward;
  final int referredReward;
  final List<ReferralHistory> history;

  ReferralStats({
    required this.referralCode,
    required this.totalReferrals,
    required this.totalEarnings,
    required this.pendingReferrals,
    required this.referrerReward,
    required this.referredReward,
    required this.history,
  });

  factory ReferralStats.fromJson(dynamic json) {
    if (json is! Map) {
      return ReferralStats(
        referralCode: '',
        totalReferrals: 0,
        totalEarnings: 0,
        pendingReferrals: 0,
        referrerReward: 0,
        referredReward: 0,
        history: [],
      );
    }
    // Safe parsing for history
    List<ReferralHistory> historyList = [];
    final jsonHistory = json['history'];
    if (jsonHistory is List) {
      historyList = jsonHistory.map((i) => ReferralHistory.fromJson(i)).toList();
    } else if (jsonHistory is Map && jsonHistory['data'] is List) {
      historyList = (jsonHistory['data'] as List).map((i) => ReferralHistory.fromJson(i)).toList();
    }

    return ReferralStats(
      referralCode: (json['referral_code'] ?? '').toString(),
      totalReferrals: int.tryParse(json['total_referrals']?.toString() ?? '0') ?? 0,
      totalEarnings: ParserUtil.safeParseDouble(json['total_earnings']),
      pendingReferrals: int.tryParse(json['pending_referrals']?.toString() ?? '0') ?? 0,
      referrerReward: int.tryParse(json['referrer_reward']?.toString() ?? '0') ?? 0,
      referredReward: int.tryParse(json['referred_reward']?.toString() ?? '0') ?? 0,
      history: historyList,
    );
  }
}

class ReferralHistory {
  final String id;
  final String phone;
  final String status;
  final double amount;
  final String date;
  final String referredName;

  ReferralHistory({
    required this.id,
    required this.phone,
    required this.status,
    required this.amount,
    required this.date,
    required this.referredName,
  });

  factory ReferralHistory.fromJson(dynamic json) {
    if (json is! Map) {
      return ReferralHistory(id: '', phone: '', status: '', amount: 0, date: '', referredName: '');
    }
    return ReferralHistory(
      id: (json['id'] ?? '').toString(),
      phone: (json['phone'] ?? '').toString(),
      status: (json['status'] ?? 'pending').toString(),
      amount: ParserUtil.safeParseDouble(json['amount']),
      date: (json['date'] ?? '').toString(),
      referredName: (json['referred_name'] ?? 'Unknown').toString(),
    );
  }
}
