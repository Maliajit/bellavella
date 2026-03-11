import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import 'package:bellavella/core/theme/app_theme.dart';
import 'package:bellavella/features/professional/models/professional_models.dart';
import 'package:bellavella/features/professional/services/professional_api_service.dart';
import 'package:intl/intl.dart';
import 'package:bellavella/core/utils/razorpay/razorpay_helper.dart';
import 'package:razorpay_flutter/razorpay_flutter.dart';
import 'package:bellavella/core/routes/app_routes.dart';
import '../widgets/workflow_stepper.dart';

class ProPaymentScreen extends StatefulWidget {
  final ProfessionalBooking booking;
  const ProPaymentScreen({super.key, required this.booking});

  @override
  State<ProPaymentScreen> createState() => _ProPaymentScreenState();
}

class _ProPaymentScreenState extends State<ProPaymentScreen> {
  bool _isProcessing = false;
  RazorpayService? _razorpayService;
  String _selectedMethod = "online"; // "online" or "cash"

  void _initRazorpay() {
    if (_razorpayService != null) return;
    _razorpayService = getService();
    _razorpayService!.init(
      _handlePaymentSuccess,
      _handlePaymentError,
      _handleExternalWallet,
    );
  }

  @override
  void initState() {
    super.initState();
    _initRazorpay();
  }

  @override
  void dispose() {
    _razorpayService?.clear();
    super.dispose();
  }

  void _handlePaymentSuccess(PaymentSuccessResponse response) async {
    setState(() => _isProcessing = true);
    try {
      final res = await ProfessionalApiService.verifyJobPayment(
        id: widget.booking.id,
        razorpayPaymentId: response.paymentId!,
        razorpayOrderId: response.orderId!,
        razorpaySignature: response.signature!,
      );
      
      if (mounted) {
        context.pushNamed(AppRoutes.proJobCompleteName, extra: widget.booking);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Verification Failed: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  void _handlePaymentError(PaymentFailureResponse response) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Payment Failed: ${response.message}')),
    );
  }

  void _handleExternalWallet(ExternalWalletResponse response) {
    // Handle external wallet
  }

  Future<void> _startRazorpayPayment() async {
    setState(() => _isProcessing = true);
    try {
      final orderRes = await ProfessionalApiService.createJobPaymentOrder(widget.booking.id);
      
      final options = {
        'key': 'rzp_test_S7dlJIqMvrpcaj',
        'amount': orderRes['amount'],
        'name': 'BellaVella',
        'order_id': orderRes['order_id'],
        'description': 'Payment for ${widget.booking.serviceName}',
        'timeout': 300,
        'prefill': {
          'contact': '', // Professional mobile or client mobile?
          'email': '',
        },
        'theme': {
          'color': '#FF3366',
        }
      };

      _initRazorpay();
      _razorpayService!.open(options);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to initialize payment: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  Future<void> _completeJob() async {
    // This is for Cash payment or direct completion if allowed
    setState(() => _isProcessing = true);
    try {
      final res = await ProfessionalApiService.jobComplete(widget.booking.id);
      if (mounted) {
        if (res['success'] == true) {
          context.pushNamed(AppRoutes.proJobCompleteName, extra: widget.booking);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(res['message'] ?? 'Failed to complete job')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final currencyFormat = NumberFormat.currency(symbol: '₹', decimalDigits: 0);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: Colors.black87),
          onPressed: () => context.pop(),
        ),
        title: Text(
          "Collect Payment",
          style: GoogleFonts.inter(
            fontSize: 16,
            fontWeight: FontWeight.w800,
            color: Colors.black87,
          ),
        ),
      ),
      body: Column(
        children: [
          const WorkflowStepper(currentStep: 4),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  const SizedBox(height: 20),
                  Text(
                    "Total Amount to Collect",
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey.shade500,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    currencyFormat.format(widget.booking.totalPrice),
                    style: GoogleFonts.inter(
                      fontSize: 48,
                      fontWeight: FontWeight.w900,
                      color: Colors.black87,
                      letterSpacing: -1,
                    ),
                  ),
                  const SizedBox(height: 48),
                  
                  // QR Section (Only shown for Online)
                  if (_selectedMethod == "online")
                    Container(
                      padding: const EdgeInsets.all(32),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade50,
                        borderRadius: BorderRadius.circular(32),
                        border: Border.all(color: Colors.grey.shade100),
                      ),
                      child: Column(
                        children: [
                          Icon(Icons.qr_code_2_rounded, size: 200, color: Colors.black87.withValues(alpha: 0.8)),
                          const SizedBox(height: 24),
                          Text(
                            "Ask customer to scan and pay",
                            style: GoogleFonts.inter(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: Colors.grey.shade600,
                            ),
                          ),
                        ],
                      ),
                    )
                  else
                    Container(
                      padding: const EdgeInsets.all(32),
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade50,
                        borderRadius: BorderRadius.circular(32),
                        border: Border.all(color: Colors.grey.shade100),
                      ),
                      child: Column(
                        children: [
                          Icon(Icons.payments_outlined, size: 100, color: Colors.grey.shade400),
                          const SizedBox(height: 24),
                          Text(
                            "Collect cash from customer",
                            style: GoogleFonts.inter(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: Colors.grey.shade600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  
                  const SizedBox(height: 32),
                  
                  Row(
                    children: [
                      Expanded(
                        child: GestureDetector(
                          onTap: () => setState(() => _selectedMethod = "online"),
                          child: _paymentMethodOption(
                            Icons.account_balance_wallet_outlined, 
                            "UPI / Online", 
                            _selectedMethod == "online"
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: GestureDetector(
                          onTap: () => setState(() => _selectedMethod = "cash"),
                          child: _paymentMethodOption(
                            Icons.money_rounded, 
                            "Cash", 
                            _selectedMethod == "cash"
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(24),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isProcessing ? null : (_selectedMethod == "online" ? _startRazorpayPayment : _completeJob),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.black,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 20),
                  elevation: 0,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
                child: _isProcessing 
                    ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : Text(
                        _selectedMethod == "online" ? "Collect Online Payment" : "Received Cash",
                        style: GoogleFonts.inter(fontWeight: FontWeight.w800, fontSize: 16),
                      ),
              ),
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _paymentMethodOption(IconData icon, String label, bool isSelected) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16),
      decoration: BoxDecoration(
        color: isSelected ? AppTheme.primaryColor.withValues(alpha: 0.05) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isSelected ? AppTheme.primaryColor : Colors.grey.shade200,
          width: 2,
        ),
      ),
      child: Column(
        children: [
          Icon(icon, color: isSelected ? AppTheme.primaryColor : Colors.grey.shade400),
          const SizedBox(height: 8),
          Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: isSelected ? Colors.black87 : Colors.grey.shade500,
            ),
          ),
        ],
      ),
    );
  }
}
