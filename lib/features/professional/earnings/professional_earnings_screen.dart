import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/router/route_names.dart';
import '../services/professional_api_service.dart';
import '../models/professional_models.dart' as pro_models;

class ProfessionalEarningsScreen extends StatefulWidget {
  const ProfessionalEarningsScreen({super.key});

  @override
  State<ProfessionalEarningsScreen> createState() => _ProfessionalEarningsScreenState();
}

class _ProfessionalEarningsScreenState extends State<ProfessionalEarningsScreen> {
  pro_models.ProfessionalDashboardStats? _stats;
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
      final stats = await ProfessionalApiService.getDashboardStats();
      if (mounted) {
        setState(() {
          _stats = stats;
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
              ElevatedButton(onPressed: _fetchStats, child: const Text('Retry')),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _fetchStats,
          color: AppTheme.primaryColor,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            child: Column(
              children: [
                _buildHeader(),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 20),
                      _buildMainStats(),
                      const SizedBox(height: 25),
                      _buildActionGrid(),
                      const SizedBox(height: 30),
                      _buildActiveJobs(),
                      const SizedBox(height: 30),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => context.pop(),
          ),
          const Text(
            'Earnings Overview',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          IconButton(
            icon: const Icon(Icons.help_outline),
            onPressed: () {},
          ),
        ],
      ),
    );
  }

  Widget _buildMainStats() {
    final earnings = _stats?.totalEarnings ?? 0.0;
    final totalJobs = _stats?.totalBookings ?? 0;
    
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppTheme.primaryColor, AppTheme.primaryColor.withOpacity(0.8)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(30),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primaryColor.withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Total Earnings',
            style: TextStyle(color: Colors.white70, fontSize: 16),
          ),
          const SizedBox(height: 8),
          Text(
            '₹${earnings.toStringAsFixed(2)}',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 36,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              _buildSimpleStat('Jobs Done', '$totalJobs'),
              const SizedBox(width: 40),
              const _buildSimpleStat('Success Rate', '98%'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildActionGrid() {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 3,
      mainAxisSpacing: 15,
      crossAxisSpacing: 15,
      children: [
        _buildActionItem('Wallet', Icons.account_balance_wallet, () => context.push(AppRoutes.proWallet)),
        _buildActionItem('Payouts', Icons.payments, () {}),
        _buildActionItem('Tax Info', Icons.description, () {}),
      ],
    );
  }

  Widget _buildActionItem(String label, IconData icon, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.grey.shade100),
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10, offset: const Offset(0, 4)),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: AppTheme.primaryColor),
            const SizedBox(height: 8),
            Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }

  Widget _buildActiveJobs() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Active Job Requests',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            TextButton(
              onPressed: () => context.push(AppRoutes.proJobs),
              child: const Text('View All'),
            ),
          ],
        ),
        const SizedBox(height: 15),
        const Text(
          'Check the "Job Requests" page for new opportunities.',
          style: TextStyle(color: AppTheme.greyText),
        ),
      ],
    );
  }
}

class _buildSimpleStat extends StatelessWidget {
  final String label;
  final String value;
  const _buildSimpleStat(this.label, this.value);

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(color: Colors.white70, fontSize: 12)),
        const SizedBox(height: 4),
        Text(value, style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
      ],
    );
  }
}
