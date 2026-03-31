import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:share_plus/share_plus.dart';
import 'package:bellavella/core/theme/app_theme.dart';
import '../../../core/widgets/base_widgets.dart';
import '../services/professional_api_service.dart';
import '../models/professional_models.dart' as pro_models;

class ProfessionalReferEarnScreen extends StatefulWidget {
  const ProfessionalReferEarnScreen({super.key});

  @override
  State<ProfessionalReferEarnScreen> createState() => _ProfessionalReferEarnScreenState();
}

class _ProfessionalReferEarnScreenState extends State<ProfessionalReferEarnScreen> {
  pro_models.ReferralStats? _stats;
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _fetchStats();
  }

  Future<void> _fetchStats() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      final stats = await ProfessionalApiService.getReferralStats();
      if (mounted) {
        setState(() {
          _stats = pro_models.ReferralStats.fromJson(stats);
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

  void _shareCode() {
    if (_stats == null) return;
    final code = _stats!.referralCode;
    Share.share(
      'Hey! Join BellaVella 💖\n\n'
      'Use my referral code: $code\n\n'
      'Download the app here: https://bellavella.com/download?ref=$code',
      subject: 'Join BellaVella',
    );
  }

  void _copyCode() {
    if (_stats == null) return;
    Clipboard.setData(ClipboardData(text: _stats!.referralCode));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Referral code copied to clipboard')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: false,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          'Refer & Earn',
          style: GoogleFonts.outfit(
            color: Colors.black, 
            fontWeight: FontWeight.bold, 
            fontSize: 20,
          ),
        ),
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator(color: AppTheme.primaryColor))
          : _errorMessage != null
              ? Center(child: Text('Error: $_errorMessage'))
              : _buildContent(),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
        child: PrimaryButton(
          label: 'Invite Friends',
          onPressed: _shareCode,
        ),
      ),
    );
  }

  Widget _buildContent() {
    return SingleChildScrollView(
      child: Column(
        children: [
          _buildHeader(),
          const SizedBox(height: 24),
          _buildReferralCodeCard(),
          const SizedBox(height: 32),
          _buildHowItWorks(),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 24),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Color(0xFFFF85A1), // Lighter pink
            Color(0xFFFF2D6F), // Primary pink
          ],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(40),
          bottomRight: Radius.circular(40),
        ),
      ),
      child: Column(
        children: [
          // Gift Box Icon with Circle Background
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.card_giftcard,
              color: Colors.white,
              size: 50,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'Invite friends & Earn Rewards!',
            textAlign: TextAlign.center,
            style: GoogleFonts.outfit(
              fontSize: 26,
              fontWeight: FontWeight.w800,
              color: Colors.white,
              height: 1.2,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            _stats != null 
              ? 'Share your referral code and earn ${_stats!.referrerReward} credits\nwhen your friends join & book services.'
              : 'Share your referral code and earn rewards\nwhen your friends join & book services.',
            textAlign: TextAlign.center,
            style: GoogleFonts.outfit(
              fontSize: 15,
              color: Colors.white.withOpacity(0.9),
              fontWeight: FontWeight.w500,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReferralCodeCard() {
    final code = (_stats?.referralCode == null || _stats!.referralCode.isEmpty) 
        ? 'NGA7NSUI' 
        : _stats!.referralCode;
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFFDEEF2)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              code,
              style: GoogleFonts.outfit(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: const Color(0xFF2E2E2E),
                letterSpacing: 2,
              ),
            ),
          ),
          Material(
            color: AppTheme.primaryColor,
            borderRadius: BorderRadius.circular(12),
            child: InkWell(
              onTap: _copyCode,
              borderRadius: BorderRadius.circular(12),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                child: Row(
                  children: [
                    const Icon(Icons.copy_all_rounded, color: Colors.white, size: 18),
                    const SizedBox(width: 8),
                    Text(
                      'Copy',
                      style: GoogleFonts.outfit(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHowItWorks() {
    return Column(
      children: [
        Text(
          'How it works',
          style: GoogleFonts.outfit(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: const Color(0xFF2E2E2E),
          ),
        ),
        const SizedBox(height: 24),
        _buildWorkStep(
          icon: Icons.person_add_alt_1_rounded,
          title: 'Invite your friends',
          description: 'Share your referral code with your friends.',
        ),
        _buildWorkStep(
          icon: Icons.sell_rounded,
          title: 'Friend joins & books',
          description: _stats != null 
            ? 'Your friend signs up and gets ${_stats!.referredReward} credits bonus.'
            : 'Your friend signs up and books their first service.',
        ),
        _buildWorkStep(
          icon: Icons.card_giftcard_rounded,
          title: 'Earn rewards',
          description: _stats != null
            ? 'You get ${_stats!.referrerReward} credits in your wallet after their service completion.'
            : 'You get rewards in your wallet after their service completion.',
        ),
      ],
    );
  }

  Widget _buildWorkStep({
    required IconData icon,
    required String title,
    required String description,
  }) {
    return Container(
      margin: const EdgeInsets.fromLTRB(24, 0, 24, 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFF5F5F5)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppTheme.primaryColor.withOpacity(0.08),
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              color: AppTheme.primaryColor,
              size: 24,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.outfit(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF2E2E2E),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: GoogleFonts.outfit(
                    fontSize: 14,
                    color: const Color(0xFF7A7A7A),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
