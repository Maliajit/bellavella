import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/models/data_models.dart';
import '../../../core/services/token_manager.dart';
import 'services/client_api_service.dart';

class ClientProfileScreen extends StatefulWidget {
  const ClientProfileScreen({super.key});

  @override
  State<ClientProfileScreen> createState() => _ClientProfileScreenState();
}

class _ClientProfileScreenState extends State<ClientProfileScreen> {
  Customer? _customer;
  bool _isLoading = true;
  String? _errorMessage;
  double _walletBalance = 0.0;
  int _addressCount = 0;

  @override
  void initState() {
    super.initState();
    _fetchProfile();
  }

  Future<void> _fetchProfile() async {
    if (!TokenManager.hasToken) {
      // user is not authenticated, send back to login
      if (mounted) {
        context.go('/client/login');
      }
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // Fetch profile, wallet, and addresses in parallel
      final results = await Future.wait([
        ClientApiService.getProfile(),
        ClientApiService.getWallet(),
        ClientApiService.getAddresses(),
      ]);

      if (mounted) {
        setState(() {
          _customer = results[0] as Customer;
          final walletData = results[1] as Map<String, dynamic>;
          _walletBalance = (walletData['balance'] as num?)?.toDouble() ?? 0.0;
          final addresses = results[2] as List;
          _addressCount = addresses.length;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        final message = e.toString();
        if (message.toLowerCase().contains('unauthenticated')) {
          // token might be invalid/expired
          TokenManager.clearToken();
          context.go('/client/login');
          return;
        }
        setState(() {
          _errorMessage = message;
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(color: AppTheme.primaryColor),
        ),
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
                onPressed: _fetchProfile,
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFFAFAFA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: Text(
          'Profile',
          style: GoogleFonts.outfit(
            color: Colors.black,
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            const SizedBox(height: 10),
            _buildProfileHeader(context),
            const SizedBox(height: 24),
            _buildProfileSection(
              title: 'ACCOUNT',
              options: [
                _ProfileOption(
                  icon: Icons.location_on_outlined,
                  title: 'Manage Address',
                  subtitle: '$_addressCount saved addresses',
                  onTap: () => context.push('/client/profile/manage-address'),
                ),
                _ProfileOption(
                  icon: Icons.account_balance_wallet_outlined,
                  title: 'My Wallet',
                  subtitle: '₹${_walletBalance.toStringAsFixed(0)} coins',
                  onTap: () => context.push('/client/wallet'),
                ),
                _ProfileOption(
                  icon: Icons.share_outlined,
                  title: 'Refer & Earn',
                  subtitle: 'Invite friends and earn rewards',
                  onTap: () => context.push('/client/profile/refer-earn'),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildProfileSection(
              title: 'SUPPORT & FEEDBACK',
              options: [
                _ProfileOption(
                  icon: Icons.star_outline_rounded,
                  title: 'Rate us',
                  onTap: () => context.push('/client/profile/rate-us'),
                ),
                _ProfileOption(
                  icon: Icons.info_outline_rounded,
                  title: 'About Us',
                  onTap: () => context.push('/client/profile/about-us'),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildProfileSection(
              title: 'ACTIONS',
              options: [
                _ProfileOption(
                  icon: Icons.logout_rounded,
                  title: 'Logout',
                  color: Colors.red.shade400,
                  onTap: () => context.go('/client/login'),
                ),
              ],
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileHeader(BuildContext context) {
    final avatarUrl = _customer?.avatar;
    final displayName = _customer?.name ?? 'User';
    final phone = _customer?.mobile ?? '';

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 70,
            height: 70,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.grey.shade100,
              border: Border.all(
                color: AppTheme.primaryColor.withValues(alpha: 0.1),
                width: 2,
              ),
              image: avatarUrl != null && avatarUrl.isNotEmpty
                  ? DecorationImage(
                      image: NetworkImage(avatarUrl),
                      fit: BoxFit.cover,
                    )
                  : null,
            ),
            child: avatarUrl == null || avatarUrl.isEmpty
                ? const Icon(Icons.person, size: 40, color: Colors.grey)
                : null,
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  displayName,
                  style: GoogleFonts.outfit(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  phone,
                  style: GoogleFonts.outfit(
                    fontSize: 14,
                    color: Colors.grey.shade600,
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ],
            ),
          ),
          GestureDetector(
            onTap: () async {
              await context.push('/client/profile/edit-profile');
              _fetchProfile();
            },
            child: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppTheme.primaryColor.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(14),
              ),
              child: const Icon(
                Icons.edit_outlined,
                color: AppTheme.primaryColor,
                size: 20,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileSection({
    required String title,
    required List<_ProfileOption> options,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 32, bottom: 12),
          child: Text(
            title,
            style: GoogleFonts.outfit(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: Colors.grey.shade500,
              letterSpacing: 1.2,
            ),
          ),
        ),
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.02),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            children: List.generate(options.length, (index) {
              final option = options[index];
              final isLast = index == options.length - 1;
              return Column(
                children: [
                  ListTile(
                    onTap: option.onTap,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 4,
                    ),
                    leading: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: (option.color ?? Colors.grey.shade600)
                            .withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(
                        option.icon,
                        color: option.color ?? Colors.grey.shade700,
                        size: 22,
                      ),
                    ),
                    title: Text(
                      option.title,
                      style: GoogleFonts.outfit(
                        color: option.color ?? Colors.black87,
                        fontSize: 15,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    subtitle: option.subtitle != null
                        ? Text(
                            option.subtitle!,
                            style: GoogleFonts.outfit(
                              color: Colors.grey.shade600,
                              fontSize: 12,
                              fontWeight: FontWeight.w400,
                            ),
                          )
                        : null,
                    trailing: const Icon(
                      Icons.arrow_forward_ios_rounded,
                      color: Colors.grey,
                      size: 14,
                    ),
                  ),
                  if (!isLast)
                    Padding(
                      padding: const EdgeInsets.only(left: 65),
                      child: Divider(height: 1, color: Colors.grey.shade100),
                    ),
                ],
              );
            }),
          ),
        ),
      ],
    );
  }
}

class _ProfileOption {
  final IconData icon;
  final String title;
  final String? subtitle;
  final VoidCallback onTap;
  final Color? color;

  _ProfileOption({
    required this.icon,
    required this.title,
    this.subtitle,
    required this.onTap,
    this.color,
  });
}
