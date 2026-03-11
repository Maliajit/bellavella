import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import 'package:razorpay_flutter/razorpay_flutter.dart';
import 'package:bellavella/features/professional/models/professional_models.dart' as pro_models;
import 'package:bellavella/features/professional/models/professional_models.dart';
import 'package:bellavella/features/professional/services/professional_api_service.dart';
import 'package:bellavella/core/utils/razorpay/razorpay_helper.dart' as rzp_helper;
import 'widgets/kit_store_header.dart';
import 'widgets/kit_store_banner.dart';
import 'widgets/kit_product_card.dart';
import 'package:bellavella/core/routes/app_routes.dart';
import 'package:bellavella/core/theme/app_theme.dart';

class KitStoreScreen extends StatefulWidget {
  const KitStoreScreen({super.key});

  @override
  State<KitStoreScreen> createState() => _KitStoreScreenState();
}

class _KitStoreScreenState extends State<KitStoreScreen> {
  int _currentKits = 0;
  String _searchQuery = '';
  List<KitProductModel> _kits = [];
  bool _isLoading = true;
  String? _errorMessage;
  bool _isProcessing = false;
  final TextEditingController _searchCtrl = TextEditingController();
  rzp_helper.RazorpayService? _razorpayService;
  static const String _razorpayKey = 'rzp_test_S7dlJIqMvrpcaj'; 
  
  // Selected kit for Razorpay callback
   KitProductModel? _selectedKitForRZP;
  int _selectedQtyForRZP = 1;

  List<KitProductModel> get _filteredKits {
    if (_searchQuery.isEmpty) return _kits;
    final q = _searchQuery.toLowerCase();
    return _kits.where((k) =>
        k.name.toLowerCase().contains(q) ||
        (k.category ?? '').toLowerCase().contains(q) ||
        k.description.toLowerCase().contains(q)
    ).toList();
  }

  @override
  void initState() {
    super.initState();
    _fetchKits();
    _initRazorpay();
  }

  void _initRazorpay() {
    _razorpayService = rzp_helper.getService();
    _razorpayService?.init(_onPaymentSuccess, _onPaymentError, _onExternalWallet);
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    _razorpayService?.clear();
    super.dispose();
  }

  Future<void> _fetchKits() async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      final products = await ProfessionalApiService.getKitProducts();
      final stats = await ProfessionalApiService.getDashboardStats();
      if (!mounted) return;
      setState(() {
        _kits = products;
        _currentKits = stats.kitCount;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('Error fetching kits: $e');
      if (!mounted) return;
      setState(() {
        _errorMessage = e.toString();
        _isLoading = false;
      });
    }
  }

  // --- Razorpay Methods ---
  
  void _openRazorpay(KitProductModel kit, int qty) async {
    HapticFeedback.mediumImpact();
    setState(() {
      _isProcessing = true;
      _selectedKitForRZP = kit;
      _selectedQtyForRZP = qty;
    });

    try {
      // Step 1: Create Order on Backend
      final orderData = await ProfessionalApiService.createKitPaymentOrder(kit.id, qty);
      final String razorpayOrderId = orderData['order_id'];
      final int amountPaise = orderData['amount'];

      final options = {
        'key': _razorpayKey,
        'amount': amountPaise,
        'name': 'Bella Villa',
        'description': '${kit.name} × $qty',
        'order_id': razorpayOrderId, // MUST pass order_id for signature verification
        'prefill': {'contact': '', 'email': ''},
        'theme': {'color': '#FF2D6F'},
      };

      _razorpayService?.open(options);
    } catch (e) {
      if (!mounted) return;
      setState(() => _isProcessing = false);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Order Creation Failed: $e'), backgroundColor: Colors.red));
    }
  }

