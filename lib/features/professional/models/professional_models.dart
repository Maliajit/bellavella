import 'package:bellavella/core/models/data_models.dart';

class ProfessionalBooking {
  final String id;
  final String clientName;
  final String serviceName;
  final String time;
  final double totalPrice;
  final String address;
  final BookingStatus status;

  ProfessionalBooking({
    required this.id,
    required this.clientName,
    required this.serviceName,
    required this.time,
    required this.totalPrice,
    required this.address,
    required this.status,
  });

  factory ProfessionalBooking.fromJson(Map<String, dynamic> json) {
    return ProfessionalBooking(
      id: json['id']?.toString() ?? '',
      clientName: json['client_name'] ?? 'Unknown',
      serviceName: json['service_name'] ?? 'Service',
      time: json['time'] ?? '',
      totalPrice: (json['total_price'] ?? 0.0).toDouble(),
      address: json['address'] ?? 'No address provided',
      status: BookingStatus.values.firstWhere(
        (e) => e.name == json['status'],
        orElse: () => BookingStatus.requested,
      ),
    );
  }
}

class ProfessionalDashboardStats {
  final double todayEarnings;
  final double rating;
  final int activeJobsCount;
  final double distanceToJob;
  final String? activeJobStatus;
  final List<ProfessionalBooking> recentBookings;

  ProfessionalDashboardStats({
    required this.todayEarnings,
    required this.rating,
    required this.activeJobsCount,
    required this.distanceToJob,
    this.activeJobStatus,
    required this.recentBookings,
  });

  factory ProfessionalDashboardStats.fromJson(Map<String, dynamic> json) {
    return ProfessionalDashboardStats(
      todayEarnings: (json['today_earnings'] ?? 0.0).toDouble(),
      rating: (json['rating'] ?? 0.0).toDouble(),
      activeJobsCount: json['active_jobs_count'] ?? 0,
      distanceToJob: (json['distance_to_job'] ?? 0.0).toDouble(),
      activeJobStatus: json['status'],
      recentBookings: (json['recent_bookings'] as List? ?? [])
          .map((i) => ProfessionalBooking.fromJson(i))
          .toList(),
    );
  }
}

class ProfessionalWallet {
  final double balance;
  final List<Transaction> transactions;

  ProfessionalWallet({
    required this.balance,
    required this.transactions,
  });

  factory ProfessionalWallet.fromJson(Map<String, dynamic> json) {
    return ProfessionalWallet(
      balance: (json['balance'] ?? 0.0).toDouble(),
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
      amount: (json['amount'] ?? 0.0).toDouble(),
      type: json['type'] ?? 'credit',
      date: json['created_at'] ?? '',
      description: json['description'] ?? '',
    );
  }
}
