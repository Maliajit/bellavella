import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:bellavella/core/services/api_service.dart';
import 'package:bellavella/core/theme/app_theme.dart';
import 'package:bellavella/core/utils/toast_util.dart';
import '../../../core/models/data_models.dart';
import '../../../core/services/token_manager.dart';
import 'services/client_profile_api_service.dart';

class ClientProfileScreen extends StatefulWidget {
  const ClientProfileScreen({super.key});

  @override
  State<ClientProfileScreen> createState() => _ClientProfileScreenState();
}

class _ClientProfileScreenState extends State<ClientProfileScreen> {
  Customer? _customer;
  bool _isLoading = true;
  bool _isLoggedIn = true;
  String? _errorMessage;
  double _walletBalance = 0.0;
  int _addressCount = 0;

  @override
  void initState() {
    super.initState();
    _fetchProfile();
  }

  Future<void> _logout() async {
    try {
      if (TokenManager.hasToken) {
        await ApiService.post('/client/auth/logout', {});
      }
    } catch (_) {
      // Ignore backend logout failures; local logout must still complete.
    } finally {
      await TokenManager.clearClientToken();
      if (!mounted) {
        return;
      }
      context.go('/client/home');
      ToastUtil.showSuccess(context, 'You have been logged out successfully');
    }
  }

  Future<void> _fetchProfile() async {
    if (!TokenManager.hasToken) {
      if (mounted) {
        setState(() {
          _customer = null;
          _walletBalance = 0;
          _addressCount = 0;
          _isLoggedIn = false;
          _isLoading = false;
        });
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
        ClientProfileApiService.getProfile(),
        ClientProfileApiService.getWallet(),
        ClientProfileApiService.getAddresses(),
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
        if (message.toLowerCase().contains('unauthenticated') ||
            message.contains(ApiService.sessionExpiredMessage)) {
          // token might be invalid/expired
          await TokenManager.clearClientToken();
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

  // ─────────────────────────────────────────────────────────────────────────
  // Login gate — shown when user is not authenticated
  // ─────────────────────────────────────────────────────────────────────────
  Widget _buildLoginGate() {
    return Scaffold(
      backgroundColor: const Color(0xFFFAFAFA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: Text(
          'Profile',
          style: GoogleFonts.outfit(
            color: Colors.black,
            fontWeight: FontWeight.w600,
            fontSize: 18,
          ),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Illustration circle
              Container(
                width: 110,
                height: 110,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      AppTheme.primaryColor.withOpacity(0.12),
                      AppTheme.primaryColor.withOpacity(0.04),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Icon(
                    Icons.person_outline_rounded,
                    size: 52,
                    color: AppTheme.primaryColor,
                  ),
                ),
              ),
              const SizedBox(height: 28),

              // Headline
              Text(
                'Sign in to your account',
                style: GoogleFonts.outfit(
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  color: Colors.black,
                  height: 1.2,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 10),

              // Subtitle
              Text(
                'Access your bookings, manage your\naddresses, wallet and more.',
                style: GoogleFonts.outfit(
                  fontSize: 14,
                  color: Colors.grey[500],
                  height: 1.5,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 36),

              // Sign In button
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: () async {
                    await context.push('/client/login');
                    // Re-check auth after returning from login
                    _fetchProfile();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryColor,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: Text(
                    'Sign In',
                    style: GoogleFonts.outfit(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),

            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // ── Not logged in: show a premium login gate ─────────────────────
    if (!_isLoggedIn) return _buildLoginGate();

    if (_isLoading) {
      return Scaffold(
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
                  onTap: _logout,
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
              border: Border.all(
                color: AppTheme.primaryColor.withValues(alpha: 0.2),
                width: 2,
              ),
            ),
            child: ClipOval(
              child: avatarUrl != null && avatarUrl.isNotEmpty
                  ? Image.network(
                      avatarUrl,
                      fit: BoxFit.cover,
                      width: 70,
                      height: 70,
                      errorBuilder: (_, __, ___) => Container(
                        color: Colors.grey.shade100,
                        child: Icon(Icons.person, size: 38, color: Colors.grey.shade400),
                      ),
                    )
                  : Container(
                      color: Colors.grey.shade100,
                      child: Icon(Icons.person, size: 38, color: Colors.grey.shade400),
                    ),
            ),
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
              child: Icon(
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
