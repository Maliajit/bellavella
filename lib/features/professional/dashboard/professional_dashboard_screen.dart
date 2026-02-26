import 'dart:math' as Math;
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:confetti/confetti.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/professional_bottom_nav.dart';
import '../../../core/utils/permission_handler_util.dart';

class ProfessionalDashboardScreen extends StatefulWidget {
  const ProfessionalDashboardScreen({super.key});

  @override
  State<ProfessionalDashboardScreen> createState() =>
      _ProfessionalDashboardScreenState();
}

class _ProfessionalDashboardScreenState
    extends State<ProfessionalDashboardScreen> {
  bool _isOnline = false;
  final ScrollController _scrollController = ScrollController();
  bool _isScrolled = false;
  late ConfettiController _confettiController;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    _confettiController =
        ConfettiController(duration: const Duration(seconds: 3));
    _confettiController.play();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      PermissionHandlerUtil.requestAllPermissions(context);
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _confettiController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.hasClients) {
      if (_scrollController.offset > 0 && !_isScrolled) {
        setState(() => _isScrolled = true);
      } else if (_scrollController.offset <= 0 && _isScrolled) {
        setState(() => _isScrolled = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          SafeArea(
            child: Column(
              children: [
                _buildHeader(),
                Expanded(
                  child: ListView(
                    controller: _scrollController,
                    padding: EdgeInsets.zero,
                    children: [
                      _buildGreeting(),
                      _buildStatsSection(),
                      _buildTopPartnersSection(),
                      _buildNewLeadsSection(),
                      _buildAnnouncementsSection(),
                      const SizedBox(height: 100), // Extra space for bottom nav
                    ],
                  ),
                ),
              ],
            ),
          ),
          Align(
            alignment: Alignment.topCenter,
            child: ConfettiWidget(
              confettiController: _confettiController,
              blastDirectionality: BlastDirectionality.explosive,
              shouldLoop: false,
              colors: const [
                Colors.green,
                Colors.blue,
                Colors.pink,
                Colors.orange,
                Colors.purple,
                AppTheme.primaryColor,
              ],
              createParticlePath: drawStar,
            ),
          ),
        ],
      ),
      bottomNavigationBar: const ProfessionalBottomNav(currentIndex: 0),
    );
  }

  /// A custom Path to paint stars for the confetti
  Path drawStar(Size size) {
    // Method to convert degree to radians
    double degToRad(double deg) => deg * (3.1415926535897932 / 180.0);

    const numberOfPoints = 5;
    final halfWidth = size.width / 2;
    final externalRadius = halfWidth;
    final internalRadius = halfWidth / 2.5;
    final degreesPerStep = degToRad(360 / numberOfPoints);
    final halfDegreesPerStep = degreesPerStep / 2;
    final path = Path();
    final fullAngle = degToRad(360);
    path.moveTo(size.width, halfWidth);

    for (double step = 0; step < fullAngle; step += degreesPerStep) {
      path.lineTo(halfWidth + externalRadius * Math.cos(step),
          halfWidth + externalRadius * Math.sin(step));
      path.lineTo(halfWidth + internalRadius * Math.cos(step + halfDegreesPerStep),
          halfWidth + internalRadius * Math.sin(step + halfDegreesPerStep));
    }
    path.close();
    return path;
  }

  Widget _buildHeader() {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      height: 70,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      decoration: BoxDecoration(
        color: _isScrolled ? AppTheme.primaryColor : Colors.white,
        boxShadow: _isScrolled
            ? [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ]
            : [],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Flexible(
            child: Text(
              'Dashboard',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: _isScrolled ? Colors.white : Colors.black,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Row(
            children: [
              Text(
                _isOnline ? 'ON' : 'OFF',
                style: TextStyle(
                  color: _isScrolled
                      ? Colors.white
                      : (_isOnline ? Colors.green : Colors.red),
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
              const SizedBox(width: 4),
              Transform.scale(
                scale: 0.8,
                child: Switch(
                  value: _isOnline,
                  onChanged: (val) {
                    if (val) {
                      _attemptGoLive();
                    } else {
                      setState(() => _isOnline = false);
                    }
                  },
                  activeColor: Colors.white,
                  activeTrackColor: Colors.green,
                ),
              ),
              const SizedBox(width: 8),
              Icon(
                Icons.notifications_none,
                color: _isScrolled ? Colors.white : Colors.black,
                size: 24,
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _attemptGoLive() {
    // Mock data for validation
    const double currentBalance = 12450.0; // In reality, fetch from wallet service
    const int currentKits = 3; // Mocking 3 kits to trigger the error sheet (Requirement: 5)

    if (currentBalance >= 1500 && currentKits >= 5) {
      setState(() => _isOnline = true);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('You are now Online! Receiving bookings...'),
            backgroundColor: Colors.green),
      );
    } else {
      _showGoLiveRequirements(currentBalance, currentKits);
    }
  }

  void _showGoLiveRequirements(double balance, int kits) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.only(
              topLeft: Radius.circular(32), topRight: Radius.circular(32)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Go-Live Requirements',
              style:
                  GoogleFonts.outfit(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              'Complete these tasks to start receiving bookings today.',
              style: GoogleFonts.outfit(color: Colors.grey.shade600),
            ),
            const SizedBox(height: 24),
            _buildRequirementRow(
              'Min. ₹1,500 Balance',
              balance >= 1500,
              'Current: ₹${balance.toStringAsFixed(0)}',
              () => context.push('/professional/wallet'),
            ),
            const SizedBox(height: 16),
            _buildRequirementRow(
              'Min. 5 Official Kits',
              kits >= 5,
              'Current: $kits Kits',
              () => _showKitStore(),
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryColor,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16)),
                ),
                child: const Text('I Understand',
                    style: TextStyle(
                        fontWeight: FontWeight.bold, color: Colors.white)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRequirementRow(
      String label, bool isMet, String subtitle, VoidCallback onAction) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isMet ? Colors.green.shade50 : Colors.grey.shade50,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
            color: isMet ? Colors.green.withOpacity(0.2) : Colors.grey.shade100),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 12,
            backgroundColor: isMet ? Colors.green : Colors.grey.shade300,
            child: Icon(isMet ? Icons.check : Icons.priority_high,
                color: Colors.white, size: 14),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label,
                    style: GoogleFonts.outfit(
                        fontWeight: FontWeight.bold, fontSize: 16)),
                Text(subtitle,
                    style: GoogleFonts.outfit(
                        fontSize: 13, color: Colors.grey.shade600)),
              ],
            ),
          ),
          if (!isMet)
            TextButton(
              onPressed: onAction,
              child: Text('FIX NOW',
                  style: GoogleFonts.outfit(
                      color: AppTheme.primaryColor,
                      fontWeight: FontWeight.bold)),
            ),
        ],
      ),
    );
  }

  void _showKitStore() {
    Navigator.pop(context); // Close bottom sheet
    context.push('/professional/kit-store');
  }


  Widget _buildGreeting() {
    return const Padding(
      padding: EdgeInsets.all(20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Hello, Kevin!',
            style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
          ),
          Text(
            'Welcome back to your dashboard',
            style: TextStyle(color: Colors.grey, fontSize: 16),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsSection() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: [
          Expanded(
            child: _buildStatCard(
              'Total Orders',
              '12',
              Icons.shopping_basket_outlined,
              Colors.blue,
            ),
          ),
          const SizedBox(width: 15),
          Expanded(
            child: _buildStatCard(
              'Total Earnings',
              '₹15,200',
              Icons.account_balance_wallet_outlined,
              Colors.green,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color),
          const SizedBox(height: 15),
          Text(
            value,
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          Text(label, style: const TextStyle(color: Colors.black54)),
        ],
      ),
    );
  }

  Widget _buildTopPartnersSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 20, vertical: 15),
          child: Text(
            'Top Partners',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
        ),
        SizedBox(
          height: 100,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 10),
            itemCount: 5,
            itemBuilder: (context, index) => Container(
              width: 70,
              margin: const EdgeInsets.symmetric(horizontal: 10),
              decoration: BoxDecoration(
                color: Colors.grey.shade200,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.person, color: Colors.grey),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildNewLeadsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 20, vertical: 15),
          child: Text(
            'New Leads',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
        ),
        _buildLeadCard('Sia Kapoor', 'Bridal Makeup', 'Today, 2:00 PM'),
        _buildLeadCard('Riya Sharma', 'Facial & Cleanup', 'Tomorrow, 11:00 AM'),
      ],
    );
  }

  Widget _buildLeadCard(String name, String service, String time) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey.shade100),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: AppTheme.secondaryColor.withOpacity(0.3),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.person_outline,
              color: AppTheme.primaryColor,
            ),
          ),
          const SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                Text(service, style: const TextStyle(color: Colors.black54)),
                const SizedBox(height: 5),
                Row(
                  children: [
                    const Icon(Icons.access_time, size: 14, color: Colors.grey),
                    const SizedBox(width: 5),
                    Expanded(
                      child: Text(
                        time,
                        style: const TextStyle(
                          color: Colors.grey,
                          fontSize: 12,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton(
                      onPressed: () {},
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primaryColor,
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        minimumSize: const Size(70, 36),
                      ),
                      child: const Text(
                        'Accept',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAnnouncementsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 20, vertical: 15),
          child: Text(
            'Announcements',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
        ),
        _buildAnnouncementCard(
          'Special Bonus!',
          'Complete 10 jobs this week and earn ₹500 extra bonus.',
        ),
        _buildAnnouncementCard(
          'New Policy Update',
          'Please upload your KYC documents before 25th June.',
        ),
      ],
    );
  }

  Widget _buildAnnouncementCard(String title, String subtitle) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.pink.shade50.withOpacity(0.3),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: Colors.pink,
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            subtitle,
            style: const TextStyle(color: Colors.black87, fontSize: 14),
          ),
        ],
      ),
    );
  }
}
