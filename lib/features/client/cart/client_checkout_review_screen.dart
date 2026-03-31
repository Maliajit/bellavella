import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

import 'package:bellavella/core/config/app_config.dart';
import 'package:bellavella/core/utils/razorpay/razorpay_helper.dart';
import 'package:razorpay_flutter/razorpay_flutter.dart';

import 'package:bellavella/core/routes/app_routes.dart';
import 'package:bellavella/core/services/api_service.dart';

import 'package:bellavella/core/widgets/mock_razorpay_dialog.dart';
import 'package:bellavella/features/client/profile/services/client_profile_api_service.dart';
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
  int? _lastConfirmedPayablePaise;
  int? _previewPayablePaise;
  int? _previewDiscountPaise;
  bool _isPreviewLoading = false;
  String? _previewError;
  StateSetter? _paymentSheetSetState;
  bool _useWalletCoins = false;
  bool _isWalletLoading = false;
  int _walletBalanceCoins = 0;

  @override
  void initState() {
    super.initState();
    _initRazorpay();
  }

  @override
  void dispose() {
    _paymentSheetSetState = null;
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

  Future<void> _loadWalletBalance() async {
    if (_isWalletLoading) return;

    setState(() => _isWalletLoading = true);
    _paymentSheetSetState?.call(() {});
    try {
      final walletData = await ClientProfileApiService.getWallet();
      if (!mounted) return;

      setState(() {
        _walletBalanceCoins = walletData['balance'] is num
            ? (walletData['balance'] as num).toInt()
            : int.tryParse(walletData['balance']?.toString() ?? '') ?? 0;
        _isWalletLoading = false;
      });
      _paymentSheetSetState?.call(() {});
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _walletBalanceCoins = 0;
        _isWalletLoading = false;
      });
      _paymentSheetSetState?.call(() {});
    }
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

  Map<String, dynamic> _buildCheckoutRequestData(CartProvider cartProvider) {
    final String fullAddress = _composeCheckoutAddress();
    final String? slotStr = widget.checkoutData['slot']?.toString();
    final parsedSlot = _parseSlot(slotStr);

    final Map<String, dynamic> requestData = {
      'address': fullAddress,
      'address_id': widget.checkoutData['addressId'],
      'city': widget.checkoutData['city'],
      'latitude': widget.checkoutData['latitude'],
      'longitude': widget.checkoutData['longitude'],
      'scheduled_date': parsedSlot['date'],
      'scheduled_slot': parsedSlot['time'],
      'payment_method': _selectedPaymentMethod,
      'coupon_code': cartProvider.appliedOffer?['code'],
      'tip_amount_paise': (cartProvider.tip * 100).toInt(),
    };

    final checkoutCoinsUsed = _selectedCoinsToUse(cartProvider);
    if (checkoutCoinsUsed > 0) {
      requestData['coins_used'] = checkoutCoinsUsed;
    }

    return requestData;
  }

  int _selectedCoinsToUse(CartProvider cartProvider) {
    if (!_useWalletCoins) {
      return 0;
    }

    final localMaxOrderCoins = cartProvider.totalAmount.floor();
    if (localMaxOrderCoins <= 0) {
      return 0;
    }

    return _walletBalanceCoins.clamp(0, localMaxOrderCoins);
  }

  Future<void> _refreshCheckoutPreview(CartProvider cartProvider) async {
    if (!mounted) return;

    setState(() {
      _isPreviewLoading = true;
      _previewError = null;
    });
    _paymentSheetSetState?.call(() {});

    try {
      final response =
          await ClientApiService.previewCheckoutCart(_buildCheckoutRequestData(cartProvider));

      if (!mounted) return;

      if (response['success'] == true && response['data'] is Map<String, dynamic>) {
        final data = Map<String, dynamic>.from(response['data'] as Map);
        final totalDiscountPaise = _parsePaise(data['total_discount_paise']) ?? 0;
        final walletRedeemedPaise = _parsePaise(data['wallet_redeemed_paise']) ?? 0;
        setState(() {
          _previewPayablePaise = _parsePaise(data['total_paise']);
          _previewDiscountPaise = totalDiscountPaise + walletRedeemedPaise;
          _previewError = null;
          _isPreviewLoading = false;
        });
        _paymentSheetSetState?.call(() {});
      } else {
        setState(() {
          _previewPayablePaise = null;
          _previewDiscountPaise = null;
          _previewError =
              response['message']?.toString() ?? 'Unable to preview payable amount.';
          _isPreviewLoading = false;
        });
        _paymentSheetSetState?.call(() {});
      }
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _previewPayablePaise = null;
        _previewDiscountPaise = null;
        _previewError = 'Unable to preview payable amount.';
        _isPreviewLoading = false;
      });
      _paymentSheetSetState?.call(() {});
    }
  }

  void _showPaymentBottomSheet(BuildContext context) {
    final cartProvider = context.read<CartProvider>();
    var initialPreviewRequested = false;
    final currencyFormat = NumberFormat.currency(symbol: '₹', decimalDigits: 0);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (BuildContext ctx) {
        return StatefulBuilder(
          builder: (BuildContext ctx, StateSetter setModalState) {
            _paymentSheetSetState = setModalState;
            if (!initialPreviewRequested) {
              initialPreviewRequested = true;
              WidgetsBinding.instance.addPostFrameCallback((_) {
                _loadWalletBalance();
                _refreshCheckoutPreview(cartProvider);
              });
            }
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
                        onPressed: () {
                          _paymentSheetSetState = null;
                          Navigator.pop(ctx);
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  
                  // Payable Summary
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
                          _isPreviewLoading
                              ? 'Calculating Payable'
                              : _lastConfirmedPayablePaise != null
                                  ? 'Final Payable'
                                  : _previewPayablePaise != null
                                      ? 'Discounted Payable'
                                      : 'Estimated Payable',
                          style: GoogleFonts.outfit(
                            fontSize: 16,
                            color: Colors.black87,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        _isPreviewLoading
                            ? const SizedBox(
                                width: 22,
                                height: 22,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Color(0xFFFF4891),
                                ),
                              )
                            : Text(
                                _lastConfirmedPayablePaise != null
                                    ? _formatPaise(_lastConfirmedPayablePaise!)
                                    : _previewPayablePaise != null
                                        ? _formatPaise(_previewPayablePaise!)
                                        : currencyFormat.format(cartProvider.totalAmount),
                                style: GoogleFonts.outfit(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: const Color(0xFFFF4891), // pinkPrimary
                                ),
                              ),
                      ],
                    ),
                  ),
                  if (!_isPreviewLoading && (_previewDiscountPaise ?? 0) > 0) ...[
                    const SizedBox(height: 10),
                    Text(
                      'Checkout savings: ${_formatPaise(_previewDiscountPaise!)}',
                      style: GoogleFonts.outfit(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: Colors.green.shade700,
                      ),
                    ),
                  ],
                  if (!_isPreviewLoading && _previewError != null) ...[
                    const SizedBox(height: 10),
                    Text(
                      _previewError!,
                      style: GoogleFonts.outfit(
                        fontSize: 13,
                        color: Colors.red.shade400,
                      ),
                    ),
                  ],
                  const SizedBox(height: 12),
                  Text(
                    _paymentHintText(),
                    style: GoogleFonts.outfit(
                      fontSize: 13,
                      color: Colors.grey.shade600,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 24),
                  _buildWalletUsageCard(cartProvider, setModalState),
                  const SizedBox(height: 16),
                  
                  // Payment Options
                  _buildPaymentOption(
                    title: 'Online Payment (UPI/Cards)',
                    icon: Icons.credit_card,
                    value: 'online',
                    groupValue: _selectedPaymentMethod,
                    onChanged: (val) {
                      setModalState(() => _selectedPaymentMethod = val!);
                      _refreshCheckoutPreview(cartProvider);
                    },
                  ),
                  const SizedBox(height: 12),
                  _buildPaymentOption(
                    title: 'Cash after service',
                    icon: Icons.money,
                    value: 'cod',
                    groupValue: _selectedPaymentMethod,
                    onChanged: (val) {
                      setModalState(() => _selectedPaymentMethod = val!);
                      _refreshCheckoutPreview(cartProvider);
                    },
                  ),
                  const SizedBox(height: 30),
                  SizedBox(
                    width: double.infinity,
                    height: 55,
                    child: ElevatedButton(
                      onPressed: (_isProcessing || _isPreviewLoading)
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

  Widget _buildWalletUsageCard(CartProvider cartProvider, StateSetter setModalState) {
    final coinsToUse = _selectedCoinsToUse(cartProvider);
    final canToggleWalletCoins = !_isWalletLoading && _walletBalanceCoins > 0;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade200),
        borderRadius: BorderRadius.circular(14),
        color: Colors.white,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: const Color(0xFFFFF0F5),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.account_balance_wallet, color: Color(0xFFFF4891)),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'BellaVella Wallet',
                  style: GoogleFonts.outfit(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _isWalletLoading
                      ? 'Loading wallet balance...'
                      : _walletBalanceCoins > 0
                          ? 'Available: $_walletBalanceCoins coins. Wallet will automatically reduce this order by up to $coinsToUse.'
                          : 'No BellaVella Wallet balance available right now.',
                  style: GoogleFonts.outfit(
                    fontSize: 13,
                    color: Colors.grey.shade600,
                    height: 1.35,
                  ),
                ),
                if (_useWalletCoins && coinsToUse > 0) ...[
                  const SizedBox(height: 8),
                  Text(
                    'Wallet applied: $coinsToUse coins (₹$coinsToUse)',
                    style: GoogleFonts.outfit(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: Colors.green.shade700,
                    ),
                  ),
                ],
              ],
            ),
          ),
          Switch(
            value: _useWalletCoins,
            onChanged: canToggleWalletCoins
                ? (value) {
                    setModalState(() {
                      _useWalletCoins = value;
                    });
                    _refreshCheckoutPreview(cartProvider);
                  }
                : null,
            activeColor: const Color(0xFFFF4891),
          ),
        ],
      ),
    );
  }

  Future<void> _handleCheckout(BuildContext modalContext, CartProvider cartProvider) async {
    setState(() => _isProcessing = true);
    
    // safe to pop modal first
    _paymentSheetSetState = null;
    Navigator.pop(modalContext);

    try {
      final Map<String, dynamic> requestData = _buildCheckoutRequestData(cartProvider);

      final response = await ClientApiService.checkoutCart(requestData);

      if (response['success'] == true) {
        final orderData = response['data'];
        _lastOrderId = orderData['order_id'];
        final confirmedAmountPaise = _parsePaise(orderData['amount']);
        if (confirmedAmountPaise != null && mounted) {
          setState(() {
            _lastConfirmedPayablePaise = confirmedAmountPaise;
          });
        } else if (confirmedAmountPaise != null) {
          _lastConfirmedPayablePaise = confirmedAmountPaise;
        }

        if (_selectedPaymentMethod == 'online' && orderData['razorpay_order_id'] != null) {
          final localEstimatedPaise = (cartProvider.totalAmount * 100).round();
          if (confirmedAmountPaise != null && mounted) {
            final message = confirmedAmountPaise < localEstimatedPaise
                ? 'Checkout discount applied. Final payable ${_formatPaise(confirmedAmountPaise)}'
                : 'Final payable ${_formatPaise(confirmedAmountPaise)}';
            ToastUtil.showSuccess(context, message);
          }

          if (orderData['is_mock'] == true) {
            if (!mounted) return;
            MockRazorpayDialog.show(
              context,
              options: {
                'amount': orderData['amount'],
                'name': 'BellaVella',
                'description': 'Service Booking',
                'order_id': orderData['razorpay_order_id'],
              },
              onSuccess: _handlePaymentSuccess,
              onFailure: _handlePaymentError,
            );
            return;
          }
          
          // Open Razorpay
          final options = {
            'key': AppConfig.razorpayKeyId,
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
        if (response['message'] == 'Unauthenticated.' ||
            response['_auth_expired'] == true) {
          ToastUtil.showError(context, ApiService.sessionExpiredMessage);
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

  String _composeCheckoutAddress() {
    final parts = <String>[
      if ((widget.checkoutData['houseNumber'] as String?)?.trim().isNotEmpty == true)
        (widget.checkoutData['houseNumber'] as String).trim(),
      if ((widget.checkoutData['landmark'] as String?)?.trim().isNotEmpty == true)
        (widget.checkoutData['landmark'] as String).trim(),
      if ((widget.checkoutData['fullAddress'] as String?)?.trim().isNotEmpty == true)
        (widget.checkoutData['fullAddress'] as String).trim(),
      if ((widget.checkoutData['city'] as String?)?.trim().isNotEmpty == true)
        (widget.checkoutData['city'] as String).trim(),
    ];

    return parts.join(', ');
  }

  int? _parsePaise(dynamic value) {
    if (value is num) {
      return value.toInt();
    }
    if (value == null) {
      return null;
    }

    return int.tryParse(value.toString());
  }

  String _formatPaise(int paise) {
    final currencyFormat = NumberFormat.currency(symbol: '₹', decimalDigits: 0);
    return currencyFormat.format(paise / 100);
  }

  String _paymentHintText() {
    switch (_selectedPaymentMethod) {
      case 'online':
        return _useWalletCoins
            ? 'BellaVella Wallet will reduce the order first, then any eligible online-payment discount is applied before Razorpay opens.'
            : 'Online-payment discounts are confirmed by the backend before Razorpay opens, so the final payable can be lower than the cart estimate.';
      default:
        return _useWalletCoins
            ? 'BellaVella Wallet will reduce the payable first. Any remaining amount will be collected after service.'
            : 'The backend confirms the final payable after applying any eligible coupon and checkout discount rules.';
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
    final slot = widget.checkoutData['slot'] as String?;
    final categories = (widget.checkoutData['categories'] as List? ?? const [])
        .map((item) => item?.toString() ?? '')
        .where((item) => item.isNotEmpty)
        .toList();

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
                            'Scheduled Slot',
                            style: GoogleFonts.outfit(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      Container(
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
                                    slot ?? 'No slot selected',
                                    style: GoogleFonts.outfit(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                      color: pinkPrimary,
                                    ),
                                  ),
                                  if (categories.isNotEmpty) ...[
                                    const SizedBox(height: 8),
                                    Text(
                                      'Applies to: ${categories.join(', ')}',
                                      style: GoogleFonts.outfit(
                                        color: Colors.grey.shade700,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                            Icon(Icons.edit_outlined, color: Colors.grey.shade400, size: 20),
                          ],
                        ),
                      ),
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
