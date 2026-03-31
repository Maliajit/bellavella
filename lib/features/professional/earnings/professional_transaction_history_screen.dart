import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:bellavella/core/theme/app_theme.dart';
import 'package:bellavella/core/models/data_models.dart';
import 'package:bellavella/core/models/wallet_transaction.dart';
import '../models/professional_models.dart' as pro_models;
import '../services/professional_api_service.dart';

class ProfessionalTransactionHistoryScreen extends StatefulWidget {
  const ProfessionalTransactionHistoryScreen({super.key});

  @override
  State<ProfessionalTransactionHistoryScreen> createState() =>
      _ProfessionalTransactionHistoryScreenState();
}

class _ProfessionalTransactionHistoryScreenState
    extends State<ProfessionalTransactionHistoryScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  // Cash / Coins
  List<WalletTransaction> _cashTxs   = [];
  List<WalletTransaction> _coinTxs   = [];
  // Kits
  List<pro_models.KitOrderModel> _kitOrders = [];

  bool _loadingCash  = true;
  bool _loadingCoins = true;
  bool _loadingKits  = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _fetchCash();
    _fetchCoins();
    _fetchKits();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _fetchCash() async {
    setState(() => _loadingCash = true);
    try {
      final wallet = await ProfessionalApiService.getWallet(tab: 'earnings');
      if (mounted) setState(() { _cashTxs = wallet.transactions; _loadingCash = false; });
    } catch (_) {
      if (mounted) setState(() => _loadingCash = false);
    }
  }

  Future<void> _fetchCoins() async {
    setState(() => _loadingCoins = true);
    try {
      final wallet = await ProfessionalApiService.getWallet(tab: 'coins');
      if (mounted) setState(() { _coinTxs = wallet.transactions; _loadingCoins = false; });
    } catch (_) {
      if (mounted) setState(() => _loadingCoins = false);
    }
  }

  Future<void> _fetchKits() async {
    setState(() => _loadingKits = true);
    try {
      final raw = await ProfessionalApiService.getKitOrders();
      if (mounted) {
        setState(() {
          _kitOrders = raw.map((m) => pro_models.KitOrderModel.fromJson(m)).toList();
          _loadingKits = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _loadingKits = false);
    }
  }

  Future<void> _refreshAll() async {
    await Future.wait([_fetchCash(), _fetchCoins(), _fetchKits()]);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        surfaceTintColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.black, size: 20),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          'Transaction History',
          style: GoogleFonts.inter(color: Colors.black, fontWeight: FontWeight.w800, fontSize: 17),
        ),
        bottom: TabBar(
          controller: _tabController,
          labelColor: AppTheme.primaryColor,
          unselectedLabelColor: Colors.grey.shade400,
          indicatorColor: AppTheme.primaryColor,
          indicatorWeight: 3,
          labelStyle: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 13),
          unselectedLabelStyle: GoogleFonts.inter(fontWeight: FontWeight.w500, fontSize: 13),
          tabs: const [
            Tab(text: 'Cash'),
            Tab(text: 'Coins'),
            Tab(text: 'Kits'),
          ],
        ),
      ),
      body: RefreshIndicator(
        onRefresh: _refreshAll,
        color: AppTheme.primaryColor,
        child: TabBarView(
          controller: _tabController,
          children: [
            _buildCashTab(),
            _buildCoinsTab(),
            _buildKitsTab(),
          ],
        ),
      ),
    );
  }

  // ─── CASH TAB ──────────────────────────────────────────────────────────────
  Widget _buildCashTab() {
    if (_loadingCash) return _loadingView();
    if (_cashTxs.isEmpty) return _emptyState(icon: Icons.account_balance_wallet_outlined, message: 'No cash transactions yet');

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _cashTxs.length,
      itemBuilder: (_, i) {
        final tx = _cashTxs[i];
        return _txCard(
          title: (tx.description.isEmpty == true || tx.description == '') ? 'Transaction' : tx.description,
          subtitle: tx.date,
          amount: tx.amount,
          isCredit: tx.type == 'credit',
          icon: tx.type == 'credit' ? Icons.arrow_downward_rounded : Icons.arrow_upward_rounded,
          tagColor: tx.type == 'credit' ? Colors.green : Colors.red,
        );
      },
    );
  }

  // ─── COINS TAB ─────────────────────────────────────────────────────────────
  Widget _buildCoinsTab() {
    if (_loadingCoins) return _loadingView();
    if (_coinTxs.isEmpty) return _emptyState(icon: Icons.toll_rounded, message: 'No coin transactions yet');

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _coinTxs.length,
      itemBuilder: (_, i) {
        final tx = _coinTxs[i];
        return _txCard(
          title: (tx.description.isEmpty == true || tx.description == '') ? 'Coin Reward' : tx.description,
          subtitle: tx.date,
          amount: tx.amount,
          isCredit: tx.type == 'credit',
          icon: tx.type == 'credit' ? Icons.add_circle_outline_rounded : Icons.remove_circle_outline_rounded,
          tagColor: const Color(0xFFFFB020),
          isCoin: true,
        );
      },
    );
  }

  // ─── KITS TAB ───────────────────────────────────────────────────────────────
  Widget _buildKitsTab() {
    if (_loadingKits) return _loadingView();
    if (_kitOrders.isEmpty) {
      return _emptyState(icon: Icons.inventory_2_outlined, message: 'No kit orders yet');
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _kitOrders.length,
      itemBuilder: (_, i) => _kitOrderCard(_kitOrders[i]),
    );
  }

  Widget _kitOrderCard(pro_models.KitOrderModel order) {
    final isDelivered = order.orderStatus.toLowerCase() == 'delivered';
    final isPending   = order.orderStatus.toLowerCase() == 'processing';
    final statusColor = isDelivered ? Colors.green : isPending ? Colors.orange : Colors.blue;

    String dateFormatted = order.assignedAt;
    try {
      dateFormatted = DateFormat('dd MMM yyyy').format(DateTime.parse(order.assignedAt));
    } catch (_) {}

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.grey.shade100),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.inventory_2_outlined, color: Colors.grey, size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  order.productName,
                  style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 14, color: Colors.black87),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 3),
                Text(
                  'Qty: ${order.quantity}  ·  $dateFormatted',
                  style: GoogleFonts.inter(color: Colors.grey.shade500, fontSize: 12),
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: statusColor.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        order.orderStatus,
                        style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w700, color: statusColor),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: order.paymentStatus.toLowerCase() == 'paid'
                            ? Colors.green.withValues(alpha: 0.1)
                            : Colors.orange.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        order.paymentStatus,
                        style: GoogleFonts.inter(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: order.paymentStatus.toLowerCase() == 'paid' ? Colors.green : Colors.orange,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Text(
            '₹${order.totalAmount > 0 ? order.totalAmount.toStringAsFixed(0) : order.productPrice.toStringAsFixed(0)}',
            style: GoogleFonts.inter(fontWeight: FontWeight.w800, fontSize: 15, color: Colors.black),
          ),
        ],
      ),
    );
  }

  // ─── SHARED WIDGETS ─────────────────────────────────────────────────────────
  Widget _txCard({
    required String title,
    required String subtitle,
    required double amount,
    required bool isCredit,
    required IconData icon,
    required Color tagColor,
    bool isCoin = false,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.grey.shade100),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: tagColor.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 20, color: tagColor),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 14, color: Colors.black87),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 3),
                Text(
                  subtitle,
                  style: GoogleFonts.inter(color: Colors.grey.shade400, fontSize: 12),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '${isCredit ? '+' : '-'}${isCoin ? '' : '₹'}${amount.toStringAsFixed(0)}${isCoin ? ' 🪙' : ''}',
                style: GoogleFonts.inter(
                  fontWeight: FontWeight.w800,
                  fontSize: 15,
                  color: isCredit ? Colors.green : Colors.red,
                ),
              ),
              const SizedBox(height: 4),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: tagColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  isCredit ? 'Credit' : 'Debit',
                  style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.w700, color: tagColor),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _loadingView() {
    return Center(child: CircularProgressIndicator(color: AppTheme.primaryColor));
  }

  Widget _emptyState({required IconData icon, required String message}) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 56, color: Colors.grey.shade200),
          const SizedBox(height: 16),
          Text(
            message,
            style: GoogleFonts.inter(color: Colors.grey.shade400, fontSize: 14, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}
