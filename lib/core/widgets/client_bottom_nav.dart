import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class ClientBottomNav extends StatelessWidget {
  final int currentIndex;

  const ClientBottomNav({
    super.key,
    required this.currentIndex,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 70,
      decoration: BoxDecoration(
        color: Colors.white,
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
          _buildNavItem(context, Icons.home, 'Home', 0, '/client/home'),
          _buildNavItem(context, Icons.grid_view_rounded, 'Category', 1, '/client/services/Category'),
          _buildNavItem(context, Icons.receipt_long_outlined, 'Bookings', 2, '/client/my-bookings'),
          _buildNavItem(context, Icons.person_outline, 'Profile', 3, '/client/profile'),
        ],
      ),
    );
  }

  Widget _buildNavItem(BuildContext context, IconData icon, String label, int index, String route) {
    final bool isActive = currentIndex == index;
    return Expanded(
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            if (isActive) return;
            context.go(route);
          },
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon, 
                color: isActive ? Colors.pink : Colors.grey.shade400, 
                size: 28
              ),
              if (label.isNotEmpty) ...[
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
            ],
          ),
        ),
      ),
    );
  }
}