  void _onPaymentSuccess(PaymentSuccessResponse response) async {
    if (_selectedKitForRZP == null) return;
    
    // Step 2: Verify Payment Signature on Backend
    setState(() => _isProcessing = true);
    try {
      final res = await ProfessionalApiService.verifyKitPayment(
        kitProductId: _selectedKitForRZP!.id,
        quantity: _selectedQtyForRZP,
        razorpayPaymentId: response.paymentId ?? '',
        razorpayOrderId: response.orderId ?? '',
        razorpaySignature: response.signature ?? '',
      );
      
      if (!mounted) return;
      setState(() => _isProcessing = false);
      _fetchKits(); // Refresh inventory count

      final orderId = res['id']?.toString() ?? 'N/A';
      context.pushReplacementNamed(
        AppRoutes.proKitPaymentSuccessName,
        extra: {
          'orderId': orderId,
          'amount': _selectedKitForRZP!.price * _selectedQtyForRZP,
          'kitName': _selectedKitForRZP!.name,
          'paymentId': response.paymentId ?? '',
        },
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _isProcessing = false);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Payment Verification Failed: $e'), backgroundColor: Colors.red));
    }
  }

  void _onPaymentError(PaymentFailureResponse response) {
    setState(() => _isProcessing = false);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Payment failed: ${response.message}'), backgroundColor: Colors.red),
    );
  }

  void _onExternalWallet(ExternalWalletResponse response) {
    setState(() => _isProcessing = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6F7F9),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _fetchKits,
          color: AppTheme.primaryColor,
          child: CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(
              parent: BouncingScrollPhysics(),
            ),
            slivers: [
              // Header with live search
              SliverToBoxAdapter(
                child: KitStoreHeader(
                  searchController: _searchCtrl,
                  onSearchChanged: (q) => setState(() => _searchQuery = q),
                ),
              ),

              // Hero Banner
              SliverToBoxAdapter(
                child: KitStoreBanner(
                  kitCount: _currentKits,
                  onManage: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Inventory management coming soon!'),
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  },
                ),
              ),

              // Loading state
              if (_isLoading)
                const SliverFillRemaining(
                  child: Center(
                    child: CircularProgressIndicator(color: AppTheme.primaryColor),
                  ),
                )
              // Error state
              else if (_errorMessage != null)
                SliverFillRemaining(
                  child: _buildErrorState(),
                )
              // Empty state (no kits in DB)
              else if (_kits.isEmpty)
                const SliverFillRemaining(
                  child: _EmptyState(),
                )
              else ...[
                const SliverToBoxAdapter(child: SizedBox(height: 8)),

                // Results count / search indicator
                SliverPadding(
                  padding: EdgeInsets.fromLTRB(20, 0, 20, 8),
                  sliver: SliverToBoxAdapter(
                    child: Row(
                      children: [
                        if (_searchQuery.isNotEmpty)
                          Expanded(
                            child: RichText(
                              text: TextSpan(children: [
                                TextSpan(
                                  text: '${_filteredKits.length} results for ',
                                  style: GoogleFonts.poppins(fontSize: 13, color: const Color(0xFF9CA3AF)),
                                ),
                                TextSpan(
                                  text: '"$_searchQuery"',
                                  style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.w700, color: const Color(0xFF111827)),
                                ),
                              ]),
                            ),
                          )
                        else
                          Text(
                            '${_filteredKits.length} Products',
                            style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w700, color: const Color(0xFF111827)),
                          ),
                        const Spacer(),
                        Text('Tap to view details', style: GoogleFonts.poppins(fontSize: 11, color: const Color(0xFF9CA3AF))),
                      ],
                    ),
                  ),
                ),

                // No search results
                if (_filteredKits.isEmpty && _searchQuery.isNotEmpty)
                  SliverFillRemaining(
                    child: Center(
                      child: Padding(
                        padding: EdgeInsets.all(32),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Text('🔍', style: TextStyle(fontSize: 48)),
                            const SizedBox(height: 16),
                            Text('No kits found', style: GoogleFonts.poppins(fontSize: 17, fontWeight: FontWeight.w700, color: const Color(0xFF111827))),
                            const SizedBox(height: 6),
                            Text('Try a different keyword', style: GoogleFonts.poppins(fontSize: 13, color: const Color(0xFF9CA3AF))),
                          ],
                        ),
                      ),
                    ),
                  )
                else
                  // Kit cards
                  SliverPadding(
                    padding: EdgeInsets.symmetric(horizontal: 20),
                    sliver: SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (context, index) {
                          final kit = _filteredKits[index];
                          return KitProductCard(
                            kit: kit,
                            onBuy: () => _showBuySheet(kit),
                            onViewDetails: () => _showDetailsSheet(kit),
                          );
                        },
                        childCount: _filteredKits.length,
                      ),
                    ),
                  ),
              ],

              // Bottom spacer for nav bar
              const SliverToBoxAdapter(child: SizedBox(height: 100)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('😕', style: TextStyle(fontSize: 48)),
            const SizedBox(height: 16),
            Text(
              'Something went wrong',
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: const Color(0xFF111827),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _errorMessage ?? 'Please try again.',
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(
                fontSize: 13,
                color: const Color(0xFF9CA3AF),
              ),
            ),
            const SizedBox(height: 24),
            GestureDetector(
              onTap: _fetchKits,
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 32, vertical: 14),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [AppTheme.primaryColor, Color(0xFFFF6B9D)],
                  ),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Text(
                  'Try Again',
                  style: GoogleFonts.poppins(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showDetailsSheet(KitProductModel kit) {
    HapticFeedback.lightImpact();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _DetailsSheet(kit: kit, onBuy: () {
        Navigator.pop(context);
        _showBuySheet(kit);
      }),
    );
  }

  void _showBuySheet(KitProductModel kit) {
    HapticFeedback.mediumImpact();
    int qty = 1;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetCtx) => StatefulBuilder(
        builder: (context, setSheetState) {
          final total = kit.price * qty;
          
          return Container(
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
            ),
            padding: EdgeInsets.fromLTRB(24, 16, 24, 24 + MediaQuery.of(context).viewInsets.bottom),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(width: 40, height: 4, decoration: BoxDecoration(color: const Color(0xFFE5E7EB), borderRadius: BorderRadius.circular(2))),
                const SizedBox(height: 20),
                Text('Confirm Order', style: GoogleFonts.poppins(fontSize: 20, fontWeight: FontWeight.w800, color: const Color(0xFF111827))),
                const SizedBox(height: 20),
                Row(
                  children: [
                    ClipRRect(borderRadius: BorderRadius.circular(12),
                      child: Image.network(kit.image, width: 60, height: 60, fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => Container(width: 60, height: 60, color: const Color(0xFFF3F4F6), child: const Center(child: Text('💼', style: TextStyle(fontSize: 24)))))),
                    const SizedBox(width: 14),
                    Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text(kit.name, style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w700, color: const Color(0xFF111827)), maxLines: 1, overflow: TextOverflow.ellipsis),
                      Text('₹${kit.price.toStringAsFixed(0)} per kit', style: GoogleFonts.poppins(fontSize: 12, color: const Color(0xFF9CA3AF))),
                    ])),
                  ],
                ),
                const SizedBox(height: 16),
                const Divider(height: 1),
                const SizedBox(height: 16),
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                  Text('Quantity', style: GoogleFonts.poppins(fontSize: 15, fontWeight: FontWeight.w600, color: const Color(0xFF374151))),
                  Row(children: [
                    _qtyBtn(icon: Icons.remove_rounded, active: qty > 1, onTap: qty > 1 ? () => setSheetState(() => qty--) : null),
                    Padding(padding: EdgeInsets.symmetric(horizontal: 16),
                      child: Text('$qty', style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.w900, color: const Color(0xFF111827)))),
                    _qtyBtn(icon: Icons.add_rounded, active: true, primary: true, onTap: () => setSheetState(() => qty++)),
                  ]),
                ]),
                const SizedBox(height: 12),
                const Divider(height: 1),
                const SizedBox(height: 12),
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                  Text('Total Amount', style: GoogleFonts.poppins(fontSize: 15, fontWeight: FontWeight.w700, color: const Color(0xFF111827))),
                  Text('₹${total.toStringAsFixed(0)}', style: GoogleFonts.poppins(fontSize: 22, fontWeight: FontWeight.w900, color: AppTheme.primaryColor)),
                ]),
                const SizedBox(height: 24),
                
                // Direct Razorpay Button
                SizedBox(
                  width: double.infinity,
                  height: 54,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.pop(sheetCtx);
                      _openRazorpay(kit, qty);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF111827),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      elevation: 0,
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.flash_on_rounded, color: Colors.amber, size: 18),
                        const SizedBox(width: 8),
                        Text('Proceed to Pay ₹${total.toStringAsFixed(0)}', 
                          style: GoogleFonts.poppins(fontSize: 15, fontWeight: FontWeight.w700, color: Colors.white)),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                TextButton(
                  onPressed: () => Navigator.pop(sheetCtx),
                  child: Text('Cancel', style: GoogleFonts.poppins(color: const Color(0xFF9CA3AF), fontWeight: FontWeight.w600)),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _qtyBtn({required IconData icon, bool active = false, bool primary = false, VoidCallback? onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        width: 36, height: 36,
        decoration: BoxDecoration(
          color: primary ? AppTheme.primaryColor : active ? const Color(0xFFF3F4F6) : const Color(0xFFE5E7EB),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, size: 18, color: primary ? Colors.white : active ? const Color(0xFF374151) : const Color(0xFFD1D5DB)),
      ),
    );
  }
}

