import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:razorpay_flutter/razorpay_flutter.dart';

import 'package:bellavella/core/config/app_config.dart';
import 'package:bellavella/core/models/data_models.dart';
import 'package:bellavella/core/routes/app_routes.dart';
import 'package:bellavella/core/theme/app_theme.dart';
import 'package:bellavella/core/utils/razorpay/razorpay_helper.dart';
import 'package:bellavella/core/widgets/mock_razorpay_dialog.dart';
import 'package:bellavella/features/professional/controllers/dashboard_controller.dart';
import 'package:bellavella/features/professional/models/professional_models.dart';
import 'package:bellavella/features/professional/services/professional_api_service.dart';

import '../widgets/workflow_stepper.dart';

class ProPaymentScreen extends StatefulWidget {
  final ProfessionalBooking booking;
  final bool isInsideContainer;

  const ProPaymentScreen({
    super.key,
    required this.booking,
    this.isInsideContainer = false,
  });

  @override
  State<ProPaymentScreen> createState() => _ProPaymentScreenState();
}

class _ProPaymentScreenState extends State<ProPaymentScreen> {
  bool _isProcessing = false;
  RazorpayService? _razorpayService;
  String _selectedMethod = 'online';
  bool _hasHapticFired = false;

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

  void _goToCompletion() {
    if (!mounted) return;
    context.goNamed(
      AppRoutes.proJobCompleteName,
      pathParameters: {'id': widget.booking.id},
    );
  }

