import 'package:bellavella/core/models/wallet_transaction.dart';

class ProfessionalWallet {
  final double availableBalance;
  final double pendingBalance;
  final double depositBalance;
  final double cashBalance;
  final double lockedBalance;
  final double earningsBalance;

  final double todayEarnings;
  final double weeklyEarnings;
  final double monthlyEarnings;

  final int totalJobs;
  final int coins;

  final bool canWithdraw;
  final DateTime? nextWithdrawalAt;
  final int withdrawDelayDays;
  final int remainingSeconds;

  final List<dynamic> kits;
  final List<dynamic> kitOrders;

  final List<WalletTransaction> transactions;

  ProfessionalWallet({
    required this.availableBalance,
    required this.pendingBalance,
    required this.depositBalance,
    required this.cashBalance,
    required this.lockedBalance,
    required this.earningsBalance,
    required this.todayEarnings,
    required this.weeklyEarnings,
    required this.monthlyEarnings,
    required this.totalJobs,
    required this.coins,
    required this.canWithdraw,
    this.nextWithdrawalAt,
    required this.withdrawDelayDays,
    required this.remainingSeconds,
    required this.kits,
    required this.kitOrders,
    required this.transactions,
  });

  factory ProfessionalWallet.fromJson(Map<String, dynamic> json) {
    return ProfessionalWallet(
      availableBalance: (json['available_balance'] ?? 0).toDouble(),
      pendingBalance: (json['pending_balance'] ?? 0).toDouble(),
      depositBalance: (json['deposit_balance'] ?? 0).toDouble(),
      cashBalance: (json['cash_balance'] ?? 0).toDouble(),
      lockedBalance: (json['locked_balance'] ?? 0).toDouble(),
      earningsBalance: (json['earnings_balance'] ?? 0).toDouble(),

      todayEarnings: (json['today_earnings'] ?? 0).toDouble(),
      weeklyEarnings: (json['weekly_earnings'] ?? 0).toDouble(),
      monthlyEarnings: (json['monthly_earnings'] ?? 0).toDouble(),

      totalJobs: json['total_jobs'] ?? 0,
      coins: json['coins'] ?? 0,

      canWithdraw: json['can_withdraw'] ?? false,
      nextWithdrawalAt: json['next_withdrawal_at'] != null 
          ? DateTime.tryParse(json['next_withdrawal_at'].toString()) 
          : null,
      withdrawDelayDays: json['withdraw_delay_days'] ?? 0,
      remainingSeconds: json['remaining_seconds'] ?? 0,

      kits: json['kits'] ?? [],
      kitOrders: json['kit_orders'] ?? [],
      transactions: (json['transactions'] as List? ?? [])
          .map((e) => WalletTransaction.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }

  double get totalBalance => availableBalance + depositBalance + cashBalance;
  int get kitCount => kits.length;
}
