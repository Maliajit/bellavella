import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:bellavella/core/routes/app_routes.dart';

class ProfessionalBottomNav extends StatelessWidget {
  final int currentIndex;

  const ProfessionalBottomNav({
    super.key,
    required this.currentIndex,
  });

  static const _items = [
    _NavItem(
      icon: Icons.grid_view_rounded,
      activeIcon: Icons.grid_view_rounded,
      label: 'Dashboard',
      route: '/professional/dashboard',
    ),
    _NavItem(
      icon: Icons.receipt_long_outlined,
      activeIcon: Icons.receipt_long_rounded,
      label: 'Orders',
      route: '/professional/orders',
    ),
    _NavItem(
      icon: Icons.storefront_outlined,
      activeIcon: Icons.storefront_rounded,
      label: 'Kit',
      route: '/professional/kit-store',
    ),
    _NavItem(
      icon: Icons.payments_outlined,
      activeIcon: Icons.payments_rounded,
      label: 'Wallet',
      route: '/professional/wallet',
    ),
    _NavItem(
      icon: Icons.badge_outlined,
      activeIcon: Icons.badge_rounded,
      label: 'Profile',
      route: '/professional/profile',
    ),
  ];

  static const _activeColor = Color(0xFFFF2D6F);
  static const _inactiveColor = Color(0xFFB0B8C9);

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 76,
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Colors.grey.shade100, width: 1)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 16,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: Row(
        children: List.generate(_items.length, (index) {
          final item = _items[index];
          final isActive = currentIndex == index;
          return Expanded(
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () {
                  if (isActive) return;
                  HapticFeedback.selectionClick();
                  context.go(item.route);
                },
                splashColor: _activeColor.withOpacity(0.08),
                highlightColor: Colors.transparent,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 200),
                      child: Icon(
                        isActive ? item.activeIcon : item.icon,
                        key: ValueKey(isActive),
                        color: isActive ? _activeColor : _inactiveColor,
                        size: isActive ? 26 : 24,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      item.label,
                      style: TextStyle(
                        color: isActive ? _activeColor : _inactiveColor,
                        fontSize: 10.5,
                        fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
                        letterSpacing: isActive ? 0.2 : 0,
                      ),
                    ),
                    const SizedBox(height: 2),
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 250),
                      width: isActive ? 20 : 0,
                      height: 3,
                      decoration: BoxDecoration(
                        color: _activeColor,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }),
      ),
    );
  }
}

class _NavItem {
  final IconData icon;
  final IconData activeIcon;
  final String label;
  final String route;

  const _NavItem({
    required this.icon,
    required this.activeIcon,
    required this.label,
    required this.route,
  });
}
