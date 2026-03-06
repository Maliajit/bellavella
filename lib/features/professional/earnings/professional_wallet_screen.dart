import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:bellavella/core/router/route_names.dart';
import 'package:bellavella/core/theme/app_theme.dart';
import 'package:bellavella/features/professional/services/professional_api_service.dart';
import 'package:bellavella/features/professional/models/professional_models.dart' as pro_models;

enum WalletType { earnings, coins, kits }

class ProfessionalWalletScreen extends StatefulWidget {
  const ProfessionalWalletScreen({super.key});

  @override
  State<ProfessionalWalletScreen> createState() => _ProfessionalWalletScreenState();
}

class _ProfessionalWalletScreenState extends State<ProfessionalWalletScreen> {
  pro_models.ProfessionalWallet? _wallet;
  pro_models.ProfessionalDashboardStats? _dashboardStats;
  bool _isLoading = true;
  String? _errorMessage;
  final ScrollController _scrollController = ScrollController();
  bool _isScrolled = false;
  WalletType _activeWallet = WalletType.earnings;
  static const Color goldPrimary = Color(0xFFFFB800);
  static const Color pinkPrimary = Color(0xFFFF7E98);

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    _fetchWalletData();
  }

  Future<void> _fetchWalletData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      final wallet = await ProfessionalApiService.getWallet();
      final stats = await ProfessionalApiService.getDashboardStats();
      if (mounted) {
        setState(() {
          _wallet = wallet;
          _dashboardStats = stats;
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
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.offset > 0 && !_isScrolled) {
      setState(() => _isScrolled = true);
    } else if (_scrollController.offset <= 0 && _isScrolled) {
      setState(() => _isScrolled = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator(color: AppTheme.primaryColor)),
      );
    }

    if (_errorMessage != null) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text('Error: $_errorMessage'),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _fetchWalletData,
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            _buildWalletSelector(),
            Expanded(
              child: RefreshIndicator(
                onRefresh: _fetchWalletData,
                color: AppTheme.primaryColor,
                child: SingleChildScrollView(
                  controller: _scrollController,
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 24),
                      if (_activeWallet == WalletType.earnings) ...[
                        _buildHeroEarnings(),
                        const SizedBox(height: 24),
                        _buildSummarySection(),
                        const SizedBox(height: 24),
                        _buildActiveJobsSection(),
                        const SizedBox(height: 24),
                        _buildQuickActionsSection(),
                        const SizedBox(height: 24),
                        _buildTransactionList(),
                      ] else if (_activeWallet == WalletType.coins) ...[
                        // ... coin content
                        _buildCoinsCard(),
                        const SizedBox(height: 30),
                        _buildSectionTitle('Coin Rewards History'),
                        const SizedBox(height: 15),
                        _buildTransactionItem('Referral Bonus', '500 Coins', 'Today, 11:15 AM', true),
                        _buildTransactionItem('Weekly Bonus', '200 Coins', 'Yesterday, 09:00 AM', true),
                        _buildTransactionItem('Profile Completion', '150 Coins', '15 Aug, 02:00 PM', true),
                        const SizedBox(height: 30),
                        _buildCoinEarnInfo(),
                      ] else ...[
                        _buildKitsCard(),
                        const SizedBox(height: 30),
                        _buildSectionTitle('Inventory Log'),
                        const SizedBox(height: 15),
                        _buildTransactionItem('Kit Assigned', '2 Kits', 'Today, 10:00 AM', true),
                        _buildTransactionItem('Service Completed', '-1 Kit', 'Yesterday, 4:30 PM', false),
                        _buildTransactionItem('Kit Assigned', '5 Kits', '12 Aug, 11:00 AM', true),
                      ],
                      const SizedBox(height: 100),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title.toUpperCase(),
      style: GoogleFonts.outfit(
        fontSize: 11, 
        fontWeight: FontWeight.w800, 
        color: Colors.grey.shade400, 
        letterSpacing: 1,
      ),
    );
  }

  Widget _buildHeader() {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      decoration: BoxDecoration(
        color: _isScrolled ? AppTheme.primaryColor : Colors.white,
        boxShadow: _isScrolled 
            ? [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4))]
            : [],
      ),
      child: Row(
        children: [
          if (context.canPop()) 
            IconButton(
              icon: const Icon(Icons.arrow_back_ios_new, size: 20),
              color: _isScrolled ? Colors.white : Colors.black,
              onPressed: () => context.pop(),
            ),
          Text(
            'Wallet',
            style: GoogleFonts.outfit(
              fontSize: 20, 
              fontWeight: FontWeight.bold,
              color: _isScrolled ? Colors.white : Colors.black,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWalletSelector() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Expanded(child: _buildSelectorOption('Earnings', WalletType.earnings)),
          Expanded(child: _buildSelectorOption('Coins', WalletType.coins)),
          Expanded(child: _buildSelectorOption('Service Kits', WalletType.kits)),
        ],
      ),
    );
  }

  Widget _buildSelectorOption(String label, WalletType type) {
    final isSelected = _activeWallet == type;
    return GestureDetector(
      onTap: () => setState(() => _activeWallet = type),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? Colors.white : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          boxShadow: isSelected ? [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 5)] : [],
        ),
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: GoogleFonts.outfit(
            fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
            color: isSelected ? pinkPrimary : Colors.grey.shade600,
          ),
        ),
      ),
    );
  }

  Widget _buildHeroEarnings() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade100, width: 2),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 20, offset: const Offset(0, 8)),
        ],
      ),
      child: Column(
        children: [
          Text(
            'Current Balance',
            style: GoogleFonts.outfit(color: Colors.grey.shade400, fontSize: 13, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 6),
          Text(
            '₹${_wallet?.balance ?? 0}',
            style: GoogleFonts.outfit(color: Colors.black, fontSize: 32, fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _heroMetric('52 Total Jobs', Icons.task_alt_rounded), // Still mock for now, but label updated
              _dot(),
              _heroMetric('₹${_dashboardStats?.todayEarnings ?? 0} Today', Icons.payments_outlined),
            ],
          ),
        ],
      ),
    );
  }

  Widget _heroMetric(String text, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 14, color: Colors.grey.shade400),
        const SizedBox(width: 6),
        Text(text, style: GoogleFonts.outfit(color: Colors.grey.shade500, fontSize: 13, fontWeight: FontWeight.w500)),
      ],
    );
  }

  Widget _dot() => Container(margin: const EdgeInsets.symmetric(horizontal: 12), width: 4, height: 4, decoration: BoxDecoration(color: Colors.grey.shade200, shape: BoxShape.circle));


  Widget _buildSummarySection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle("EARNINGS SUMMARY"),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(child: _summaryCardV3('Today', '₹${_dashboardStats?.todayEarnings ?? 0}')),
            const SizedBox(width: 12),
            Expanded(child: _summaryCardV3('Weekly', '₹${(_dashboardStats?.todayEarnings ?? 0) * 5}')), // Estimated
            const SizedBox(width: 12),
            Expanded(child: _summaryCardV3('Monthly', '₹${(_dashboardStats?.todayEarnings ?? 0) * 20}')), // Estimated
          ],
        ),
      ],
    );
  }

  Widget _summaryCardV3(String label, String amount) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade100, width: 2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: GoogleFonts.outfit(color: Colors.grey.shade400, fontSize: 10, fontWeight: FontWeight.w800)),
          const SizedBox(height: 4),
          Text(amount, style: GoogleFonts.outfit(color: Colors.black, fontSize: 15, fontWeight: FontWeight.w900)),
        ],
      ),
    );
  }

  Widget _buildActiveJobsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle("Active Jobs"),
        const SizedBox(height: 12),
        _jobRowV3('Jobs Assigned', '${_dashboardStats?.activeJobsCount ?? 0}'),
        _dividerV3(),
        _jobRowV3('In Progress', '${_dashboardStats?.activeJobsCount ?? 0}'),
      ],
    );
  }

  Widget _buildTransactionList() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle('RECENT TRANSACTIONS'),
        const SizedBox(height: 15),
        if (_wallet?.transactions.isEmpty ?? true)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 20),
            child: Center(child: Text('No transactions yet')),
          )
        else
          ...(_wallet!.transactions.map((tx) => 
            _buildTransactionItem(
              tx.description, 
              '₹${tx.amount}', 
              tx.date, 
              tx.type == 'credit'
            )
          )),
      ],
    );
  }

  Widget _jobRowV3(String label, String count) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: GoogleFonts.outfit(fontSize: 14, color: Colors.grey.shade600, fontWeight: FontWeight.w500)),
          Text(count, style: GoogleFonts.outfit(fontSize: 16, color: Colors.black, fontWeight: FontWeight.w900)),
        ],
      ),
    );
  }

  Widget _dividerV3() => Padding(padding: const EdgeInsets.symmetric(vertical: 14), child: Divider(color: Colors.grey.shade50, height: 1));

  Widget _buildQuickActionsSection() {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      childAspectRatio: 2.4,
      children: [
        _actionItemV3("Schedule", Icons.calendar_month_rounded),
        _actionItemV3("Transactions", Icons.history_rounded),
      ],
    );
  }

  Widget _actionItemV3(String label, IconData icon) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade100, width: 2),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 4, offset: const Offset(0, 2))],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
        onTap: () {
          if (label == 'Accept Jobs') context.push(AppRoutes.proJobs);
          if (label == 'Wallet') context.push(AppRoutes.proWallet);
          if (label == 'Schedule') context.push(AppRoutes.proSchedule);
          if (label == 'Transactions') context.pushNamed(AppRoutes.proTransactionsName);
        },
          borderRadius: BorderRadius.circular(16),
          child: Center(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, size: 18, color: Colors.black87),
                const SizedBox(width: 10),
                Text(label, style: GoogleFonts.outfit(fontSize: 13, fontWeight: FontWeight.w700, color: Colors.black87)),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCoinsCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [goldPrimary, Color(0xFFFF8A00)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(color: goldPrimary.withOpacity(0.3), blurRadius: 20, offset: const Offset(0, 10)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'BellaVella Coins',
                style: GoogleFonts.outfit(color: Colors.white70, fontSize: 16),
              ),
              CircleAvatar(
                radius: 12,
                backgroundColor: Colors.white24,
                child: Text('🪙', style: TextStyle(fontSize: 12)),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            '850',
            style: GoogleFonts.outfit(color: Colors.white, fontSize: 36, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                const Icon(Icons.auto_awesome, color: Colors.white, size: 16),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Loyalty rewards for our gold partners',
                    style: GoogleFonts.outfit(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w500),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTransactionItem(String title, String amount, String date, bool isCredit) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: Colors.grey.shade100, width: 1.5),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 8, offset: const Offset(0, 4)),
        ],
      ),
      child: Row(
        children: [
        const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.black87),
                ),
                Text(
                  date,
                  style: GoogleFonts.outfit(color: Colors.grey.shade500, fontSize: 13),
                ),
              ],
            ),
          ),
          Text(
            amount,
            style: GoogleFonts.outfit(
              fontWeight: FontWeight.bold,
              color: isCredit ? Colors.green : Colors.black87,
              fontSize: 17,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCoinEarnInfo() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.amber.shade50.withOpacity(0.5),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: goldPrimary.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'How to earn more coins?',
            style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.orange.shade900),
          ),
          const SizedBox(height: 12),
          _buildEarnRow(Icons.person_add_alt_1_outlined, 'Invite a new professional (500 Coins)'),
          const SizedBox(height: 8),
          _buildEarnRow(Icons.star_outline, 'Complete 5 jobs premium in a week (200 Coins)'),
          const SizedBox(height: 8),
          _buildEarnRow(Icons.verified_user_outlined, 'Verifying your profile (100 Coins)'),
        ],
      ),
    );
  }

  Widget _buildEarnRow(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, size: 18, color: goldPrimary),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            text,
            style: GoogleFonts.outfit(fontSize: 14, color: Colors.black87),
          ),
        ),
      ],
    );
  }

  Widget _buildKitsCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF6366F1), Color(0xFF4F46E5)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(color: const Color(0xFF6366F1).withOpacity(0.3), blurRadius: 20, offset: const Offset(0, 10)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Available Kits',
                style: GoogleFonts.outfit(color: Colors.white70, fontSize: 16),
              ),
              const Icon(Icons.inventory_2_outlined, color: Colors.white70, size: 20),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            '6',
            style: GoogleFonts.outfit(color: Colors.white, fontSize: 36, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () => context.push(AppRoutes.proKitStore),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: const Color(0xFF6366F1),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                padding: const EdgeInsets.symmetric(vertical: 14),
                elevation: 0,
              ),
              child: Text(
                'Get More Kits',
                style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 16),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Min 5 kits required to stay online',
            style: GoogleFonts.outfit(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }
}