  void _handlePaymentSuccess(PaymentSuccessResponse response) async {
    if (!mounted) return;

    setState(() => _isProcessing = true);

    try {
      final success = await context.read<DashboardController>().verifyPayment(
        razorpayPaymentId: response.paymentId ?? '',
        razorpayOrderId: response.orderId ?? '',
        razorpaySignature: response.signature ?? '',
      );
      if (!mounted) return;

      if (!success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Payment verification failed.')),
        );
        return;
      }
      
      // Haptic & Auto-navigation is handled by the build method/polling sync
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Payment error: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  void _handlePaymentError(PaymentFailureResponse response) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Payment failed: ${response.message}')),
    );
  }

  void _handleExternalWallet(ExternalWalletResponse response) {}

  Future<void> _startRazorpayPayment() async {
    if (_isProcessing) return;

    setState(() => _isProcessing = true);

    try {
      final orderRes =
          await ProfessionalApiService.createJobPaymentOrder(widget.booking.id);

      final options = {
        'key': AppConfig.razorpayKeyId,
        'amount': orderRes['amount'],
        'name': 'BellaVella',
        'order_id': orderRes['order_id'],
        'description': 'Payment for ${widget.booking.serviceName}',
        'timeout': 300,
        'prefill': {
          'contact': '',
          'email': '',
        },
        'theme': {
          'color': '#FF3366',
        },
      };

      _initRazorpay();

      if (orderRes['is_mock'] == true) {
        if (!mounted) return;

        MockRazorpayDialog.show(
          context,
          options: {
            'amount': orderRes['amount'],
            'name': 'BellaVella',
            'description': 'Payment for ${widget.booking.serviceName}',
            'order_id': orderRes['order_id'],
          },
          onSuccess: _handlePaymentSuccess,
          onFailure: _handlePaymentError,
        );
        return;
      }

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

  Future<void> _handleCollectCash() async {
    if (_isProcessing) return;

    setState(() => _isProcessing = true);

    try {
      final success = await context.read<DashboardController>().collectCash();
      if (!mounted) return;

      if (!success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Cash collection failed. Already paid?'),
          ),
        );
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Cash collected successfully!')),
      );
      // Success triggers re-build via polling or direct result
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Cash collection failed: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  Future<void> _completeJob() async {
    if (_isProcessing) return;

    setState(() => _isProcessing = true);

    try {
      final success = await context.read<DashboardController>().completeJob();
      if (!mounted) return;

      if (!success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Unable to complete booking. Please try again.'),
          ),
        );
        return;
      }

      _goToCompletion();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Job completion failed: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.isInsideContainer) {
      return _buildBody();
    }

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
          'Collect Payment',
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
          Expanded(child: _buildBody()),
        ],
      ),
    );
  }

  Widget _buildBody() {
    final booking = widget.booking;

    if (booking.paymentStatus == PaymentStatus.paid) {
      _triggerSuccessHaptic();
      return _buildPaidScreen();
    } else if (booking.paymentStatus == PaymentStatus.failed) {
      return _buildFailedScreen();
    } else {
      if (booking.paymentMethod == 'cash') {
        return _buildCashOnlyScreen();
      } else {
        return _buildQrAndOnlineScreen();
      }
    }
  }

  void _triggerSuccessHaptic() {
    if (!_hasHapticFired) {
      HapticFeedback.vibrate();
      _hasHapticFired = true;
      
      // AUTO-COMPLETE: Automatically proceed after 2 seconds
      Timer(const Duration(seconds: 2), () {
        if (mounted && widget.booking.paymentStatus == PaymentStatus.paid && !_isProcessing) {
          _completeJob();
        }
      });
    }
  }

  Widget _buildPaidScreen() {
    final currencyFormat =
        NumberFormat.currency(symbol: '₹', decimalDigits: 0);
    
    // AUTO-COMPLETE UI LOGIC: Disable buttons if processing
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.check_circle, color: Colors.green, size: 100),
          const SizedBox(height: 24),
          Text(
            currencyFormat.format(widget.booking.totalPrice),
            style: GoogleFonts.inter(
              fontSize: 40,
              fontWeight: FontWeight.w900,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            "Paid via ${widget.booking.paymentSource?.name.toUpperCase() ?? widget.booking.paymentMethod.toUpperCase()}",
            style: GoogleFonts.inter(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.green.shade50,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              "✅ Payment Successful",
              style: GoogleFonts.inter(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: Colors.green.shade700,
              ),
            ),
          ),
          const Spacer(),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _isProcessing ? null : _completeJob,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.black,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 20),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              child: _isProcessing 
                ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                : const Text("Continue to Finish"),
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildFailedScreen() {
     final currencyFormat =
        NumberFormat.currency(symbol: '₹', decimalDigits: 0);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline_rounded, color: Colors.red, size: 80),
          const SizedBox(height: 24),
          Text(
            "Payment Failed",
            style: GoogleFonts.inter(
              fontSize: 24,
              fontWeight: FontWeight.w800,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            "Transaction for ${currencyFormat.format(widget.booking.totalPrice)} was unsuccessful.",
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(
              fontSize: 14,
              color: Colors.grey.shade600,
            ),
          ),
          const Spacer(),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => setState(() => _selectedMethod = 'cash'),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 18),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                  child: const Text("Pay by Cash"),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  onPressed: _startRazorpayPayment,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.black,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 18),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                  child: const Text("Retry Online"),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildCashOnlyScreen() {
    final currencyFormat =
        NumberFormat.currency(symbol: '₹', decimalDigits: 0);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          const SizedBox(height: 40),
          Icon(Icons.payments_outlined, size: 80, color: Colors.grey.shade400),
          const SizedBox(height: 24),
          Text(
            "Collect Cash from Customer",
            style: GoogleFonts.inter(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            currencyFormat.format(widget.booking.totalPrice),
            style: GoogleFonts.inter(
              fontSize: 48,
              fontWeight: FontWeight.w900,
              color: Colors.black87,
            ),
          ),
          const Spacer(),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _isProcessing ? null : _handleCollectCash,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.black,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 20),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              child: _isProcessing
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white))
                  : const Text("Mark as Cash Received"),
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildQrAndOnlineScreen() {
    final currencyFormat =
        NumberFormat.currency(symbol: '₹', decimalDigits: 0);
    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                const SizedBox(height: 20),
                Text(
                  'Total Amount to Collect',
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
                const SizedBox(height: 32),
                Container(
                  padding: const EdgeInsets.all(32),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade50,
                    borderRadius: BorderRadius.circular(32),
                    border: Border.all(color: Colors.grey.shade100),
                  ),
                  child: Column(
                    children: [
                      Icon(
                        Icons.qr_code_2_rounded,
                        size: 200,
                        color: Colors.black87.withValues(alpha: 0.8),
                      ),
                      const SizedBox(height: 24),
                      Text(
                        'Ask customer to scan and pay',
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
                        onTap: () => setState(() => _selectedMethod = 'online'),
                        child: _paymentMethodOption(
                          Icons.account_balance_wallet_outlined,
                          'UPI / Online',
                          _selectedMethod == 'online',
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: GestureDetector(
                        onTap: () => setState(() => _selectedMethod = 'cash'),
                        child: _paymentMethodOption(
                          Icons.money_rounded,
                          'Cash',
                          _selectedMethod == 'cash',
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
              onPressed: _isProcessing
                  ? null
                  : (_selectedMethod == 'online'
                      ? _startRazorpayPayment
                      : _handleCollectCash),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.black,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 20),
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              child: _isProcessing
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : Text(
                      _selectedMethod == 'online'
                          ? 'Collect Online Payment'
                          : 'Received Cash',
                      style: GoogleFonts.inter(
                        fontWeight: FontWeight.w800,
                        fontSize: 16,
                      ),
                    ),
            ),
          ),
        ),
        const SizedBox(height: 24),
      ],
    );
  }

  Widget _paymentMethodOption(IconData icon, String label, bool isSelected) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16),
      decoration: BoxDecoration(
        color: isSelected
            ? AppTheme.primaryColor.withValues(alpha: 0.05)
            : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isSelected ? AppTheme.primaryColor : Colors.grey.shade200,
          width: 2,
        ),
      ),
      child: Column(
        children: [
          Icon(
            icon,
            color: isSelected ? AppTheme.primaryColor : Colors.grey.shade400,
          ),
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
