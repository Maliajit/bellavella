class WalletTransaction {
  final String id;
  final String title;
  final String description;
  final String type;
  final double amount;
  final String status;
  final String date;

  WalletTransaction({
    required this.id,
    required this.title,
    required this.description,
    required this.type,
    required this.amount,
    required this.status,
    required this.date,
  });

  factory WalletTransaction.fromJson(Map<String, dynamic> json) {
    return WalletTransaction(
      id: json['id'].toString(),
      title: json['title'] ?? '',
      description: json['title'] ?? '', // Mapping title to description for UI compatibility
      type: json['type'] ?? '',
      amount: (json['amount'] as num? ?? 0).toDouble(),
      status: json['status'] ?? '',
      date: json['created_at'] ?? '',
    );
  }
}
