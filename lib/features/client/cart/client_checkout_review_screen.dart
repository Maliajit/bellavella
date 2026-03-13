import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

import 'package:bellavella/core/utils/razorpay/razorpay_helper.dart';
import 'package:razorpay_flutter/razorpay_flutter.dart';

import 'package:bellavella/core/routes/app_routes.dart';

import 'controllers/cart_provider.dart';
import '../services/client_api_service.dart';
import 'package:bellavella/core/utils/toast_util.dart';

class ClientCheckoutReviewScreen extends StatefulWidget {
  final Map<String, dynamic> checkoutData;

  const ClientCheckoutReviewScreen({super.key, required this.checkoutData});

  @override
  State<ClientCheckoutReviewScreen> createState() => _ClientCheckoutReviewScreenState();
}

class _ClientCheckoutReviewScreenState extends State<ClientCheckoutReviewScreen> {
  bool _isProcessing = false;
  String _selectedPaymentMethod = 'online'; // Default
  RazorpayService? _razorpayService;
  int? _lastOrderId; // Store order id for verification

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

  void _initRazorpay() {
    if (_razorpayService != null) return;
    _razorpayService = getService();
    _razorpayService!.init(
      _handlePaymentSuccess,
      _handlePaymentError,
      _handleExternalWallet,
    );
  }

