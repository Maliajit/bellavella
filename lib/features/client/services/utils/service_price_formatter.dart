String formatRupees(double amount, {bool from = false}) {
  final prefix = from ? 'From ' : '';
  return '$prefix₹${amount.toStringAsFixed(0)}';
}
