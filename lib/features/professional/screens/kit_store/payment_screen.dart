import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:razorpay_flutter/razorpay_flutter.dart';
import 'package:go_router/go_router.dart';
import '../../models/professional_models.dart';
import '../../services/professional_api_service.dart';
import '../../../../core/router/route_names.dart';

class PaymentScreen extends StatefulWidget {
  final KitProductModel kit;
  final int quantity;

  const PaymentScreen({
    super.key,
    required this.kit,
    required this.quantity,
  });

  @override
  State<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends State<PaymentScreen> {
  late final Razorpay _razorpay;
  String _selectedMethod = 'upi';
  bool _isProcessing = false;

  double get _total => widget.kit.price * widget.quantity;

  static const String _razorpayKey = 'rzp_test_YOUR_KEY_HERE'; // Replace with your Razorpay test key

  final List<Map<String, dynamic>> _paymentMethods = [
    {'id': 'upi', 'label': 'UPI', 'icon': Icons.account_balance_rounded, 'color': Color(0xFF3B82F6)},
    {'id': 'card', 'label': 'Card', 'icon': Icons.credit_card_rounded, 'color': Color(0xFF8B5CF6)},
    {'id': 'netbanking', 'label': 'Net Banking', 'icon': Icons.account_balance_outlined, 'color': Color(0xFF10B981)},
    {'id': 'wallet', 'label': 'Wallet', 'icon': Icons.account_balance_wallet_outlined, 'color': Color(0xFFF59E0B)},
  ];

  @override
  void initState() {
    super.initState();
    _razorpay = Razorpay();
    _razorpay.on(Razorpay.EVENT_PAYMENT_SUCCESS, _onPaymentSuccess);
    _razorpay.on(Razorpay.EVENT_PAYMENT_ERROR, _onPaymentError);
    _razorpay.on(Razorpay.EVENT_EXTERNAL_WALLET, _onExternalWallet);
  }

  @override
  void dispose() {
    _razorpay.clear();
    super.dispose();
  }

  void _openRazorpay() async {
    HapticFeedback.mediumImpact();
    setState(() => _isProcessing = true);

    final options = {
      'key': _razorpayKey,
      'amount': (_total * 100).toInt(), // paise
      'name': 'Bella Villa',
      'description': '${widget.kit.name} × ${widget.quantity}',
      'prefill': {
        'contact': '',
        'email': '',
      },
      'theme': {'color': '#FF2D6F'},
      'method': {
        'upi': _selectedMethod == 'upi',
        'card': _selectedMethod == 'card',
        'netbanking': _selectedMethod == 'netbanking',
        'wallet': _selectedMethod == 'wallet',
      },
    };

    try {
      _razorpay.open(options);
    } catch (e) {
      setState(() => _isProcessing = false);
      debugPrint('Razorpay error: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not open payment: $e')),
        );
      }
    }
  }

  void _onPaymentSuccess(PaymentSuccessResponse response) async {
    setState(() => _isProcessing = true);
    try {
      final res = await ProfessionalApiService.verifyKitPayment(
        kitProductId: widget.kit.id,
        quantity: widget.quantity,
        paymentId: response.paymentId ?? '',
        razorpayOrderId: response.orderId ?? '',
        paymentMethod: _selectedMethod,
      );
      if (!mounted) return;
      setState(() => _isProcessing = false);
      final orderId = res['data']?['id']?.toString() ?? '';
      context.pushReplacementNamed(
        AppRoutes.proKitPaymentSuccessName,
        extra: {
          'orderId': orderId,
          'amount': _total,
          'kitName': widget.kit.name,
          'paymentId': response.paymentId ?? '',
        },
      );
    } catch (e) {
      setState(() => _isProcessing = false);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Payment verification failed: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _onPaymentError(PaymentFailureResponse response) {
    setState(() => _isProcessing = false);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Payment failed: ${response.message}'),
        backgroundColor: const Color(0xFFEF4444),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _onExternalWallet(ExternalWalletResponse response) {
    setState(() => _isProcessing = false);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('External wallet: ${response.walletName}')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6F7F9),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        surfaceTintColor: Colors.white,
        leading: IconButton(
          onPressed: () => context.pop(),
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18, color: Color(0xFF111827)),
        ),
        title: Text(
          'Payment',
          style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.w800, color: const Color(0xFF111827)),
        ),
      ),
      body: Stack(
        children: [
          SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Order Summary Card
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 14, offset: const Offset(0, 4))],
                  ),
                  padding: const EdgeInsets.all(18),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('ORDER SUMMARY', style: GoogleFonts.poppins(fontSize: 10, fontWeight: FontWeight.w700, color: const Color(0xFF9CA3AF), letterSpacing: 1.2)),
                      const SizedBox(height: 14),
                      Row(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: Image.network(widget.kit.image, width: 64, height: 64, fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => Container(width: 64, height: 64, color: const Color(0xFFF3F4F6), child: const Center(child: Text('💼', style: TextStyle(fontSize: 28))))),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(widget.kit.name, style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w700, color: const Color(0xFF111827)), maxLines: 2, overflow: TextOverflow.ellipsis),
                                Text((widget.kit.category ?? 'General').toUpperCase(), style: GoogleFonts.poppins(fontSize: 10, color: const Color(0xFF9CA3AF), fontWeight: FontWeight.w600, letterSpacing: 0.5)),
                                const SizedBox(height: 4),
                                Text('₹${widget.kit.price.toStringAsFixed(0)} × ${widget.quantity}', style: GoogleFonts.poppins(fontSize: 13, color: const Color(0xFF6B7280))),
                              ],
                            ),
                          ),
                          Text('₹${_total.toStringAsFixed(0)}', style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.w900, color: const Color(0xFFFF2D6F))),
                        ],
                      ),
                      const SizedBox(height: 14),
                      const Divider(height: 1),
                      const SizedBox(height: 14),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('Total Payable', style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w700, color: const Color(0xFF111827))),
                          Text('₹${_total.toStringAsFixed(0)}', style: GoogleFonts.poppins(fontSize: 20, fontWeight: FontWeight.w900, color: const Color(0xFFFF2D6F))),
                        ],
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 20),

                // Delivery Address
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10, offset: const Offset(0, 3))],
                  ),
                  padding: const EdgeInsets.all(18),
                  child: Row(
                    children: [
                      Container(
                        width: 40, height: 40,
                        decoration: BoxDecoration(color: const Color(0xFFFF2D6F).withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
                        child: const Icon(Icons.location_on_outlined, color: Color(0xFFFF2D6F), size: 20),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Delivery Address', style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.w700, color: const Color(0xFF111827))),
                            Text('Registered address on file', style: GoogleFonts.poppins(fontSize: 11, color: const Color(0xFF9CA3AF))),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 20),

                // Payment Method
                Text('PAYMENT METHOD', style: GoogleFonts.poppins(fontSize: 10, fontWeight: FontWeight.w700, color: const Color(0xFF9CA3AF), letterSpacing: 1.2)),
                const SizedBox(height: 12),
                GridView.count(
                  crossAxisCount: 2,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  childAspectRatio: 2.8,
                  children: _paymentMethods.map((method) {
                    final isSelected = _selectedMethod == method['id'];
                    return GestureDetector(
                      onTap: () => setState(() => _selectedMethod = method['id']),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        decoration: BoxDecoration(
                          color: isSelected ? (method['color'] as Color).withOpacity(0.1) : Colors.white,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: isSelected ? method['color'] as Color : const Color(0xFFE5E7EB),
                            width: isSelected ? 2 : 1,
                          ),
                          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8, offset: const Offset(0, 2))],
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(method['icon'] as IconData, color: isSelected ? method['color'] as Color : const Color(0xFF6B7280), size: 18),
                            const SizedBox(width: 8),
                            Text(method['label'] as String, style: GoogleFonts.poppins(fontSize: 13, fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500, color: isSelected ? method['color'] as Color : const Color(0xFF374151))),
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                ),

                const SizedBox(height: 120),
              ],
            ),
          ),

          // Bottom Confirm Button
          Positioned(
            left: 0, right: 0, bottom: 0,
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 20, offset: const Offset(0, -4))],
              ),
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Total', style: GoogleFonts.poppins(fontSize: 12, color: const Color(0xFF9CA3AF))),
                      Text('₹${_total.toStringAsFixed(0)}', style: GoogleFonts.poppins(fontSize: 20, fontWeight: FontWeight.w900, color: const Color(0xFFFF2D6F))),
                    ],
                  ),
                  const SizedBox(height: 10),
                  SizedBox(
                    width: double.infinity,
                    height: 54,
                    child: ElevatedButton(
                      onPressed: _isProcessing ? null : _openRazorpay,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFFF2D6F),
                        disabledBackgroundColor: const Color(0xFFE5E7EB),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        elevation: 0,
                      ),
                      child: _isProcessing
                          ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5))
                          : Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(Icons.lock_rounded, size: 16, color: Colors.white),
                                const SizedBox(width: 8),
                                Text('Confirm Payment', style: GoogleFonts.poppins(fontSize: 15, fontWeight: FontWeight.w700, color: Colors.white)),
                              ],
                            ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Processing Overlay
          if (_isProcessing)
            Container(
              color: Colors.black.withOpacity(0.3),
              child: const Center(child: CircularProgressIndicator(color: Color(0xFFFF2D6F))),
            ),
        ],
      ),
    );
  }
}
