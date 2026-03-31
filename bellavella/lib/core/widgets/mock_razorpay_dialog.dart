import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:razorpay_flutter/razorpay_flutter.dart';

class MockRazorpayDialog extends StatelessWidget {
  final Map<String, dynamic> options;
  final Function(PaymentSuccessResponse) onSuccess;
  final Function(PaymentFailureResponse) onFailure;

  const MockRazorpayDialog({
    super.key,
    required this.options,
    required this.onSuccess,
    required this.onFailure,
  });

  static Future<void> show(
    BuildContext context, {
    required Map<String, dynamic> options,
    required Function(PaymentSuccessResponse) onSuccess,
    required Function(PaymentFailureResponse) onFailure,
  }) {
    return showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => MockRazorpayDialog(
        options: options,
        onSuccess: onSuccess,
        onFailure: onFailure,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final String amount = ((options['amount'] ?? 0) / 100).toStringAsFixed(2);
    final String name = options['name'] ?? 'BellaVella';
    final String description = options['description'] ?? 'Payment';
    final String orderId = options['order_id'] ?? 'order_mock_123';

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 24,
      backgroundColor: Colors.white,
      child: Container(
        width: 400,
        padding: const EdgeInsets.symmetric(vertical: 0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(20),
              decoration: const BoxDecoration(
                color: Color(0xFF2E3440),
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(16),
                  topRight: Radius.circular(16),
                ),
              ),
              child: Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Center(
                      child: Text(
                        name[0],
                        style: GoogleFonts.inter(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 20,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          name,
                          style: GoogleFonts.inter(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        Text(
                          description,
                          style: GoogleFonts.inter(
                            color: Colors.white.withOpacity(0.6),
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        '₹$amount',
                        style: GoogleFonts.inter(
                          color: Colors.white,
                          fontWeight: FontWeight.w900,
                          fontSize: 18,
                        ),
                      ),
                      Text(
                        'MOCK MODE',
                        style: GoogleFonts.inter(
                          color: Colors.orange,
                          fontWeight: FontWeight.bold,
                          fontSize: 9,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Payment Methods Placeholder
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                children: [
                  _methodTile(Icons.qr_code, 'UPI (Google Pay, PhonePe, etc.)'),
                  _methodTile(Icons.credit_card, 'Cards (Visa, MasterCard, RuPay)'),
                  _methodTile(Icons.account_balance, 'Netbanking'),
                  _methodTile(Icons.wallet, 'Wallet'),
                ],
              ),
            ),

            const SizedBox(height: 32),

            // Action Buttons
            Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.pop(context);
                        onSuccess(PaymentSuccessResponse(
                          'pay_mock_${DateTime.now().millisecondsSinceEpoch}',
                          orderId,
                          'mock_sig_$orderId',
                          {},
                        ));
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF3399FF),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        elevation: 0,
                      ),
                      child: Text(
                        'SIMULATE SUCCESS',
                        style: GoogleFonts.inter(fontWeight: FontWeight.w800),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextButton(
                    onPressed: () {
                      Navigator.pop(context);
                      onFailure(PaymentFailureResponse(
                        900,
                        'Payment cancelled by user (Mock)',
                        {},
                      ));
                    },
                    child: Text(
                      'CANCEL PAYMENT',
                      style: GoogleFonts.inter(
                        color: Colors.grey.shade600,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            
            // Footer
            Container(
              padding: const EdgeInsets.symmetric(vertical: 12),
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(16),
                  bottomRight: Radius.circular(16),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.shield_outlined, size: 14, color: Colors.grey.shade400),
                  const SizedBox(width: 6),
                  Text(
                    'Secured by Razorpay (Simulated)',
                    style: GoogleFonts.inter(
                      fontSize: 10,
                      color: Colors.grey.shade500,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _methodTile(IconData icon, String label) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        children: [
          Icon(icon, size: 20, color: Colors.grey.shade400),
          const SizedBox(width: 16),
          Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 13,
              color: Colors.grey.shade600,
              fontWeight: FontWeight.w500,
            ),
          ),
          const Spacer(),
          Icon(Icons.chevron_right, size: 16, color: Colors.grey.shade300),
        ],
      ),
    );
  }
}
