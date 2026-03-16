import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../widgets/professional_bottom_nav.dart';
import '../../features/professional/services/professional_realtime_service.dart';
import '../../features/professional/controllers/professional_profile_controller.dart';

class ProfessionalScaffold extends StatefulWidget {
  final Widget child;

  const ProfessionalScaffold({
    super.key,
    required this.child,
  });

  @override
  State<ProfessionalScaffold> createState() => _ProfessionalScaffoldState();
}

class _ProfessionalScaffoldState extends State<ProfessionalScaffold> {
  @override
  void initState() {
    super.initState();
    // Start listening as soon as we have a profile, and also listen for changes
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initRealtimeListeners();
      context.read<ProfessionalProfileController>().addListener(_onProfileChange);
    });
  }

  void _onProfileChange() {
    _initRealtimeListeners();
  }

  void _initRealtimeListeners() {
    if (!mounted) return;
    final profile = context.read<ProfessionalProfileController>().profile;
    if (profile != null) {
      ProfessionalRealtimeService.startAllListeners(profile.id);
    }
  }

  @override
  void dispose() {
    // Correctly remove listener to avoid memory leaks
    if (mounted) {
      context.read<ProfessionalProfileController>().removeListener(_onProfileChange);
    }
    ProfessionalRealtimeService.stopAllListeners();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: widget.child,
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
