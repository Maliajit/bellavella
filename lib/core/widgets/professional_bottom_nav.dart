import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../router/route_names.dart';

class ProfessionalBottomNav extends StatelessWidget {
  final int currentIndex;

  const ProfessionalBottomNav({
    super.key,
    required this.currentIndex,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 80,
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Colors.grey.shade100)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildNavItem(context, Icons.home_outlined, 'Home', 0),
          _buildNavItem(context, Icons.card_giftcard, 'Orders', 1),
          _buildNavItem(context, Icons.account_balance_wallet_outlined, 'Earnings', 2),
          _buildNavItem(context, Icons.person_outline, 'Profile', 3),
        ],
      ),
    );
  }

  Widget _buildNavItem(BuildContext context, IconData icon, String label, int index) {
    final bool isActive = currentIndex == index;
    return Expanded(
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            if (isActive) return;
            if (label == 'Home') context.go('/professional/dashboard');
            if (label == 'Orders') context.go('/professional/orders');
            if (label == 'Earnings') context.go('/professional/earnings');
            if (label == 'Profile') context.go('/professional/profile');
          },
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon, 
                color: isActive ? Colors.pink : Colors.grey.shade400, 
                size: 28
              ),
              const SizedBox(height: 4),
              Text(
                label,
                style: TextStyle(
                  color: isActive ? Colors.pink : Colors.grey.shade400,
                  fontSize: 12,
                  fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
