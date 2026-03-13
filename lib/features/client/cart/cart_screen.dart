import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:provider/provider.dart';
import 'package:bellavella/features/client/cart/controllers/cart_provider.dart';
import 'package:bellavella/features/client/cart/models/cart_model.dart';
import 'package:bellavella/core/services/promotion_service.dart';
import 'package:bellavella/core/services/token_manager.dart';
import 'package:bellavella/core/routes/app_routes.dart';
import 'package:bellavella/core/utils/toast_util.dart';

class CartScreen extends StatefulWidget {
  const CartScreen({super.key});

  @override
  State<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen> {
  // Theme colors matching the screenshots
  static const Color pinkPrimary = Color(0xFFFF4891);
  static const Color pinkLight = Color(0xFFFFF0F5);
  static const Color greenSaving = Color(0xFF00897B);

  final TextEditingController _couponController = TextEditingController();
  bool _isSyncing = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<CartProvider>().fetchCart();
    });
  }

  @override
  void dispose() {
    _couponController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cartProvider = context.watch<CartProvider>();
    final groupedItems = <String, List<CartItem>>{};
    for (var item in cartProvider.items) {
      final cat = item.categoryName ?? 'Other';
      groupedItems.putIfAbsent(cat, () => []).add(item);
    }

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
          'Your cart',
          style: GoogleFonts.outfit(
            color: Colors.black,
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
      ),
      body: cartProvider.isLoading
          ? const Center(child: CircularProgressIndicator())
          : cartProvider.error != null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Text(
                      cartProvider.error!,
                      textAlign: TextAlign.center,
                      style: GoogleFonts.outfit(fontSize: 16, color: Colors.grey),
                    ),
                  ),
                )
              : cartProvider.items.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.shopping_cart_outlined, size: 80, color: Colors.grey),
                  const SizedBox(height: 16),
                  Text(
                    'Your cart is empty',
                    style: GoogleFonts.outfit(fontSize: 18, color: Colors.grey),
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: () => context.pop(),
                    style: ElevatedButton.styleFrom(backgroundColor: pinkPrimary),
                    child: const Text('Go Back', style: TextStyle(color: Colors.white)),
                  ),
                ],
              ),
            )
          : SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildSavingsBanner(),
                  ...groupedItems.entries.map((entry) => Column(
                        children: [
                          _buildCartCategorySection(entry.key, entry.value),
                          const Divider(thickness: 8, color: Color(0xFFF5F5F5)),
                        ],
                      )),
                  _buildFrequentlyAdded(),
                  const Divider(thickness: 8, color: Color(0xFFF5F5F5)),
                  _buildCouponsSection(),
                  const Divider(thickness: 8, color: Color(0xFFF5F5F5)),
                  _buildPaymentSummary(cartProvider),
                  const Divider(thickness: 8, color: Color(0xFFF5F5F5)),
                  _buildTipSection(),
                  const Divider(thickness: 8, color: Color(0xFFF5F5F5)),
                  _buildPolicySection(),
                  const SizedBox(height: 100), // Spacer for sticky footer
                ],
              ),
            ),
      bottomNavigationBar: cartProvider.items.isEmpty ? null : _buildStickyFooter(),
    );
  }

  Widget _buildSavingsBanner() {
    final cartProvider = context.watch<CartProvider>();
    final discount = cartProvider.discount;
    if (discount <= 0) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
      color: Colors.white,
      child: Row(
        children: [
          const Icon(Icons.sell, color: greenSaving, size: 20),
          const SizedBox(width: 12),
          Text(
            'Saving ${_formatCurrency(discount)} on this order',
            style: GoogleFonts.outfit(
              color: greenSaving,
              fontWeight: FontWeight.w600,
              fontSize: 15,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCartCategorySection(String category, List<CartItem> items) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            category,
            style: GoogleFonts.outfit(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.black,
            ),
          ),
          const SizedBox(height: 15),
          ...items.map((item) => _buildCartItem(context, item)),
        ],
      ),
    );
  }

  Widget _buildCartItem(BuildContext context, CartItem item) {
    final cartProvider = context.read<CartProvider>();
    return Padding(
      padding: const EdgeInsets.only(bottom: 25),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.outfit(
                        fontSize: 16,
                        fontWeight: FontWeight.w400,
                        color: Colors.black87,
                      ),
                    ),
                    if (item.subtitle != null) ...[
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.only(left: 12),
                        decoration: const BoxDecoration(
                          border: Border(left: BorderSide(color: Color(0xFFE0E0E0), width: 2)),
                        ),
                        child: Text(
                          item.subtitle!,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.outfit(
                            fontSize: 14,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 10),
              _buildQuantitySelector(item.quantity,
                isSyncing: cartProvider.isItemSyncing(item.id),
                onIncrement: () => cartProvider.incrementQuantity(item.id),
                onDecrement: () => cartProvider.decrementQuantity(item.id),
              ),
              const SizedBox(width: 15),
              _buildPriceDisplay(item.price, null),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildQuantitySelector(
    int quantity, {
    bool isSyncing = false,
    VoidCallback? onIncrement,
    VoidCallback? onDecrement,
  }) {
    return Container(
      height: 40,
      decoration: BoxDecoration(
        color: pinkLight,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: pinkPrimary.withOpacity(0.2)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: 34,
            height: double.infinity,
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(10),
                onTap: isSyncing ? null : onDecrement,
                child: const Icon(Icons.remove, size: 16, color: pinkPrimary),
              ),
            ),
          ),
          SizedBox(
            width: 24,
            child: Center(
              child: isSyncing
                  ? const SizedBox(
                      width: 14,
                      height: 14,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Text(
                      '$quantity',
                      style: GoogleFonts.outfit(
                        color: pinkPrimary,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
            ),
          ),
          SizedBox(
            width: 34,
            height: double.infinity,
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(10),
                onTap: isSyncing ? null : onIncrement,
                child: const Icon(Icons.add, size: 16, color: pinkPrimary),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPriceDisplay(double price, double? originalPrice) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Text(
          _formatCurrency(price),
          style: GoogleFonts.outfit(
            fontSize: 15,
            fontWeight: FontWeight.bold,
            color: Colors.black,
          ),
        ),
        if (originalPrice != null)
          Text(
            _formatCurrency(originalPrice),
            style: GoogleFonts.outfit(
              fontSize: 12,
              color: Colors.grey,
              decoration: TextDecoration.lineThrough,
            ),
          ),
      ],
    );
  }

  Widget _buildFrequentlyAdded() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Text(
              'Frequently added together',
              style: GoogleFonts.outfit(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
            ),
          ),
          const SizedBox(height: 15),
          SizedBox(
            height: 250,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              children: [
                _buildSuggestCard(context, 'Threading', '49', 'https://images.unsplash.com/photo-1522337360788-8b13dee7a37e?q=80&w=400'),
                _buildSuggestCard(context, 'Casmara charcoal detox mask', '1,299', 'https://images.unsplash.com/photo-1560750588-73207b1ef5b8?q=80&w=400'),
                _buildSuggestCard(context, 'RIC wax', '69', 'https://images.unsplash.com/photo-1522338242992-e1a54906a8da?q=80&w=400'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSuggestCard(BuildContext context, String title, String price, String img) {
    return Container(
      width: 170,
      margin: const EdgeInsets.symmetric(horizontal: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Image.network(img, height: 160, width: 170, fit: BoxFit.cover),
          ),
          const SizedBox(height: 10),
          Text(
            title,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.outfit(fontSize: 14, fontWeight: FontWeight.normal),
          ),
          const Spacer(),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('₹$price', style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
              GestureDetector(
                onTap: () {
                  ToastUtil.showAddToCartToast(context, title);
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 5),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.grey.shade300),
                  ),
                  child: Text('Add', style: GoogleFonts.outfit(color: pinkPrimary, fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCouponsSection() {
    final cartProvider = context.watch<CartProvider>();
    final hasPromo = cartProvider.appliedPromotion != null;

    return InkWell(
      onTap: () => _showCouponBottomSheet(context),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
        child: Row(
          children: [
            const Icon(Icons.percent, color: greenSaving),
            const SizedBox(width: 15),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    hasPromo ? 'Coupon Applied' : 'Coupons and offers',
                    style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  Text(
                    hasPromo 
                      ? '${cartProvider.appliedPromotion!['code']} applied successfully'
                      : 'Login/Sign up to view offers',
                    style: GoogleFonts.outfit(
                      fontSize: 13, 
                      color: hasPromo ? greenSaving : Colors.grey,
                      fontWeight: hasPromo ? FontWeight.w500 : FontWeight.normal,
                    ),
                  ),
                ],
              ),
            ),
            if (hasPromo)
              TextButton(
                onPressed: () => cartProvider.removePromotion(),
                child: Text('Remove', style: GoogleFonts.outfit(color: pinkPrimary, fontWeight: FontWeight.bold)),
              )
            else
              const Icon(Icons.arrow_forward_ios, size: 14, color: Colors.grey),
          ],
        ),
      ),
    );
  }

  void _showCouponBottomSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.7,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Apply Coupon',
                  style: GoogleFonts.outfit(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const SizedBox(height: 20),
            TextField(
              controller: _couponController,
              style: GoogleFonts.outfit(),
              decoration: InputDecoration(
                hintText: 'Enter coupon code',
                hintStyle: GoogleFonts.outfit(color: Colors.grey),
                suffixIcon: TextButton(
                  onPressed: () async {
                    if (_couponController.text.trim().isEmpty) return;
                    
                    final error = await context.read<CartProvider>().applyPromotion(
                      _couponController.text.trim(),
                    );
                    
                    if (!mounted) return;
                    
                    if (error != null) {
                      ToastUtil.showError(context, error);
                    } else {
                      Navigator.pop(context);
                      ToastUtil.showSuccess(context, 'Coupon applied successfully!');
                    }
                  },
                  child: Text(
                    'Apply',
                    style: GoogleFonts.outfit(color: pinkPrimary, fontWeight: FontWeight.bold),
                  ),
                ),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(color: pinkPrimary),
                ),
              ),
            ),
            const SizedBox(height: 30),
            Expanded(
              child: FutureBuilder<Map<String, dynamic>>(
                future: PromotionService.getActivePromotions(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator(color: pinkPrimary));
                  }
                  
                  if (!snapshot.hasData || snapshot.data!['success'] == false) {
                    return Center(
                      child: Text('No offers available', style: GoogleFonts.outfit(color: Colors.grey)),
                    );
                  }
                  
                  final promotions = snapshot.data!['data'] as List;
                  if (promotions.isEmpty) {
                    return Center(
                      child: Text('No offers available', style: GoogleFonts.outfit(color: Colors.grey)),
                    );
                  }

                  return ListView.builder(
                    itemCount: promotions.length,
                    itemBuilder: (context, index) {
                      final promo = promotions[index];
                      return Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey.shade200),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: pinkLight,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Icon(Icons.percent, color: pinkPrimary, size: 20),
                            ),
                            const SizedBox(width: 15),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    promo['code'],
                                    style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 16),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    promo['description'] ?? 'Discount on your order',
                                    style: GoogleFonts.outfit(fontSize: 13, color: Colors.grey.shade600),
                                  ),
                                ],
                              ),
                            ),
                            TextButton(
                              onPressed: () async {
                                final error = await context.read<CartProvider>().applyPromotion(promo['code']);
                                if (!mounted) return;
                                
                                if (error != null) {
                                  ToastUtil.showError(context, error);
                                } else {
                                  Navigator.pop(context);
                                  ToastUtil.showSuccess(context, 'Coupon applied successfully!');
                                }
                              },
                              child: Text(
                                'APPLY',
                                style: GoogleFonts.outfit(color: pinkPrimary, fontWeight: FontWeight.bold),
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPaymentSummary(CartProvider cartProvider) {
    final groupedItems = <String, double>{};
    for (var item in cartProvider.items) {
      final cat = item.categoryName ?? 'Other';
      final itemTotal = item.price * item.quantity;
      if (!itemTotal.isNaN) {
        groupedItems[cat] = (groupedItems[cat] ?? 0.0) + itemTotal;
      }
    }

    final hasDiscount = cartProvider.discount > 0;
    final hasTip = cartProvider.tip > 0;

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Payment summary',
            style: GoogleFonts.outfit(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 20),
          ...groupedItems.entries.map((entry) => _summaryRow(entry.key, _formatCurrency(entry.value))),
          const Divider(height: 30),
          _summaryRow('Item total', _formatCurrency(cartProvider.subtotal), isBold: true),
          if (hasDiscount) ...[
            const SizedBox(height: 8),
            _summaryRow(
              'Coupon discount', 
              '-${_formatCurrency(cartProvider.discount)}', 
              textColor: greenSaving,
              isBold: true,
            ),
          ],
          const Divider(height: 30),
          _summaryRow('Total amount', _formatCurrency(cartProvider.totalAfterDiscount), isBold: true),
          if (hasTip) ...[
            const SizedBox(height: 8),
            _summaryRow(
              'Professional tip', 
              _formatCurrency(cartProvider.tip), 
              isBold: true,
            ),
          ],
          const Divider(height: 30),
          _summaryRow('Amount to pay', _formatCurrency(cartProvider.totalAmount), isBold: true, largeText: true),
        ],
      ),
    );
  }

  Widget _summaryRow(String label, String value, {bool isBold = false, bool largeText = false, Color? textColor}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: GoogleFonts.outfit(
              fontSize: largeText ? 18 : 15,
              fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
              color: textColor ?? (isBold ? Colors.black : Colors.black87),
            ),
          ),
          Text(
            value,
            style: GoogleFonts.outfit(
              fontSize: largeText ? 18 : 15,
              fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
              color: textColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTipSection() {
    final cartProvider = context.watch<CartProvider>();
    final tips = [50, 75, 100];
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Add a tip to thank your professionals',
            style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              ...tips.map((tip) => Expanded(
                    child: GestureDetector(
                      onTap: () {
                        if (cartProvider.tip == tip.toDouble()) {
                          cartProvider.setTip(0);
                        } else {
                          cartProvider.setTip(tip.toDouble());
                        }
                      },
                      child: Stack(
                        clipBehavior: Clip.none,
                        children: [
                          Container(
                            margin: const EdgeInsets.symmetric(horizontal: 4),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            decoration: BoxDecoration(
                              color: cartProvider.tip == tip.toDouble() ? pinkPrimary.withOpacity(0.05) : Colors.white,
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                color: cartProvider.tip == tip.toDouble() ? pinkPrimary : Colors.grey.shade300,
                              ),
                            ),
                            alignment: Alignment.center,
                            child: Text(
                              '₹$tip',
                              style: GoogleFonts.outfit(
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                                color: cartProvider.tip == tip.toDouble() ? pinkPrimary : Colors.black87,
                              ),
                            ),
                          ),
                          if (tip == 75)
                            Positioned(
                              top: -10,
                              left: 0,
                              right: 0,
                              child: Center(
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFE0F2F1),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Text(
                                    'POPULAR',
                                    style: GoogleFonts.outfit(
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                      color: const Color(0xFF00695C),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  )),
              Expanded(
                child: GestureDetector(
                  onTap: () => _showCustomTipDialog(context),
                  child: Container(
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    decoration: BoxDecoration(
                      color: cartProvider.tip > 0 && !tips.contains(cartProvider.tip.toInt()) ? pinkPrimary.withOpacity(0.05) : Colors.white,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: cartProvider.tip > 0 && !tips.contains(cartProvider.tip.toInt()) ? pinkPrimary : Colors.grey.shade300,
                      ),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      cartProvider.tip > 0 && !tips.contains(cartProvider.tip.toInt()) ? '₹${cartProvider.tip.toInt()}' : 'Custom',
                      style: GoogleFonts.outfit(
                        fontSize: 16, 
                        fontWeight: cartProvider.tip > 0 && !tips.contains(cartProvider.tip.toInt()) ? FontWeight.w500 : FontWeight.normal,
                        color: cartProvider.tip > 0 && !tips.contains(cartProvider.tip.toInt()) ? pinkPrimary : Colors.black87,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Text(
            'Tip will be split equally between the professionals.',
            style: GoogleFonts.outfit(fontSize: 13, color: Colors.grey.shade600),
          ),
        ],
      ),
    );
  }

  void _showCustomTipDialog(BuildContext context) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Custom Tip', style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          autofocus: true,
          style: GoogleFonts.outfit(),
          decoration: InputDecoration(
            hintText: 'Enter amount',
            prefixText: '₹ ',
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel', style: GoogleFonts.outfit(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () {
              final val = double.tryParse(controller.text);
              if (val != null && val >= 0) {
                context.read<CartProvider>().setTip(val);
                Navigator.pop(context);
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: pinkPrimary),
            child: Text('Apply', style: GoogleFonts.outfit(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Widget _buildPolicySection() {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Cancellation & reschedule policy',
            style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          Text(
            'A small fee may apply depending on the service if you cancel or reschedule after a certain time',
            style: GoogleFonts.outfit(fontSize: 14, color: Colors.grey.shade600, height: 1.4),
          ),
          const SizedBox(height: 12),
          Text(
            'Read full policy',
            style: GoogleFonts.outfit(
              fontSize: 15,
              fontWeight: FontWeight.bold,
              color: Colors.black,
              decoration: TextDecoration.underline,
            ),
          ),
        ],
      ),
    );
  }

  String _formatCurrency(double? amount) {
    if (amount == null || amount.isNaN || amount.isInfinite) return '₹0';
    return '₹${amount.toInt()}';
  }

  Widget _buildStickyFooter() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 5,
            offset: const Offset(0, -3),
          ),
        ],
      ),
      child: ElevatedButton(
        onPressed: _isSyncing 
            ? null 
            : () async {
                if (!TokenManager.hasToken) {
                  ToastUtil.showError(context, 'Please log in to proceed to checkout.');
                  context.push(AppRoutes.clientLogin);
                  return;
                }

                setState(() => _isSyncing = true);
                
                final cartProvider = context.read<CartProvider>();
                final syncSuccess = await cartProvider.syncCartWithBackend();
                
                if (!mounted) return;
                setState(() => _isSyncing = false);

                if (syncSuccess) {
                  context.push('/client/checkout-address');
                } else {
                  ToastUtil.showError(context, 'Failed to sync cart. Please try again.');
                }
              },
        style: ElevatedButton.styleFrom(
          backgroundColor: pinkPrimary,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          padding: const EdgeInsets.symmetric(vertical: 15),
        ),
        child: _isSyncing
            ? const SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
              )
            : Text(
                'Proceed to Checkout',
                style: GoogleFonts.outfit(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
      ),
    );
  }
}
// Helper models for mock data structures
class _CartItem {
  final String title;
  final String? subtitle;
  final int? price;
  final int? originalPrice;
  final int quantity;
  final bool isSubGroup;
  final List<_SubItem>? subItems;

  _CartItem({
    required this.title,
    this.subtitle,
    this.price,
    this.originalPrice,
    required this.quantity,
    this.isSubGroup = false,
    this.subItems,
  });
}

class _SubItem {
  final String name;
  final int price;
  _SubItem({required this.name, required this.price});
}
