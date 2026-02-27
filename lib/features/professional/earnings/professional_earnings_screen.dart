import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/theme/app_theme.dart';

class ProfessionalEarningsScreen extends StatefulWidget {
  const ProfessionalEarningsScreen({super.key});

  @override
  State<ProfessionalEarningsScreen> createState() => _ProfessionalEarningsScreenState();
}

class _ProfessionalEarningsScreenState extends State<ProfessionalEarningsScreen> {
  final ScrollController _scrollController = ScrollController();
  bool _isScrolled = false;
  String _selectedMonth = 'This Month';

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
            Expanded(
              child: SingleChildScrollView(
                controller: _scrollController,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 20),
                      _buildMainStats(),
                      const SizedBox(height: 30),
                      _buildSectionHeader('Earnings Summary', showDropdown: true),
                      const SizedBox(height: 15),
                      _buildEarningsGrid(),
                      const SizedBox(height: 30),
                      _buildSectionHeader('Active Jobs'),
                      const SizedBox(height: 15),
                      _buildJobsList(),
                      const SizedBox(height: 30),
                      _buildSectionHeader('Quick Actions'),
                      const SizedBox(height: 15),
                      _buildQuickActions(),
                      const SizedBox(height: 30),
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
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
      decoration: BoxDecoration(
        color: _isScrolled ? AppTheme.primaryColor : Colors.white,
        boxShadow: _isScrolled 
            ? [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 10, offset: const Offset(0, 4))]
            : [],
      ),
      child: Row(
        children: [
          Text(
            'Earnings',
            style: TextStyle(
              fontSize: 24, 
              fontWeight: FontWeight.bold,
              color: _isScrolled ? Colors.white : Colors.black,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMainStats() {
    return Row(
      children: [
        Expanded(
          child: _buildMainStatCard(
            'Overall Earnings',
            '₹98,500',
            Colors.green.shade50,
            Colors.green.shade700,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildMainStatCard(
            'Total Hours',
            '120',
            Colors.blue.shade50,
            Colors.blue.shade700,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildMainStatCard(
            'Total Jobs',
            '45',
            Colors.orange.shade50,
            Colors.orange.shade700,
          ),
        ),
      ],
    );
  }

  Widget _buildMainStatCard(String title, String value, Color bgColor, Color textColor) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: Colors.black54),
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: textColor),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title, {bool showDropdown = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        if (showDropdown)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey.shade300),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Text(_selectedMonth, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
                const Icon(Icons.arrow_drop_down),
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildEarningsGrid() {
    return Row(
      children: [
        Expanded(
          child: _buildSummaryCard('₹450', 'Today', Icons.account_balance_wallet_outlined),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildSummaryCard('₹3,200', 'This Week', Icons.calendar_today_outlined),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildSummaryCard('₹12,800', 'This Month', Icons.account_balance_wallet),
        ),
      ],
    );
  }

  Widget _buildSummaryCard(String amount, String period, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey.shade100),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: Colors.pink.shade300, size: 24),
          const SizedBox(height: 12),
          Text(
            amount,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 4),
          Text(
            period,
            style: TextStyle(fontSize: 12, color: Colors.grey.shade400),
          ),
        ],
      ),
    );
  }

  Widget _buildJobsList() {
    return Column(
      children: [
        _buildJobStatusItem('Jobs Assigned', '5', Icons.work_outline, Colors.pink.shade300),
        const SizedBox(height: 12),
        _buildJobStatusItem('In Progress', '2', Icons.hourglass_bottom, Colors.pink.shade300),
      ],
    );
  }

  Widget _buildJobStatusItem(String label, String count, IconData icon, Color iconColor) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Icon(icon, color: iconColor),
          const SizedBox(width: 15),
          Text(label, style: const TextStyle(fontWeight: FontWeight.w500)),
          const Spacer(),
          Text(count, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        ],
      ),
    );
  }

  Widget _buildQuickActions() {
    return Row(
      children: [
        Expanded(child: _buildActionItem('Accept Jobs', Icons.check_circle_outline)),
        const SizedBox(width: 12),
        Expanded(child: _buildActionItem('Check Wallet', Icons.account_balance_wallet_outlined)),
        const SizedBox(width: 12),
        Expanded(child: _buildActionItem('Schedule', Icons.calendar_month_outlined)),
      ],
    );
  }

  Widget _buildActionItem(String label, IconData icon) {
    return GestureDetector(
      onTap: () {
        if (label == 'Accept Jobs') context.go('/professional/jobs');
        if (label == 'Check Wallet') context.go('/professional/wallet');
        if (label == 'Schedule') context.go('/professional/schedule');
      },
      child: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 20),
            decoration: BoxDecoration(
              color: Colors.pink.shade50.withOpacity(0.3),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(icon, color: Colors.pink, size: 28),
          ),
          const SizedBox(height: 8),
          Text(
            label, 
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

}
