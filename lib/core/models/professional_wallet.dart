import 'package:flutter/foundation.dart';
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
  final DateTime serverTime;
  final bool withdrawUnlocked;
  final String? lockReason;
  final DateTime? unlockDate;
  final int daysRemaining;
  final int cooldownDays;
  final bool isProfessional;

  final List<WalletKitItem> kits;
  final List<WalletKitOrder> kitOrders;

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
    required this.serverTime,
    this.withdrawUnlocked = true,
    this.lockReason,
    this.unlockDate,
    this.daysRemaining = 0,
    this.cooldownDays = 7,
    this.isProfessional = false,
    required this.kits,
    required this.kitOrders,
    required this.transactions,
  });

  factory ProfessionalWallet.fromJson(Map<String, dynamic> json) {
    if (kDebugMode) {
      debugPrint('ProfessionalWallet.fromJson data: $json');
    }

    final remainingSeconds = (json['remaining_seconds'] as num? ?? 0)
        .toInt()
        .clamp(0, 1 << 31);
    final unlockDate = json['unlock_date'] != null
        ? DateTime.tryParse(json['unlock_date'].toString())
        : (json['next_withdrawal_at'] != null
              ? DateTime.tryParse(json['next_withdrawal_at'].toString())
              : null);
    final withdrawUnlocked = json['withdraw_unlocked'] is bool
        ? json['withdraw_unlocked'] as bool
        : (json['can_withdraw'] is bool
              ? json['can_withdraw'] as bool
              : remainingSeconds == 0);
    final canWithdraw = json['can_withdraw'] is bool
        ? json['can_withdraw'] as bool
        : (withdrawUnlocked || remainingSeconds == 0);

    return ProfessionalWallet(
      availableBalance: (json['available_balance'] as num? ?? 0).toDouble(),
      pendingBalance: (json['pending_balance'] as num? ?? 0).toDouble(),
      depositBalance: (json['deposit_balance'] as num? ?? 0).toDouble(),
      cashBalance: (json['cash_balance'] as num? ?? 0).toDouble(),
      lockedBalance: (json['locked_balance'] as num? ?? 0).toDouble(),
      earningsBalance: (json['earnings_balance'] as num? ?? 0).toDouble(),

      todayEarnings: (json['today_earnings'] as num? ?? 0).toDouble(),
      weeklyEarnings: (json['weekly_earnings'] as num? ?? 0).toDouble(),
      monthlyEarnings: (json['monthly_earnings'] as num? ?? 0).toDouble(),

      totalJobs:
          (json['total_jobs'] as num? ??
                  json['total_completed_jobs'] as num? ??
                  0)
              .toInt(),
      coins: (json['coins'] as num? ?? json['coins_balance'] as num? ?? 0)
          .toInt(),

      canWithdraw: canWithdraw,
      nextWithdrawalAt: json['next_withdrawal_at'] != null
          ? DateTime.tryParse(json['next_withdrawal_at'].toString())
          : null,
      withdrawDelayDays: (json['withdraw_delay_days'] as num? ?? 0).toInt(),
      remainingSeconds: remainingSeconds,
      serverTime: json['server_time'] != null
          ? (DateTime.tryParse(json['server_time'].toString()) ??
                DateTime.now().toUtc())
          : DateTime.now().toUtc(),
      withdrawUnlocked: withdrawUnlocked,
      lockReason: json['lock_reason']?.toString(),
      unlockDate: unlockDate,
      daysRemaining: (json['days_remaining'] as num? ?? 0).toInt(),
      cooldownDays:
          (json['cooldown_days'] as num? ??
                  json['withdraw_delay_days'] as num? ??
                  7)
              .toInt(),
      isProfessional: json['is_professional'] ?? false,

      kits: (json['kits'] as List? ?? [])
          .map((e) => WalletKitItem.fromJson(e))
          .toList(),
      kitOrders: (json['kit_orders'] as List? ?? [])
          .map((e) => WalletKitOrder.fromJson(e))
          .toList(),
      transactions: (json['transactions'] as List? ?? [])
          .map((e) => WalletTransaction.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }

  double get totalBalance => availableBalance + depositBalance;
  int get kitCount => kits.length;
}

class WalletKitItem {
  final String name;
  final String status;

  WalletKitItem({required this.name, required this.status});

  factory WalletKitItem.fromJson(dynamic json) {
    if (json is! Map) return WalletKitItem(name: '', status: '');
    return WalletKitItem(
      name: (json['name'] ?? json['product_name'] ?? 'Kit Item').toString(),
      status: (json['status'] ?? 'Active').toString(),
    );
  }
}

class WalletKitOrder {
  final String description;
  final String date;
  final double amount;

  WalletKitOrder({
    required this.description,
    required this.date,
    required this.amount,
  });

  factory WalletKitOrder.fromJson(dynamic json) {
    if (json is! Map)
      return WalletKitOrder(description: '', date: '', amount: 0);
    return WalletKitOrder(
      description: (json['description'] ?? json['title'] ?? 'Kit Assigned')
          .toString(),
      date: (json['date'] ?? json['created_at'] ?? '').toString(),
      amount: (json['amount'] ?? json['quantity'] ?? 0).toDouble(),
    );
  }
}
