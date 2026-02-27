import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../router/route_names.dart';
import '../widgets/professional_scaffold.dart';
import '../../features/client/splash/splash_screen.dart';
import '../../features/professional/auth/professional_login_screen.dart';
import '../../features/professional/auth/otp_verify_screen.dart';
import '../../features/professional/auth/professional_signup_screen.dart';
import '../../features/professional/auth/verification_status_screen.dart';
import '../../features/professional/bookings/professional_order_list_screen.dart';
import '../../features/professional/dashboard/professional_dashboard_screen.dart';
import '../../features/professional/earnings/professional_earnings_screen.dart';
import '../../features/professional/profile/professional_profile_screen.dart';
import '../../features/professional/earnings/professional_jobs_screen.dart';
import '../../features/professional/earnings/professional_wallet_screen.dart';
import '../../features/professional/earnings/professional_schedule_screen.dart';
import '../../features/professional/profile/professional_edit_profile_screen.dart';
import '../../features/professional/bookings/professional_booking_requests_screen.dart';
import '../../features/professional/bookings/professional_booking_detail_screen.dart';
import '../../features/professional/earnings/professional_availability_screen.dart';
import '../../features/professional/notifications/incoming_request_screen.dart';
import '../../features/professional/orders/professional_kit_store_screen.dart';

final professionalRouter = GoRouter(
  initialLocation: AppRoutes.root,
  routes: [
    ..._rootRoutes,
    ..._authRoutes,
    ShellRoute(
      builder: (context, state, child) => ProfessionalScaffold(child: child),
      routes: _shellRoutes,
    ),
    ..._proOtherRoutes,
  ],
);

final _rootRoutes = [
  GoRoute(
    path: AppRoutes.root,
    name: AppRoutes.rootName,
    builder: (context, state) => const SplashScreen(),
  ),
];

final _authRoutes = [
  GoRoute(
    path: AppRoutes.proLogin,
    name: AppRoutes.proLoginName,
    builder: (context, state) => const ProfessionalLoginScreen(),
  ),
  GoRoute(
    path: AppRoutes.proVerifyOtp,
    name: AppRoutes.proVerifyOtpName,
    builder: (context, state) {
      final String? phoneNumber = state.extra as String?;
      if (phoneNumber == null) return const ProfessionalLoginScreen();
      return OTPVerifyScreen(phoneNumber: phoneNumber);
    },
  ),
  GoRoute(
    path: AppRoutes.proSignup,
    name: AppRoutes.proSignupName,
    builder: (context, state) => const ProfessionalSignupScreen(),
  ),
  GoRoute(
    path: AppRoutes.proVerificationStatus,
    name: AppRoutes.proVerificationStatusName,
    builder: (context, state) => VerificationStatusScreen(
      applicantName: state.extra as String?,
    ),
  ),
];

final _shellRoutes = [
  GoRoute(
    path: AppRoutes.proDashboard,
    name: AppRoutes.proDashboardName,
    builder: (context, state) => const ProfessionalDashboardScreen(),
  ),
  GoRoute(
    path: AppRoutes.proOrders,
    name: AppRoutes.proOrdersName,
    builder: (context, state) => const ProfessionalOrderListScreen(),
  ),
  GoRoute(
    path: AppRoutes.proEarnings,
    name: AppRoutes.proEarningsName,
    builder: (context, state) => const ProfessionalEarningsScreen(),
  ),
  GoRoute(
    path: AppRoutes.proProfile,
    name: AppRoutes.proProfileName,
    builder: (context, state) => const ProfessionalProfileScreen(),
  ),
];

final _proOtherRoutes = [
  GoRoute(
    path: AppRoutes.proJobs,
    name: AppRoutes.proJobsName,
    builder: (context, state) => const ProfessionalJobsScreen(),
  ),
  GoRoute(
    path: AppRoutes.proWallet,
    name: AppRoutes.proWalletName,
    builder: (context, state) => const ProfessionalWalletScreen(),
  ),
  GoRoute(
    path: AppRoutes.proSchedule,
    name: AppRoutes.proScheduleName,
    builder: (context, state) => const ProfessionalScheduleScreen(),
  ),
  GoRoute(
    path: AppRoutes.proEditProfile,
    name: AppRoutes.proEditProfileName,
    builder: (context, state) => const ProfessionalEditProfileScreen(),
  ),
  GoRoute(
    path: AppRoutes.proRequests,
    name: AppRoutes.proRequestsName,
    builder: (context, state) => const ProfessionalBookingRequestsScreen(),
  ),
  GoRoute(
    path: AppRoutes.proBookingDetail,
    name: AppRoutes.proBookingDetailName,
    builder: (context, state) => ProfessionalBookingDetailScreen(
      bookingId: state.pathParameters['id'] ?? '',
    ),
  ),
  GoRoute(
    path: AppRoutes.proAvailability,
    name: AppRoutes.proAvailabilityName,
    builder: (context, state) => const ProfessionalAvailabilityScreen(),
  ),
  GoRoute(
    path: AppRoutes.proIncomingRequest,
    name: AppRoutes.proIncomingRequestName,
    builder: (context, state) => const IncomingRequestScreen(),
  ),
  GoRoute(
    path: AppRoutes.proKitStore,
    name: AppRoutes.proKitStoreName,
    builder: (context, state) => const ProfessionalKitStoreScreen(),
  ),
];
