import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/professional_bottom_nav.dart';

class ProfessionalProfileScreen extends StatefulWidget {
  const ProfessionalProfileScreen({super.key});

  @override
  State<ProfessionalProfileScreen> createState() => _ProfessionalProfileScreenState();
}

class _ProfessionalProfileScreenState extends State<ProfessionalProfileScreen> {
  final ScrollController _scrollController = ScrollController();
  bool _isScrolled = false;

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
                      const Text(
                        'Profile Info',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 20),
                      _buildInfoCard(Icons.person_outline, 'Name', 'Kevin Shah'),
                      const SizedBox(height: 12),
                      _buildInfoCard(Icons.work_outline, 'Skills', 'Full Body Waxing, Gold Glow Facial'),
                      const SizedBox(height: 12),
                      _buildInfoCard(Icons.phone_outlined, 'Phone', '+91 98765 43210'),
                      const SizedBox(height: 12),
                      _buildInfoCard(Icons.location_on_outlined, 'Address', 'Baner, Pune, Maharashtra'),
                      const SizedBox(height: 12),
                      _buildInfoCard(
                        Icons.inventory_2_outlined, 
                        'Inventory & Kits', 
                        '3 Kits Owned',
                        onTap: () => context.push('/professional/kit-store'),
                      ),
                      const SizedBox(height: 30),
                       _buildEditButton(),
                       const SizedBox(height: 12),
                       _buildLogoutOption(),
                       const SizedBox(height: 100),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: const ProfessionalBottomNav(currentIndex: 3),
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
            'Profile & Settings',
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

  Widget _buildInfoCard(IconData icon, String label, String value, {VoidCallback? onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.grey.shade50,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: onTap != null ? AppTheme.primaryColor.withOpacity(0.1) : Colors.transparent),
        ),
        child: Row(
          children: [
            Icon(icon, color: onTap != null ? AppTheme.primaryColor : Colors.grey.shade400, size: 28),
            const SizedBox(width: 20),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: TextStyle(color: Colors.grey.shade400, fontSize: 13),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    value,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                ],
              ),
            ),
            if (onTap != null)
              const Icon(Icons.chevron_right, color: AppTheme.primaryColor),
          ],
        ),
      ),
    );
  }

  Widget _buildEditButton() {
    return GestureDetector(
      onTap: () => context.go('/professional/edit-profile'),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 20),
        decoration: BoxDecoration(
          color: Colors.pink.shade400,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.pink.withOpacity(0.2),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.edit_outlined, color: Colors.white),
            SizedBox(width: 10),
            Text(
              'Edit Profile',
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLogoutOption() {
    return ListTile(
      onTap: () => context.go('/professional/login'),
      contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
      leading: Icon(Icons.logout_rounded, color: Colors.red.shade400, size: 26),
      title: Text(
        'Logout',
        style: TextStyle(
          color: Colors.red.shade400,
          fontSize: 16,
          fontWeight: FontWeight.w500,
        ),
      ),
      trailing: const Icon(Icons.chevron_right, color: Colors.grey, size: 24),
    );
  }
}