// ─── Empty State ───────────────────────────────────────────────────────────────
class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                color: const Color(0xFFF3F4F6),
                borderRadius: BorderRadius.circular(30),
              ),
              child: const Center(
                child: Text('📦', style: TextStyle(fontSize: 56)),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'No kits available right now',
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: const Color(0xFF111827),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'New kits will be added soon.\nCheck back later.',
              style: GoogleFonts.poppins(
                fontSize: 13,
                color: const Color(0xFF9CA3AF),
                height: 1.6,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Details Bottom Sheet ──────────────────────────────────────────────────────
class _DetailsSheet extends StatelessWidget {
  final KitProductModel kit;
  final VoidCallback onBuy;

  const _DetailsSheet({required this.kit, required this.onBuy});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 12),
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: const Color(0xFFE5E7EB),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 24),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 24),
            child: Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: Image.network(
                    kit.image,
                    width: 80,
                    height: 80,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Container(
                      width: 80,
                      height: 80,
                      color: const Color(0xFFF3F4F6),
                      child: const Center(child: Text('💼', style: TextStyle(fontSize: 32))),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        kit.name,
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFF111827),
                        ),
                      ),
                      Text(
                        (kit.category ?? 'General').toUpperCase(),
                        style: GoogleFonts.poppins(
                          fontSize: 10,
                          color: const Color(0xFF9CA3AF),
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.5,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '₹${kit.price.toStringAsFixed(0)}',
                        style: GoogleFonts.poppins(
                          fontSize: 22,
                          fontWeight: FontWeight.w900,
                          color: AppTheme.primaryColor,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          const Divider(height: 1, indent: 24, endIndent: 24),
          const SizedBox(height: 16),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Description',
                  style: GoogleFonts.poppins(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF111827),
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  kit.description.isNotEmpty
                      ? kit.description
                      : 'A premium quality professional kit designed for beauty service providers.',
                  style: GoogleFonts.poppins(
                    fontSize: 13,
                    color: const Color(0xFF6B7280),
                    height: 1.6,
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    _statChip(
                      icon: Icons.inventory_2_outlined,
                      label: 'Stock: ${kit.stock}',
                      color: kit.stock > 5
                          ? const Color(0xFF10B981)
                          : kit.stock > 0
                              ? const Color(0xFFF59E0B)
                              : const Color(0xFFEF4444),
                    ),
                    const SizedBox(width: 10),
                    if (kit.isPremium == true)
                      _statChip(
                        icon: Icons.star_rounded,
                        label: 'Premium',
                        color: const Color(0xFF8B5CF6),
                      ),
                  ],
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    onPressed: kit.stock > 0 ? onBuy : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primaryColor,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                      elevation: 0,
                    ),
                    child: Text(
                      kit.stock > 0 ? 'Buy Now' : 'Out of Stock',
                      style: GoogleFonts.poppins(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Center(
                    child: Text(
                      'Close',
                      style: GoogleFonts.poppins(
                        color: const Color(0xFF9CA3AF),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _statChip({
    required IconData icon,
    required String label,
    required Color color,
  }) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 5),
          Text(
            label,
            style: GoogleFonts.poppins(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}