  void _handlePaymentSuccess(PaymentSuccessResponse response) async {
    if (_lastOrderId == null) return;
    
    setState(() => _isProcessing = true);
    try {
      final res = await ClientApiService.verifyCheckoutPayment(
        orderId: _lastOrderId!,
        razorpayPaymentId: response.paymentId!,
        razorpayOrderId: response.orderId!,
        razorpaySignature: response.signature!,
      );
      
      final cartProvider = context.read<CartProvider>();
      cartProvider.clear();

      if (mounted) {
        ToastUtil.showSuccess(context, 'Payment Successful!');
        context.go('/client/my-bookings');
      }
    } catch (e) {
      if (mounted) {
        ToastUtil.showError(context, 'Payment Verification Failed: $e');
      }
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  void _handlePaymentError(PaymentFailureResponse response) {
    setState(() => _isProcessing = false);
    ToastUtil.showError(context, 'Payment Failed: ${response.message}');
  }

  void _handleExternalWallet(ExternalWalletResponse response) {
    setState(() => _isProcessing = false);
    // Handle external wallet
  }

  // Helper to parse the slot string (e.g., "Mon, Mar 10 at 10:00 AM")
  Map<String, String> _parseSlot(String? slotStr) {
    if (slotStr == null || !slotStr.contains(' at ')) {
      return {'date': DateTime.now().toIso8601String().split('T')[0], 'time': '10:00 AM'};
    }
    try {
      final parts = slotStr.split(' at ');
      final timeParts = parts[1];
      final dateStr = parts[0];
      
      final dateParts = dateStr.split(', ');
      final monthDay = dateParts[1].split(' ');
      
      final monthStr = monthDay[0];
      final dayStr = monthDay[1];
      
      final months = ["Jan", "Feb", "Mar", "Apr", "May", "Jun", "Jul", "Aug", "Sep", "Oct", "Nov", "Dec"];
      final monthIndex = months.indexOf(monthStr) + 1;
      final year = DateTime.now().year;
      
      final formattedDate = "$year-${monthIndex.toString().padLeft(2, '0')}-${dayStr.padLeft(2, '0')}";
      return {'date': formattedDate, 'time': timeParts};
    } catch (e) {
      return {'date': DateTime.now().toIso8601String().split('T')[0], 'time': '10:00 AM'};
    }
  }

  void _showPaymentBottomSheet(BuildContext context) {
    final cartProvider = context.read<CartProvider>();
    final currencyFormat = NumberFormat.currency(symbol: '₹', decimalDigits: 0);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (BuildContext ctx) {
        return StatefulBuilder(
          builder: (BuildContext ctx, StateSetter setModalState) {
            return Container(
              padding: const EdgeInsets.all(24),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Select Payment Mode',
                        style: GoogleFonts.outfit(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () => Navigator.pop(ctx),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  
                  // Total Payable
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFF0F5), // pinkLight
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Total Payable',
                          style: GoogleFonts.outfit(
                            fontSize: 16,
                            color: Colors.black87,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Text(
                          currencyFormat.format(cartProvider.totalAmount),
                          style: GoogleFonts.outfit(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: const Color(0xFFFF4891), // pinkPrimary
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  
                  // Payment Options
                  _buildPaymentOption(
                    title: 'Online Payment (UPI/Cards)',
                    icon: Icons.credit_card,
                    value: 'online',
                    groupValue: _selectedPaymentMethod,
                    onChanged: (val) => setModalState(() => _selectedPaymentMethod = val!),
                  ),
                  const SizedBox(height: 12),
                  _buildPaymentOption(
                    title: 'Cash after service',
                    icon: Icons.money,
                    value: 'cod',
                    groupValue: _selectedPaymentMethod,
                    onChanged: (val) => setModalState(() => _selectedPaymentMethod = val!),
                  ),
                  const SizedBox(height: 12),
                  _buildPaymentOption(
                    title: 'BellaVella Wallet',
                    icon: Icons.account_balance_wallet,
                    value: 'wallet',
                    groupValue: _selectedPaymentMethod,
                    onChanged: (val) => setModalState(() => _selectedPaymentMethod = val!),
                  ),
                  
                  const SizedBox(height: 30),
                  SizedBox(
                    width: double.infinity,
                    height: 55,
                    child: ElevatedButton(
                      onPressed: _isProcessing 
                        ? null 
                        : () => _handleCheckout(ctx, cartProvider),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFFF4891),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: _isProcessing
                        ? const SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                          )
                        : Text(
                            'Confirm Payment',
                            style: GoogleFonts.outfit(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                    ),
                  ),
                  const SizedBox(height: 10),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildPaymentOption({
    required String title,
    required IconData icon,
    required String value,
    required String groupValue,
    required ValueChanged<String?> onChanged,
  }) {
    final isSelected = value == groupValue;
    return GestureDetector(
      onTap: () => onChanged(value),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          border: Border.all(
            color: isSelected ? const Color(0xFFFF4891) : Colors.grey.shade300,
            width: isSelected ? 2 : 1,
          ),
          borderRadius: BorderRadius.circular(12),
          color: isSelected ? const Color(0xFFFFF0F5).withOpacity(0.5) : Colors.white,
        ),
        child: Row(
          children: [
            Icon(icon, color: isSelected ? const Color(0xFFFF4891) : Colors.grey.shade600),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                title,
                style: GoogleFonts.outfit(
                  fontSize: 16,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                  color: Colors.black87,
                ),
              ),
            ),
            Radio<String>(
              value: value,
              groupValue: groupValue,
              onChanged: onChanged,
              activeColor: const Color(0xFFFF4891),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _handleCheckout(BuildContext modalContext, CartProvider cartProvider) async {
    setState(() => _isProcessing = true);
    
    // safe to pop modal first
    Navigator.pop(modalContext);

    try {
      final String fullAddress = '${widget.checkoutData['houseNumber']}, ${widget.checkoutData['landmark']}. ${widget.checkoutData['fullAddress']}';
      
      final Map<String, String?> slots = widget.checkoutData['slots'];
      final String? firstSlotStr = slots.values.firstWhere((element) => element != null, orElse: () => null);
      final parsedSlot = _parseSlot(firstSlotStr);

      final Map<String, dynamic> requestData = {
        'address': fullAddress,
        'scheduled_date': parsedSlot['date'],
        'scheduled_slot': parsedSlot['time'],
        'payment_method': _selectedPaymentMethod,
        'coupon_code': cartProvider.appliedPromotion?['code'],
        'tip_amount_paise': (cartProvider.tip * 100).toInt(),
      };

      final response = await ClientApiService.checkoutCart(requestData);

      if (response['success'] == true) {
        final orderData = response['data'];
        _lastOrderId = orderData['order_id'];

        if (_selectedPaymentMethod == 'online' && orderData['razorpay_order_id'] != null) {
          // Open Razorpay
          final options = {
            'key': 'rzp_test_S7dlJIqMvrpcaj',
            'amount': orderData['amount'],
            'name': 'BellaVella',
            'order_id': orderData['razorpay_order_id'],
            'description': 'Payment for Order ${orderData['order_number']}',
            'timeout': 300,
            'prefill': {
              'contact': '', 
              'email': '',
            },
            'theme': {
              'color': '#FF3366',
            }
          };

          _initRazorpay();
          _razorpayService!.open(options);
          // Don't set _isProcessing to false here, wait for Razorpay to finish
        } else {
          // Cash or Wallet - Order completed directly
          cartProvider.clear();
          
          if (!mounted) return;
          ToastUtil.showSuccess(context, 'Order placed successfully!');
          context.go('/client/my-bookings');
          if (mounted) setState(() => _isProcessing = false);
        }
      } else {
        if (!mounted) return;
        
        // Handle Laravel's default unauthenticated message
        if (response['message'] == 'Unauthenticated.') {
          ToastUtil.showError(context, 'Please log in to complete your booking.');
          context.push(AppRoutes.clientLogin);
        } else {
          ToastUtil.showError(context, response['message'] ?? 'Checkout failed');
        }
        
        if (mounted) setState(() => _isProcessing = false);
      }
    } catch (e) {
      if (!mounted) return;
      ToastUtil.showError(context, 'An error occurred: $e');
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  @override

  Widget build(BuildContext context) {
    // Theme colors matching the cart
    const Color pinkPrimary = Color(0xFFFF4891);
    const Color pinkLight = Color(0xFFFFF0F5);

    final addressLabel = widget.checkoutData['address'] as String;
    final fullAddress = widget.checkoutData['fullAddress'] as String;
    final houseNumber = widget.checkoutData['houseNumber'] as String;
    final landmark = widget.checkoutData['landmark'] as String;
    final slots = widget.checkoutData['slots'] as Map<String, String?>;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.5,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => context.pop(),
        ),
        title: Text(
          'Review Checkout',
          style: GoogleFonts.outfit(
            color: Colors.black,
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
      ),
      body: Stack(
        children: [
          SingleChildScrollView(
            child: Column(
              children: [
                // Address Section
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    border: Border(bottom: BorderSide(color: Colors.grey.shade100)),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: pinkLight,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(Icons.home_outlined, color: pinkPrimary),
                      ),
                      const SizedBox(width: 15),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  addressLabel,
                                  style: GoogleFonts.outfit(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                Icon(Icons.edit_outlined, color: Colors.grey.shade400, size: 20),
                              ],
                            ),
                            const SizedBox(height: 5),
                            Text(
                              '$houseNumber, $landmark. $fullAddress',
                              style: GoogleFonts.outfit(
                                fontSize: 14,
                                color: Colors.grey.shade600,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                
                // Slots Section
                Container(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: pinkLight,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Icon(Icons.access_time, color: pinkPrimary),
                          ),
                          const SizedBox(width: 15),
                          Text(
                            'Scheduled Sessions',
                            style: GoogleFonts.outfit(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      ...slots.entries.map((entry) => Container(
                        margin: const EdgeInsets.only(bottom: 15),
                        padding: const EdgeInsets.all(15),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.grey.shade200),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    entry.key,
                                    style: GoogleFonts.outfit(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                    ),
                                  ),
                                  const SizedBox(height: 5),
                                  Text(
                                    entry.value ?? 'No slot selected',
                                    style: GoogleFonts.outfit(
                                      color: pinkPrimary,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Icon(Icons.edit_outlined, color: Colors.grey.shade400, size: 20),
                          ],
                        ),
                      )),
                    ],
                  ),
                ),
              ],
            ),
          ),
          if (_isProcessing)
            Container(
              color: Colors.black.withOpacity(0.3),
              child: const Center(
                child: CircularProgressIndicator(color: pinkPrimary),
              ),
            ),
        ],
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.fromLTRB(20, 10, 20, 30),
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border(top: BorderSide(color: Colors.grey.shade200)),
        ),
        child: ElevatedButton(
          onPressed: _isProcessing ? null : () => _showPaymentBottomSheet(context),
          style: ElevatedButton.styleFrom(
            backgroundColor: pinkPrimary,
            minimumSize: const Size(double.infinity, 55),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
          child: Text(
            'Proceed to pay',
            style: GoogleFonts.outfit(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        ),
      ),
    );
  }
}
