import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../widgets/professional_bottom_nav.dart';

class ProfessionalScaffold extends StatelessWidget {
  final Widget child;

  const ProfessionalScaffold({
    super.key,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: child,
      bottomNavigationBar: ProfessionalBottomNav(
        currentIndex: _calculateSelectedIndex(context),
      ),
    );
  }

  int _calculateSelectedIndex(BuildContext context) {
    final String location = GoRouterState.of(context).uri.path;
    if (location.startsWith('/professional/dashboard')) return 0;
    if (location.startsWith('/professional/notifications')) return 0;
    if (location.startsWith('/professional/availability')) return 0;
    if (location.startsWith('/professional/orders')) return 1;
    if (location.startsWith('/professional/jobs')) return 1;
    if (location.startsWith('/professional/requests')) return 1;
    if (location.startsWith('/professional/schedule')) return 3;
    if (location.startsWith('/professional/kit-store')) return 2;
    if (location.startsWith('/professional/wallet')) return 3;
    if (location.startsWith('/professional/transactions')) return 3;
    if (location.startsWith('/professional/profile')) return 4;
    if (location.startsWith('/professional/edit-profile')) return 4;
    if (location.startsWith('/professional/refer-earn')) return 4;
    return 0;
  }
}
