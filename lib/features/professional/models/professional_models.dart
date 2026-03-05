import 'package:bellavella/core/models/data_models.dart';
import 'package:bellavella/core/utils/parser_util.dart';

class ProfessionalBooking {
  final String id;
  final String clientName;
  final String serviceName;
  final String time;
  final String date;
  final double totalPrice;
  final String address;
  final BookingStatus status;

  ProfessionalBooking({
    required this.id,
    required this.clientName,
    required this.serviceName,
    required this.time,
    required this.date,
    required this.totalPrice,
    required this.address,
    required this.status,
  });

  factory ProfessionalBooking.fromJson(Map<String, dynamic> json) {
    // Backend uses 'customer_name', 'slot' as time, 'price' as total_price
    String statusStr = (json['status'] ?? '').toString().toLowerCase().trim().replaceAll(' ', '');
    BookingStatus status = BookingStatus.requested;
    
    if (statusStr == 'confirmed' || statusStr == 'assigned' || statusStr == 'accepted') status = BookingStatus.accepted;
    else if (statusStr == 'inprogress' || statusStr == 'started') status = BookingStatus.started;
    else if (statusStr == 'completed') status = BookingStatus.completed;
    else if (statusStr == 'cancelled') status = BookingStatus.cancelled;

    return ProfessionalBooking(
      id: json['id']?.toString() ?? '',
      clientName: json['customer_name'] ?? json['client_name'] ?? 'Unknown',
      serviceName: json['service_name'] ?? 'Service',
      time: json['slot'] ?? json['time'] ?? 'Asap',
      date: json['date'] ?? '',
      totalPrice: ParserUtil.safeParseDouble(json['price'] ?? json['total_price']),
      address: json['city'] ?? json['address'] ?? 'No address provided',
      status: status,
    );
  }
}

class ProfessionalDashboardStats {
  final double todayEarnings;
  final double totalEarnings;
  final int totalBookings;
  final double rating;
  final int activeJobsCount;
  final int kitCount;
  final double distanceToJob;
  final String? activeJobStatus;
  final List<ProfessionalBooking> recentBookings;

  ProfessionalDashboardStats({
    required this.todayEarnings,
    required this.totalEarnings,
    required this.totalBookings,
    required this.rating,
    required this.activeJobsCount,
    this.kitCount = 0,
    required this.distanceToJob,
    this.activeJobStatus,
    required this.recentBookings,
  });

  factory ProfessionalDashboardStats.fromJson(Map<String, dynamic> json) {
    return ProfessionalDashboardStats(
      todayEarnings: ParserUtil.safeParseDouble(json['todays_earnings'] ?? json['today_earnings']),
      totalEarnings: ParserUtil.safeParseDouble(json['total_earnings'] ?? json['earnings']),
      totalBookings: int.tryParse((json['total_orders'] ?? json['total_bookings'])?.toString() ?? '0') ?? 0,
      rating: ParserUtil.safeParseDouble(json['rating']),
      activeJobsCount: int.tryParse((json['pending_requests'] ?? json['active_jobs_count'])?.toString() ?? '0') ?? 0,
      kitCount: int.tryParse(json['kit_count']?.toString() ?? '0') ?? 0,
      distanceToJob: ParserUtil.safeParseDouble(json['distance_to_job']),
      activeJobStatus: json['status'],
      recentBookings: ( (json['todays_bookings'] ?? json['recent_bookings']) as List? ?? [])
          .map((i) => ProfessionalBooking.fromJson(i))
          .toList(),
    );
  }
}

class ProfessionalWallet {
  final double balance;
  final int coins;
  final int kits;
  final List<Transaction> transactions;

  ProfessionalWallet({
    required this.balance,
    required this.coins,
    required this.kits,
    required this.transactions,
  });

  factory ProfessionalWallet.fromJson(Map<String, dynamic> json) {
    return ProfessionalWallet(
      balance: ParserUtil.safeParseDouble(json['cash_balance'] ?? json['balance']),
      coins: int.tryParse((json['coin_balance'] ?? json['coins'])?.toString() ?? '0') ?? 0,
      kits: int.tryParse((json['kit_count'] ?? json['kits'])?.toString() ?? '0') ?? 0,
      transactions: (json['transactions'] as List? ?? [])
          .map((i) => Transaction.fromJson(i))
          .toList(),
    );
  }
}

class Transaction {
  final String id;
  final double amount;
  final String type; // credit, debit
  final String date;
  final String description;

  Transaction({
    required this.id,
    required this.amount,
    required this.type,
    required this.date,
    required this.description,
  });

  factory Transaction.fromJson(Map<String, dynamic> json) {
    return Transaction(
      id: json['id'].toString(),
      amount: ParserUtil.safeParseDouble(json['amount']),
      type: json['type'] ?? 'credit',
      date: json['created_at'] ?? '',
      description: json['description'] ?? '',
    );
  }
}
