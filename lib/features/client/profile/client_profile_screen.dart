import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/client_bottom_nav.dart';

class ClientProfileScreen extends StatelessWidget {
  const ClientProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'Profile',
          style: TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.bold,
            fontSize: 22,
          ),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            const SizedBox(height: 10),
            _buildProfileHeader(context),
            const SizedBox(height: 20),
            const Divider(thickness: 1, height: 1),
            _buildProfileOption(
              icon: Icons.location_on_outlined,
              title: 'Manage Address',
              onTap: () => context.push('/client/profile/manage-address'),
            ),
            _buildProfileOption(
              icon: Icons.account_balance_wallet_outlined,
              title: 'My Wallet',
              onTap: () => context.push('/client/wallet'),
            ),
            _buildProfileOption(
              icon: Icons.share_outlined,
              title: 'Refer & Earn',
              onTap: () => context.push('/client/profile/refer-earn'),
            ),
            _buildProfileOption(
              icon: Icons.star_outline_rounded,
              title: 'Rate us',
              onTap: () => context.push('/client/profile/rate-us'),
            ),
            _buildProfileOption(
              icon: Icons.info_outline_rounded,
              title: 'About Us',
              onTap: () => context.push('/client/profile/about-us'),
            ),
            _buildProfileOption(
              icon: Icons.logout_rounded,
              title: 'Logout',
              color: Colors.red.shade400,
              onTap: () => context.go('/client/login'),
            ),
          ],
        ),
      ),
      bottomNavigationBar: const ClientBottomNav(currentIndex: 3),
    );
  }

  Widget _buildProfileHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.grey.shade200,
              image: const DecorationImage(
                image: NetworkImage(
                  'https://images.unsplash.com/photo-1539571696357-5a69c17a67c6?q=80&w=200',
                ),
                fit: BoxFit.cover,
              ),
            ),
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Guest User',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                Text(
                  '+91',
                  style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
                ),
              ],
            ),
          ),
          GestureDetector(
            onTap: () => context.push('/client/profile/edit-profile'),
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFFFFB6C1).withOpacity(0.5),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(
                Icons.edit_outlined,
                color: Colors.white,
                size: 24,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileOption({
    required IconData icon,
    required String title,
    Color? color,
    required VoidCallback onTap,
  }) {
    return ListTile(
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
      leading: Icon(icon, color: color ?? Colors.black87, size: 26),
      title: Text(
        title,
        style: TextStyle(
          color: color ?? Colors.black87,
          fontSize: 16,
          fontWeight: FontWeight.w500,
        ),
      ),
      trailing: const Icon(Icons.chevron_right, color: Colors.grey, size: 24),
    );
  }
}
