import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/theme/app_theme.dart';

class ClientWalletScreen extends StatelessWidget {
  const ClientWalletScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'BellaVella Wallet',
          style: GoogleFonts.outfit(
            color: Colors.black,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            _buildBalanceCard(),
            const SizedBox(height: 30),
            _buildHowToEarnSection(),
            const SizedBox(height: 30),
            _buildTransactionHistory(),
          ],
        ),
      ),
    );
  }

  Widget _buildBalanceCard() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A1A), // Sleek deep charcoal
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.15),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Balance',
                    style: GoogleFonts.outfit(
                      color: Colors.grey.shade400,
                      fontSize: 14,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(Icons.stars_rounded, color: Colors.amber, size: 24),
                      const SizedBox(width: 8),
                      Text(
                        '1,250',
                        style: GoogleFonts.outfit(
                          color: Colors.white,
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  'BellaVella Coins',
                  style: GoogleFonts.outfit(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          const Divider(color: Colors.white12, height: 1),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '1 Coin = ₹1.00',
                style: GoogleFonts.outfit(
                  color: Colors.white54,
                  fontSize: 12,
                ),
              ),
              GestureDetector(
                onTap: () {},
                child: Row(
                  children: [
                    Text(
                      'Redeem now',
                      style: GoogleFonts.outfit(
                        color: AppTheme.primaryColor,
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Icon(Icons.chevron_right, color: AppTheme.primaryColor, size: 18),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildHowToEarnSection() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Earn more rewards',
            style: GoogleFonts.outfit(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.black,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              _buildEarnCard(
                icon: Icons.calendar_today_rounded,
                title: 'Daily Check-in',
                reward: '10 Coins',
                subtitle: 'Earn daily',
                iconColor: const Color(0xFF4A90E2),
              ),
              const SizedBox(width: 12),
              _buildEarnCard(
                icon: Icons.people_outline_rounded,
                title: 'Refer Friend',
                reward: '500 Coins',
                subtitle: 'Invite & Get',
                iconColor: const Color(0xFFF5A623),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _buildWideEarnCard(
            icon: Icons.card_giftcard_rounded,
            title: 'Complete 5 Bookings reward',
            reward: '100 Coins',
          ),
        ],
      ),
    );
  }

  Widget _buildEarnCard({
    required IconData icon,
    required String title,
    required String reward,
    required String subtitle,
    required Color iconColor,
  }) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.grey.shade100),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.02),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: iconColor.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: iconColor, size: 20),
            ),
            const SizedBox(height: 12),
            Text(
              title,
              style: GoogleFonts.outfit(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              reward,
              style: GoogleFonts.outfit(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: iconColor,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: GoogleFonts.outfit(
                fontSize: 11,
                color: Colors.grey.shade500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWideEarnCard({
    required IconData icon,
    required String title,
    required String reward,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.primaryColor.withOpacity(0.02),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.primaryColor.withOpacity(0.1)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppTheme.primaryColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: AppTheme.primaryColor, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.outfit(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                    color: Colors.black,
                  ),
                ),
                Text(
                  'Exclusive milestone reward',
                  style: GoogleFonts.outfit(
                    fontSize: 12,
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          ),
          Text(
            reward,
            style: GoogleFonts.outfit(
              color: AppTheme.primaryColor,
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTransactionHistory() {
    final transactions = [
      {'title': 'Daily Reward', 'date': 'Today, 10:30 AM', 'amount': '+10', 'type': 'credit'},
      {'title': 'Referral Bonus - Amit', 'date': 'Yesterday', 'amount': '+500', 'type': 'credit'},
      {'title': 'Signup Bonus', 'date': '22 Feb 2026', 'amount': '+500', 'type': 'credit'},
      {'title': 'Facial Service Payment', 'date': '20 Feb 2026', 'amount': '-200', 'type': 'debit'},
    ];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Recent Activity',
                style: GoogleFonts.outfit(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),
              Text(
                'View history',
                style: GoogleFonts.outfit(
                  color: AppTheme.primaryColor,
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: transactions.length,
            separatorBuilder: (context, index) => Divider(height: 1, color: Colors.grey.shade100),
            itemBuilder: (context, index) {
              final tx = transactions[index];
              final isCredit = tx['type'] == 'credit';
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 16),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: isCredit ? Colors.green.withOpacity(0.05) : Colors.red.withOpacity(0.05),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        isCredit ? Icons.add_circle_outline_rounded : Icons.remove_circle_outline_rounded,
                        color: isCredit ? Colors.green : Colors.red,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            tx['title']!,
                            style: GoogleFonts.outfit(
                              fontWeight: FontWeight.w600,
                              fontSize: 15,
                              color: Colors.black,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            tx['date']!,
                            style: GoogleFonts.outfit(
                              color: Colors.grey.shade500,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Text(
                      tx['amount']!,
                      style: GoogleFonts.outfit(
                        color: isCredit ? Colors.green : Colors.black,
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
          const SizedBox(height: 40),
        ],
      ),
    );
  }
}
