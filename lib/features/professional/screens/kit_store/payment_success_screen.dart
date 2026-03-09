import 'package:flutter/material.dart';
import 'package:confetti/confetti.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/router/route_names.dart';
import 'package:bellavella/core/theme/app_theme.dart';

class PaymentSuccessScreen extends StatefulWidget {
  final String orderId;
  final double amount;
  final String kitName;
  final String paymentId;

  const PaymentSuccessScreen({
    super.key,
    required this.orderId,
    required this.amount,
    required this.kitName,
    required this.paymentId,
  });

  @override
  State<PaymentSuccessScreen> createState() => _PaymentSuccessScreenState();
}

class _PaymentSuccessScreenState extends State<PaymentSuccessScreen>
    with SingleTickerProviderStateMixin {
  late final ConfettiController _confetti;
  late final AnimationController _scaleCtrl;
  late final Animation<double> _scaleAnim;

  @override
  void initState() {
    super.initState();
    _confetti = ConfettiController(duration: const Duration(seconds: 3))..play();

    _scaleCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _scaleAnim = CurvedAnimation(parent: _scaleCtrl, curve: Curves.elasticOut);
    Future.delayed(const Duration(milliseconds: 200), _scaleCtrl.forward);
  }

  @override
  void dispose() {
    _confetti.dispose();
    _scaleCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6F7F9),
      body: Stack(
        alignment: Alignment.center,
        children: [
          // Confetti
          Align(
            alignment: Alignment.topCenter,
            child: ConfettiWidget(
              confettiController: _confetti,
              blastDirectionality: BlastDirectionality.explosive,
              emissionFrequency: 0.05,
              numberOfParticles: 20,
              gravity: 0.2,
              colors: [AppTheme.primaryColor, Color(0xFF8B5CF6), Color(0xFF10B981), Color(0xFFF59E0B)],
            ),
          ),

          SafeArea(
            child: Padding(
              padding: EdgeInsets.all(24),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Spacer(),

                  // Animated checkmark
                  ScaleTransition(
                    scale: _scaleAnim,
                    child: Container(
                      width: 100,
                      height: 100,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: LinearGradient(
                          colors: [Color(0xFF10B981), Color(0xFF34D399)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF10B981).withOpacity(0.35),
                            blurRadius: 24,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: const Icon(Icons.check_rounded, color: Colors.white, size: 52),
                    ),
                  ),

                  const SizedBox(height: 28),

                  Text(
                    'Payment Successful!',
                    style: GoogleFonts.poppins(
                      fontSize: 26,
                      fontWeight: FontWeight.w900,
                      color: const Color(0xFF111827),
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Your kit order has been placed successfully.',
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      color: const Color(0xFF9CA3AF),
                      height: 1.5,
                    ),
                    textAlign: TextAlign.center,
                  ),

                  const SizedBox(height: 32),

                  // Order Detail Card
                  Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 14, offset: const Offset(0, 4))],
                    ),
                    padding: EdgeInsets.all(22),
                    child: Column(
                      children: [
                        _row('Order ID', '#KIT${widget.orderId.isNotEmpty ? widget.orderId.padLeft(4, '0') : '----'}', valueBold: true),
                        const SizedBox(height: 12),
                        _row('Kit', widget.kitName),
                        const SizedBox(height: 12),
                        _row('Amount Paid', '₹${widget.amount.toStringAsFixed(0)}', valueColor: AppTheme.primaryColor, valueBold: true),
                        if (widget.paymentId.isNotEmpty) ...[
                          const SizedBox(height: 12),
                          _row('Payment ID', widget.paymentId.length > 14 ? '${widget.paymentId.substring(0, 14)}...' : widget.paymentId),
                        ],
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  Container(
                    padding: EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFF10B981).withOpacity(0.08),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: const Color(0xFF10B981).withOpacity(0.25)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.local_shipping_outlined, color: Color(0xFF10B981), size: 20),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'Your kit will be delivered to your registered address soon.',
                            style: GoogleFonts.poppins(fontSize: 12, color: const Color(0xFF065F46), fontWeight: FontWeight.w500, height: 1.5),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const Spacer(),

                  // Buttons
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton(
                      onPressed: widget.orderId.isNotEmpty
                          ? () => context.pushNamed(AppRoutes.proKitOrderDetailsName, pathParameters: {'id': widget.orderId})
                          : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primaryColor,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        elevation: 0,
                      ),
                      child: Text('View Order', style: GoogleFonts.poppins(fontSize: 15, fontWeight: FontWeight.w700, color: Colors.white)),
                    ),
                  ),
                  const SizedBox(height: 10),
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: OutlinedButton(
                      onPressed: () => context.goNamed(AppRoutes.proKitStoreName),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: Color(0xFFE5E7EB), width: 1.5),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      ),
                      child: Text('Back to Store', style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w600, color: const Color(0xFF6B7280))),
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _row(String label, String value, {Color? valueColor, bool valueBold = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: GoogleFonts.poppins(fontSize: 13, color: const Color(0xFF9CA3AF))),
        Flexible(
          child: Text(
            value,
            style: GoogleFonts.poppins(
              fontSize: 13,
              fontWeight: valueBold ? FontWeight.w700 : FontWeight.w600,
              color: valueColor ?? const Color(0xFF111827),
            ),
            textAlign: TextAlign.right,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}