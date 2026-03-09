import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:bellavella/core/theme/app_theme.dart';
import '../models/professional_models.dart' as pro_models;
import '../services/professional_api_service.dart';

class ProfessionalTransactionHistoryScreen extends StatefulWidget {
  const ProfessionalTransactionHistoryScreen({super.key});

  @override
  State<ProfessionalTransactionHistoryScreen> createState() => _ProfessionalTransactionHistoryScreenState();
}

class _ProfessionalTransactionHistoryScreenState extends State<ProfessionalTransactionHistoryScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  pro_models.ProfessionalWallet? _wallet;
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _fetchData();
  }

  Future<void> _fetchData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      final wallet = await ProfessionalApiService.getWallet();
      if (mounted) {
        setState(() {
          _wallet = wallet;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.black, size: 20),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          'Transaction History',
          style: GoogleFonts.outfit(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 18),
        ),
        bottom: TabBar(
          controller: _tabController,
          labelColor: AppTheme.primaryColor,
          unselectedLabelColor: Colors.grey,
          indicatorColor: AppTheme.primaryColor,
          labelStyle: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 14),
          tabs: const [
            Tab(text: 'Cash'),
            Tab(text: 'Coins'),
            Tab(text: 'Kits'),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppTheme.primaryColor))
          : _errorMessage != null
              ? Center(child: Text('Error: $_errorMessage'))
              : TabBarView(
                  controller: _tabController,
                  children: [
                    _buildCashHistory(),
                    _buildCoinsHistory(),
                    _buildKitsHistory(),
                  ],
                ),
    );
  }

  Widget _buildCashHistory() {
    final txs = _wallet?.transactions ?? [];
    if (txs.isEmpty) return _buildEmptyState('No cash transactions yet');

    return ListView.builder(
      padding: EdgeInsets.all(20),
      itemCount: txs.length,
      itemBuilder: (context, index) {
        final tx = txs[index];
        return _buildTransactionItem(
          title: tx.description,
          subtitle: tx.date,
          amount: '₹${tx.amount}',
          isCredit: tx.type == 'credit',
          icon: Icons.payments_outlined,
        );
      },
    );
  }

  Widget _buildCoinsHistory() {
    // Mock for now as backend might not have separate log yet
    return _buildEmptyState('Coin rewards history coming soon');
  }

  Widget _buildKitsHistory() {
    // Mock for now
    return _buildEmptyState('Inventory logs coming soon');
  }

  Widget _buildEmptyState(String message) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.history_toggle_off_rounded, size: 48, color: Colors.grey.shade300),
          const SizedBox(height: 16),
          Text(
            message,
            style: GoogleFonts.outfit(color: Colors.grey, fontSize: 14),
          ),
        ],
      ),
    );
  }

  Widget _buildTransactionItem({
    required String title,
    required String subtitle,
    required String amount,
    required bool isCredit,
    required IconData icon,
  }) {
    return Container(
      margin: EdgeInsets.only(bottom: 16),
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade100),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10, offset: const Offset(0, 4)),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: isCredit ? Colors.green.withOpacity(0.1) : Colors.red.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 18, color: isCredit ? Colors.green : Colors.red),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 15, color: Colors.black87),
                ),
                Text(
                  subtitle,
                  style: GoogleFonts.outfit(color: Colors.grey, fontSize: 12),
                ),
              ],
            ),
          ),
          Text(
            (isCredit ? '+ ' : '- ') + amount,
            style: GoogleFonts.outfit(
              fontWeight: FontWeight.bold,
              fontSize: 16,
              color: isCredit ? Colors.green : Colors.black87,
            ),
          ),
        ],
      ),
    );
  }
}
