import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import '../../models/professional_models.dart';
import '../../services/professional_api_service.dart';
import 'package:bellavella/core/routes/app_routes.dart';
import 'package:bellavella/core/theme/app_theme.dart';

class KitOrderHistoryScreen extends StatefulWidget {
  const KitOrderHistoryScreen({super.key});

  @override
  State<KitOrderHistoryScreen> createState() => _KitOrderHistoryScreenState();
}

class _KitOrderHistoryScreenState extends State<KitOrderHistoryScreen> {
  List<KitOrderModel> _orders = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _fetchOrders();
  }

  Future<void> _fetchOrders() async {
    if (!mounted) return;
    setState(() { _isLoading = true; _error = null; });
    try {
      final raw = await ProfessionalApiService.getKitOrders();
      if (!mounted) return;
      setState(() {
        _orders = raw.map((o) => KitOrderModel.fromJson(o)).toList();
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() { _error = e.toString(); _isLoading = false; });
    }
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
          onPressed: () => Navigator.pop(context),
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18, color: Color(0xFF111827)),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Kit Orders',
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: const Color(0xFF111827),
              ),
            ),
            if (_orders.isNotEmpty)
              Text(
                '${_orders.length} orders',
                style: GoogleFonts.poppins(
                  fontSize: 11,
                  color: const Color(0xFF9CA3AF),
                  fontWeight: FontWeight.w500,
                ),
              ),
          ],
        ),
        actions: [
          IconButton(
            onPressed: _fetchOrders,
            icon: const Icon(Icons.refresh_rounded, color: Color(0xFF6B7280)),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _fetchOrders,
        color: AppTheme.primaryColor,
        child: _isLoading
            ? Center(child: CircularProgressIndicator(color: AppTheme.primaryColor))
            : _error != null
                ? _buildError()
                : _orders.isEmpty
                    ? _buildEmpty()
                    : _buildList(),
      ),
    );
  }

  Widget _buildList() {
    return ListView.builder(
      padding: EdgeInsets.all(20),
      itemCount: _orders.length,
      itemBuilder: (context, index) => _KitOrderCard(order: _orders[index]),
    );
  }

  Widget _buildError() {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('😕', style: TextStyle(fontSize: 48)),
            const SizedBox(height: 16),
            Text(
              'Could not load orders',
              style: GoogleFonts.poppins(
                fontSize: 17,
                fontWeight: FontWeight.w700,
                color: const Color(0xFF111827),
              ),
            ),
            const SizedBox(height: 8),
            Text(_error ?? '', textAlign: TextAlign.center,
              style: GoogleFonts.poppins(fontSize: 12, color: const Color(0xFF9CA3AF))),
            const SizedBox(height: 24),
            TextButton(
              onPressed: _fetchOrders,
              child: Text('Try Again',
                style: GoogleFonts.poppins(color: AppTheme.primaryColor, fontWeight: FontWeight.w700)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmpty() {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 110,
              height: 110,
              decoration: BoxDecoration(
                color: const Color(0xFFF3F4F6),
                borderRadius: BorderRadius.circular(28),
              ),
              child: const Center(child: Text('📦', style: TextStyle(fontSize: 52))),
            ),
            const SizedBox(height: 24),
            Text(
              'No orders yet',
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: const Color(0xFF111827),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Your kit purchase history will appear here.',
              style: GoogleFonts.poppins(fontSize: 13, color: const Color(0xFF9CA3AF), height: 1.5),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Order Card ────────────────────────────────────────────────────────────────
class _KitOrderCard extends StatelessWidget {
  final KitOrderModel order;

  const _KitOrderCard({required this.order});

  Color get _statusColor {
    switch (order.status.toLowerCase()) {
      case 'assigned':
      case 'delivered':
        return const Color(0xFF10B981);
      case 'pending':
        return const Color(0xFFF59E0B);
      case 'cancelled':
        return const Color(0xFFEF4444);
      default:
        return const Color(0xFF6B7280);
    }
  }

  IconData get _statusIcon {
    switch (order.status.toLowerCase()) {
      case 'assigned':
      case 'delivered':
        return Icons.check_circle_rounded;
      case 'pending':
        return Icons.hourglass_top_rounded;
      case 'cancelled':
        return Icons.cancel_rounded;
      default:
        return Icons.info_rounded;
    }
  }

  String get _formattedDate {
    if (order.assignedAt.isEmpty) return '—';
    try {
      final dt = DateTime.parse(order.assignedAt).toLocal();
      final months = ['Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'];
      return '${dt.day} ${months[dt.month - 1]} ${dt.year}';
    } catch (_) {
      return order.assignedAt.split('T').first;
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => context.pushNamed(
        AppRoutes.proKitOrderDetailsName,
        pathParameters: {'id': order.id.toString()},
      ),
      child: Container(
      margin: EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: EdgeInsets.all(14),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Product image
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: order.productImage.isNotEmpty
                  ? Image.network(
                      order.productImage,
                      width: 72,
                      height: 72,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => _placeholderImage(),
                    )
                  : _placeholderImage(),
            ),
            const SizedBox(width: 14),
            // Details
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Name + status
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Text(
                          order.productName,
                          style: GoogleFonts.poppins(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: const Color(0xFF111827),
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: _statusColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(_statusIcon, size: 11, color: _statusColor),
                            const SizedBox(width: 3),
                            Text(
                              order.status,
                              style: GoogleFonts.poppins(
                                fontSize: 9,
                                fontWeight: FontWeight.w700,
                                color: _statusColor,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  // Qty + Date
                  Row(
                    children: [
                      _chip('Qty: ${order.quantity}', const Color(0xFF6B7280)),
                      const SizedBox(width: 8),
                      _chip(_formattedDate, const Color(0xFF9CA3AF)),
                    ],
                  ),
                  const SizedBox(height: 8),
                  // Price
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Order #${order.id}',
                        style: GoogleFonts.poppins(
                          fontSize: 11,
                          color: const Color(0xFFD1D5DB),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      Text(
                        '₹${(order.productPrice * order.quantity).toStringAsFixed(0)}',
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          fontWeight: FontWeight.w900,
                          color: AppTheme.primaryColor,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    ), // Container
    ); // GestureDetector
  }

  Widget _chip(String label, Color color) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: const Color(0xFFF3F4F6),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label,
        style: GoogleFonts.poppins(fontSize: 10, color: color, fontWeight: FontWeight.w600),
      ),
    );
  }

  Widget _placeholderImage() {
    return Container(
      width: 72,
      height: 72,
      decoration: BoxDecoration(
        color: const Color(0xFFF3F4F6),
        borderRadius: BorderRadius.circular(12),
      ),
      child: const Center(child: Text('💼', style: TextStyle(fontSize: 30))),
    );
  }
}