import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import '../../models/professional_models.dart';
import '../../services/professional_api_service.dart';
import 'package:bellavella/core/routes/app_routes.dart';
import 'package:bellavella/core/theme/app_theme.dart';

class KitOrderDetailsScreen extends StatefulWidget {
  final String orderId;

  const KitOrderDetailsScreen({super.key, required this.orderId});

  @override
  State<KitOrderDetailsScreen> createState() => _KitOrderDetailsScreenState();
}

class _KitOrderDetailsScreenState extends State<KitOrderDetailsScreen> {
  KitOrderModel? _order;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _fetchOrder();
  }

  Future<void> _fetchOrder() async {
    if (!mounted) return;
    setState(() { _isLoading = true; _error = null; });
    try {
      final raw = await ProfessionalApiService.getKitOrderDetails(int.parse(widget.orderId));
      if (!mounted) return;
      setState(() {
        _order = KitOrderModel.fromJson(raw);
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
          onPressed: () => context.pop(),
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18, color: Color(0xFF111827)),
        ),
        title: Text(
          'Order Details',
          style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.w800, color: const Color(0xFF111827)),
        ),
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator(color: AppTheme.primaryColor))
          : _error != null
              ? _buildError()
              : _order == null
                  ? const Center(child: Text('Order not found.'))
                  : _buildContent(),
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
            Text('Could not load order', style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.w700)),
            const SizedBox(height: 8),
            Text(_error ?? '', textAlign: TextAlign.center, style: GoogleFonts.poppins(fontSize: 12, color: const Color(0xFF9CA3AF))),
            const SizedBox(height: 20),
            TextButton(onPressed: _fetchOrder, child: Text('Retry', style: GoogleFonts.poppins(color: AppTheme.primaryColor, fontWeight: FontWeight.w700))),
          ],
        ),
      ),
    );
  }

  Widget _buildContent() {
    final order = _order!;
    return SingleChildScrollView(
      padding: EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Product Card
          _card(
            child: Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: order.productImage.isNotEmpty
                      ? Image.network(order.productImage, width: 80, height: 80, fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => _placeholderImg())
                      : _placeholderImg(),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(order.productName, style: GoogleFonts.poppins(fontSize: 15, fontWeight: FontWeight.w700, color: const Color(0xFF111827)), maxLines: 2, overflow: TextOverflow.ellipsis),
                      const SizedBox(height: 4),
                      Text('Qty: ${order.quantity}', style: GoogleFonts.poppins(fontSize: 13, color: const Color(0xFF6B7280))),
                      const SizedBox(height: 4),
                      Text('₹${order.totalAmount.toStringAsFixed(0)}', style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.w900, color: AppTheme.primaryColor)),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 14),

          // Status Tracker
          _card(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('ORDER STATUS', style: GoogleFonts.poppins(fontSize: 10, fontWeight: FontWeight.w700, color: const Color(0xFF9CA3AF), letterSpacing: 1.2)),
                const SizedBox(height: 16),
                _StatusTracker(currentStatus: order.orderStatus),
              ],
            ),
          ),

          const SizedBox(height: 14),

          // Payment Info
          _card(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('PAYMENT', style: GoogleFonts.poppins(fontSize: 10, fontWeight: FontWeight.w700, color: const Color(0xFF9CA3AF), letterSpacing: 1.2)),
                const SizedBox(height: 14),
                _infoRow('Amount', '₹${order.totalAmount.toStringAsFixed(0)}', valueColor: AppTheme.primaryColor, bold: true),
                const Divider(height: 20),
                _infoRow('Method', order.paymentMethod.isNotEmpty ? order.paymentMethod.toUpperCase() : '—'),
                const Divider(height: 20),
                _infoRow('Status', order.paymentStatus, valueColor: _paymentStatusColor(order.paymentStatus), bold: true),
              ],
            ),
          ),

          const SizedBox(height: 14),

          // Order Details
          _card(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('ORDER INFO', style: GoogleFonts.poppins(fontSize: 10, fontWeight: FontWeight.w700, color: const Color(0xFF9CA3AF), letterSpacing: 1.2)),
                const SizedBox(height: 14),
                _infoRow('Order ID', '#KIT${order.id.toString().padLeft(4, '0')}', bold: true),
                const Divider(height: 20),
                _infoRow('Date', _formatDate(order.assignedAt)),
                if (order.paymentId.isNotEmpty) ...[
                  const Divider(height: 20),
                  _infoRow('Payment ID', order.paymentId.length > 16 ? '${order.paymentId.substring(0, 16)}...' : order.paymentId),
                ],
              ],
            ),
          ),

          const SizedBox(height: 20),

          // Buy Again
          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton.icon(
              onPressed: () => context.pushNamed(AppRoutes.proKitStoreName),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryColor,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                elevation: 0,
              ),
              icon: const Icon(Icons.shopping_bag_outlined, color: Colors.white, size: 18),
              label: Text('Buy Again', style: GoogleFonts.poppins(fontSize: 15, fontWeight: FontWeight.w700, color: Colors.white)),
            ),
          ),
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _card({required Widget child}) => Container(
    width: double.infinity,
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(20),
      boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 14, offset: const Offset(0, 4))],
    ),
    padding: EdgeInsets.all(18),
    child: child,
  );

  Widget _placeholderImg() => Container(
    width: 80, height: 80,
    decoration: BoxDecoration(color: const Color(0xFFF3F4F6), borderRadius: BorderRadius.circular(12)),
    child: const Center(child: Text('💼', style: TextStyle(fontSize: 32))),
  );

  Widget _infoRow(String label, String value, {Color? valueColor, bool bold = false}) => Row(
    mainAxisAlignment: MainAxisAlignment.spaceBetween,
    children: [
      Text(label, style: GoogleFonts.poppins(fontSize: 13, color: const Color(0xFF9CA3AF))),
      Text(value, style: GoogleFonts.poppins(fontSize: 13, fontWeight: bold ? FontWeight.w700 : FontWeight.w600, color: valueColor ?? const Color(0xFF111827))),
    ],
  );

  Color _paymentStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'paid': return const Color(0xFF10B981);
      case 'failed': return const Color(0xFFEF4444);
      default: return const Color(0xFFF59E0B);
    }
  }

  String _formatDate(String raw) {
    if (raw.isEmpty) return '—';
    try {
      final dt = DateTime.parse(raw).toLocal();
      final months = ['Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'];
      return '${dt.day} ${months[dt.month - 1]} ${dt.year}';
    } catch (_) {
      return raw.split('T').first;
    }
  }
}

