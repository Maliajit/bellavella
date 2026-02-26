import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/client_bottom_nav.dart';

class ClientProfileScreen extends StatelessWidget {
  const ClientProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
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
                  onTap: () => context.push('/client/profile/manage-address'),
                ),
                _ProfileOption(
                  icon: Icons.account_balance_wallet_outlined,
                  title: 'My Wallet',
                  onTap: () => context.push('/client/wallet'),
                ),
                _ProfileOption(
                  icon: Icons.share_outlined,
                  title: 'Refer & Earn',
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
      bottomNavigationBar: const ClientBottomNav(currentIndex: 3),
    );
  }

  Widget _buildProfileHeader(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
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
              border: Border.all(color: AppTheme.primaryColor.withOpacity(0.1), width: 2),
              image: const DecorationImage(
                image: NetworkImage(
                  'https://images.unsplash.com/photo-1539571696357-5a69c17a67c6?q=80&w=200',
                ),
                fit: BoxFit.cover,
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Harshvardhan',
                  style: GoogleFonts.outfit(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '+91 9876543210',
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
            onTap: () => context.push('/client/profile/edit-profile'),
            child: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppTheme.primaryColor.withOpacity(0.08),
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

  Widget _buildProfileSection({required String title, required List<_ProfileOption> options}) {
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
                color: Colors.black.withOpacity(0.02),
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
                    contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
                    leading: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: (option.color ?? Colors.grey.shade600).withOpacity(0.08),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(option.icon, color: option.color ?? Colors.grey.shade700, size: 22),
                    ),
                    title: Text(
                      option.title,
                      style: GoogleFonts.outfit(
                        color: option.color ?? Colors.black87,
                        fontSize: 15,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    trailing: const Icon(Icons.arrow_forward_ios_rounded, color: Colors.grey, size: 14),
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
  final VoidCallback onTap;
  final Color? color;

  _ProfileOption({
    required this.icon,
    required this.title,
    required this.onTap,
    this.color,
  });
}
