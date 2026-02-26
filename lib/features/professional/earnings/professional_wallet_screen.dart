import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/theme/app_theme.dart';

enum WalletType { earnings, coins }

class ProfessionalWalletScreen extends StatefulWidget {
  const ProfessionalWalletScreen({super.key});

  @override
  State<ProfessionalWalletScreen> createState() => _ProfessionalWalletScreenState();
}

class _ProfessionalWalletScreenState extends State<ProfessionalWalletScreen> {
  final ScrollController _scrollController = ScrollController();
  bool _isScrolled = false;
  WalletType _activeWallet = WalletType.earnings;

  // Constants
  static const double minWithdrawalAmount = 1500.0;
  static const Color pinkPrimary = Color(0xFFE1306C);
  static const Color goldPrimary = Color(0xFFFFB800);

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
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
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            _buildWalletSelector(),
            Expanded(
              child: SingleChildScrollView(
                controller: _scrollController,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 20),
                      _activeWallet == WalletType.earnings 
                          ? _buildEarningsCard() 
                          : _buildCoinsCard(),
                      const SizedBox(height: 30),
                      Text(
                        _activeWallet == WalletType.earnings 
                            ? 'Earnings History' 
                            : 'Coin Rewards History',
                        style: GoogleFonts.outfit(fontSize: 20, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 15),
                      if (_activeWallet == WalletType.earnings) ...[
                        _buildTransactionItem('Bridal Makeup Payout', '₹4,500', 'Today, 2:30 PM', true),
                        _buildTransactionItem('Successful Withdrawal', '-₹10,000', 'Yesterday, 10:00 AM', false),
                        _buildTransactionItem('Hair Styling Payout', '₹1,200', '10 Aug, 4:00 PM', true),
                      ] else ...[
                        _buildTransactionItem('Referral Bonus', '500 Coins', 'Today, 11:15 AM', true),
                        _buildTransactionItem('Weekly Bonus', '200 Coins', 'Yesterday, 09:00 AM', true),
                        _buildTransactionItem('Profile Completion', '150 Coins', '15 Aug, 02:00 PM', true),
                      ],
                      const SizedBox(height: 30),
                      if (_activeWallet == WalletType.coins) _buildCoinEarnInfo(),
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
          IconButton(
            icon: const Icon(Icons.arrow_back_ios_new, size: 20),
            color: _isScrolled ? Colors.white : Colors.black,
            onPressed: () => context.go('/professional/earnings'),
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
          Expanded(child: _buildSelectorOption('BellaVella Coins', WalletType.coins)),
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

  Widget _buildEarningsCard() {
    const balance = 12450.0;
    const isWithdrawAllowed = balance >= minWithdrawalAmount;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [pinkPrimary, pinkPrimary.withOpacity(0.8)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(color: pinkPrimary.withOpacity(0.3), blurRadius: 20, offset: const Offset(0, 10)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Income Balance',
                style: GoogleFonts.outfit(color: Colors.white70, fontSize: 16),
              ),
              const Icon(Icons.info_outline, color: Colors.white54, size: 20),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            '₹12,450',
            style: GoogleFonts.outfit(color: Colors.white, fontSize: 36, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: ElevatedButton(
                  onPressed: () {
                    // Future: Show Add Money dialog
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white.withOpacity(0.2),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    elevation: 0,
                  ),
                  child: Text(
                    'Add Money',
                    style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  onPressed: isWithdrawAllowed ? () {} : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: pinkPrimary,
                    disabledBackgroundColor: Colors.white54,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    elevation: 0,
                  ),
                  child: Text(
                    'Withdraw',
                    style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                ),
              ),
            ],
          ),
          if (!isWithdrawAllowed)
            Padding(
              padding: const EdgeInsets.only(top: 12),
              child: Text(
                'Minimum ₹1,500 required to withdraw',
                style: GoogleFonts.outfit(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w500),
              ),
            ),
        ],
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
}