// ─── Status Tracker ─────────────────────────────────────────────────────────
class _StatusTracker extends StatelessWidget {
  final String currentStatus;

  const _StatusTracker({required this.currentStatus});

  static const _steps = ['Processing', 'Packed', 'Shipped', 'Delivered'];

  int get _currentIndex {
    final idx = _steps.indexWhere((s) => s.toLowerCase() == currentStatus.toLowerCase());
    return idx < 0 ? 0 : idx;
  }

  @override
  Widget build(BuildContext context) {
    final current = _currentIndex;
    return Row(
      children: List.generate(_steps.length * 2 - 1, (index) {
        if (index.isOdd) {
          // Connector line
          final prevStep = index ~/ 2;
          final isDone = prevStep < current;
          return Expanded(
            child: Container(
              height: 3,
              decoration: BoxDecoration(
                color: isDone ? AppTheme.primaryColor : const Color(0xFFE5E7EB),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          );
        }
        final stepIdx = index ~/ 2;
        final isDone = stepIdx <= current;
        return Column(
          children: [
            Container(
              width: 28, height: 28,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isDone ? AppTheme.primaryColor : const Color(0xFFE5E7EB),
              ),
              child: Icon(
                isDone && stepIdx < current ? Icons.check_rounded : Icons.circle,
                color: Colors.white,
                size: isDone && stepIdx < current ? 16 : 10,
              ),
            ),
            const SizedBox(height: 6),
            SizedBox(
              width: 64,
              child: Text(
                _steps[stepIdx],
                style: GoogleFonts.poppins(
                  fontSize: 9,
                  fontWeight: stepIdx == current ? FontWeight.w700 : FontWeight.w500,
                  color: stepIdx == current ? AppTheme.primaryColor : const Color(0xFF9CA3AF),
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ],
        );
      }),
    );
  }
}