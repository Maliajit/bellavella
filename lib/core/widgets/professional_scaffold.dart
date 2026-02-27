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
    if (location.startsWith('/professional/orders')) return 1;
    if (location.startsWith('/professional/earnings')) return 2;
    if (location.startsWith('/professional/profile')) return 3;
    return 0;
  }
}
