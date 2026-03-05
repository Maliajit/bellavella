import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/router/route_names.dart';
import '../services/professional_api_service.dart';
import 'package:bellavella/core/models/data_models.dart';

class ProfessionalProfileScreen extends StatefulWidget {
  const ProfessionalProfileScreen({super.key});

  @override
  State<ProfessionalProfileScreen> createState() => _ProfessionalProfileScreenState();
}

class _ProfessionalProfileScreenState extends State<ProfessionalProfileScreen> {
  Professional? _profile;
  bool _isLoading = true;
  String? _errorMessage;
  final ScrollController _scrollController = ScrollController();
  bool _isScrolled = false;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    _fetchProfile();
  }

  Future<void> _fetchProfile() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      final profile = await ProfessionalApiService.getProfile();
      if (mounted) {
        setState(() {
          _profile = profile;
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
    if (_scrollController.hasClients && _scrollController.offset > 10 && !_isScrolled) {
      setState(() => _isScrolled = true);
    } else if (_scrollController.hasClients && _scrollController.offset <= 10 && _isScrolled) {
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
                onPressed: _fetchProfile,
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: _buildAppBar(),
      body: RefreshIndicator(
        onRefresh: _fetchProfile,
        color: AppTheme.primaryColor,
        child: SingleChildScrollView(
          controller: _scrollController,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
          physics: const AlwaysScrollableScrollPhysics(),
          child: Column(
            children: [
              _buildProfileHeader(),
              const SizedBox(height: 32),
              // ... rest of the column content
            const SizedBox(height: 40),
            _buildSectionTitle("Personal Details"),
            const SizedBox(height: 8),
            _buildListOption(
              Icons.person_outline_rounded, 
              "Personal Information",
              onTap: () => context.pushNamed(AppRoutes.proEditProfileName),
            ),
            _buildListOption(
              Icons.near_me_outlined, 
              "Service Area",
              onTap: () => context.pushNamed(AppRoutes.proEditProfileName),
            ),
            _buildListOption(
              Icons.access_time_rounded, 
              "Working Hours",
              onTap: () => context.pushNamed(AppRoutes.proAvailabilityName),
            ),
            _buildListOption(
              Icons.call_outlined, 
              "Contact Details",
              onTap: () => context.pushNamed(AppRoutes.proEditProfileName),
            ),

            const SizedBox(height: 32),
            _buildSectionTitle("Verification"),
            const SizedBox(height: 8),
            _buildListOption(
              Icons.badge_outlined, 
              "ID Verification", 
              isVerified: true,
              onTap: () => context.pushNamed(AppRoutes.proVerificationStatusName),
            ),
            _buildListOption(
              Icons.description_outlined, 
              "Address Proof", 
              isVerified: true,
              onTap: () => context.pushNamed(AppRoutes.proVerificationStatusName),
            ),
            _buildListOption(
              Icons.school_outlined, 
              "Professional Certificate", 
              isVerified: false, 
              value: "Uploaded",
              onTap: () => context.pushNamed(AppRoutes.proVerificationStatusName),
            ),

            const SizedBox(height: 32),
            _buildSectionTitle("Payout Details"),
            const SizedBox(height: 8),
            _buildListOption(
              Icons.account_balance_outlined, 
              "Bank Account",
              onTap: () => context.pushNamed(AppRoutes.proEarningsName),
            ),
            _buildListOption(
              Icons.payments_outlined, 
              "UPI ID",
              onTap: () => context.pushNamed(AppRoutes.proEarningsName),
            ),
            _buildListOption(
              Icons.history_rounded, 
              "Transaction History",
              onTap: () => context.pushNamed(AppRoutes.proEarningsName),
            ),
            _buildListOption(
              Icons.account_balance_wallet_outlined, 
              "Withdrawal Settings",
              onTap: () => context.pushNamed(AppRoutes.proEarningsName),
            ),

            const SizedBox(height: 32),
            _buildSectionTitle("Settings"),
            const SizedBox(height: 8),
            _buildListOption(Icons.notifications_none_rounded, "Notification Settings"),
            _buildListOption(Icons.lock_outline_rounded, "Change Password"),
            _buildListOption(Icons.language_rounded, "App Language", value: "English"),
            _buildListOption(Icons.help_outline_rounded, "Support / Help"),
            _buildListOption(
              Icons.logout_rounded, 
              "Logout", 
              isDestructive: true,
              onTap: () => _handleLogout(context),
            ),
            
            const SizedBox(height: 60),
          ],
        ),
      ),
    ),
  );
}

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: Colors.white,
      elevation: _isScrolled ? 0.5 : 0,
      centerTitle: true,
      title: Text(
        "Profile",
        style: GoogleFonts.inter(
          fontSize: 16,
          fontWeight: FontWeight.w700,
          color: Colors.black87,
        ),
      ),
      actions: [
        IconButton(
          onPressed: () {},
          icon: const Icon(Icons.settings_outlined, color: Colors.black87),
        ),
      ],
    );
  }

  Widget _buildProfileHeader() {
    return Column(
      children: [
        Stack(
          alignment: Alignment.bottomRight,
          children: [
            Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: AppTheme.primaryColor.withValues(alpha: 0.2), width: 2),
              ),
              child: const CircleAvatar(
                radius: 50,
                backgroundColor: Color(0xFFF3F4F6),
                child: Icon(Icons.person_rounded, size: 50, color: Colors.grey),
              ),
            ),
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: AppTheme.primaryColor,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 2),
              ),
              child: const Icon(Icons.camera_alt_rounded, size: 14, color: Colors.white),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Text(
          _profile?.name ?? 'Professional',
          style: GoogleFonts.inter(
            fontSize: 22,
            fontWeight: FontWeight.w900,
            color: Colors.black,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          (_profile?.services != null && _profile!.services.isNotEmpty) 
              ? _profile!.services.first.name 
              : (_profile?.verification ?? 'Service Provider'),
          style: GoogleFonts.inter(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: Colors.grey.shade600,
          ),
        ),
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.star_rounded, size: 18, color: Color(0xFFFFB800)),
            const SizedBox(width: 4),
            Text(
              "${_profile?.rating ?? 0.0} (${_profile?.verification ?? 'Pending'})",
              style: GoogleFonts.inter(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: Colors.black87,
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (_profile?.experience != null)
              Padding(
                padding: const EdgeInsets.only(right: 12),
                child: _badge("Exp: ${_profile!.experience}"),
              ),
            if (_profile?.joined != null)
              _badge("Joined: ${_profile!.joined!.split('T').first}"),
            if (_profile?.experience == null && _profile?.joined == null)
              _badge("Service Provider"),
          ],
        ),
      ],
    );
  }

  Widget _badge(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(100),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Text(
        text,
        style: GoogleFonts.inter(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: Colors.grey.shade600,
        ),
      ),
    );
  }


  Widget _buildSectionTitle(String title) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Padding(
        padding: const EdgeInsets.only(left: 4, bottom: 4),
        child: Text(
          title.toUpperCase(),
          style: GoogleFonts.inter(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            color: Colors.grey.shade500,
            letterSpacing: 1,
          ),
        ),
      ),
    );
  }


  Widget _buildListOption(IconData icon, String label, {String? value, bool isVerified = false, bool isDestructive = false, VoidCallback? onTap}) {
    return ListTile(
      onTap: onTap ?? () {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("$label feature coming soon!")),
        );
      },
      dense: true,
      contentPadding: EdgeInsets.zero,
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: isDestructive ? Colors.red.shade50 : Colors.grey.shade50,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, size: 20, color: isDestructive ? Colors.red.shade600 : Colors.black87),
      ),
      title: Text(
        label,
        style: GoogleFonts.inter(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: isDestructive ? Colors.red.shade600 : Colors.black87,
        ),
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (isVerified)
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: Icon(Icons.check_circle_rounded, size: 16, color: Colors.green.shade600),
            ),
          if (value != null)
            Text(
              value,
              style: GoogleFonts.inter(
                fontSize: 12,
                color: isVerified ? Colors.green.shade600 : Colors.grey.shade500,
                fontWeight: FontWeight.w600,
              ),
            ),
          const SizedBox(width: 4),
          Icon(Icons.chevron_right_rounded, size: 20, color: Colors.grey.shade400),
        ],
      ),
    );
  }

  void _handleLogout(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Logout"),
        content: const Text("Are you sure you want to logout?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          TextButton(
            onPressed: () {
              // In a real app, clear tokens here
              context.go(AppRoutes.proLogin);
            },
            child: const Text("Logout", style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}
