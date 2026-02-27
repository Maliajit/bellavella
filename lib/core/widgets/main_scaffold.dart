import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../router/route_names.dart';

class MainScaffold extends StatelessWidget {
  final Widget child;

  const MainScaffold({
    super.key,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: child,
      bottomNavigationBar: _BottomNav(
        currentIndex: _calculateSelectedIndex(context),
      ),
    );
  }

  int _calculateSelectedIndex(BuildContext context) {
    final String location = GoRouterState.of(context).uri.path;
    if (location.startsWith('/client/home')) return 0;
    if (location.startsWith('/client/services')) return 1;
    if (location.startsWith('/client/my-bookings')) return 2;
    if (location.startsWith('/client/profile')) return 3;
    return 0;
  }
}

class _BottomNav extends StatelessWidget {
  final int currentIndex;

  const _BottomNav({required this.currentIndex});

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
          _buildNavItem(context, Icons.home, 'Home', 0, AppRoutes.clientHomeName),
          _buildNavItem(context, Icons.grid_view_rounded, 'Category', 1, AppRoutes.clientCategoryName, params: {'category': 'Category'}),
          _buildNavItem(context, Icons.receipt_long_outlined, 'Bookings', 2, AppRoutes.clientMyBookingsName),
          _buildNavItem(context, Icons.person_outline, 'Profile', 3, AppRoutes.clientProfileName),
        ],
      ),
    );
  }

  Widget _buildNavItem(BuildContext context, IconData icon, String label, int index, String routeName, {Map<String, String>? params}) {
    final bool isActive = currentIndex == index;
    return Expanded(
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            if (isActive) return;
            if (params != null) {
              context.goNamed(routeName, pathParameters: params);
            } else {
              context.goNamed(routeName);
            }
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
