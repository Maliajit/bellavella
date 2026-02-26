import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../config/app_config.dart';
import '../../features/client/splash/splash_screen.dart';
import '../../features/client/auth/client_login_screen.dart';
import '../../features/client/auth/onboarding_screen.dart';
import '../../features/client/auth/client_otp_verify_screen.dart';
import '../../features/client/auth/client_location_picker_screen.dart';
import '../../features/client/home/client_home_screen.dart';
import '../../features/client/services/service_detail_screen.dart';
import '../../features/client/booking/booking_screen.dart';
import '../../features/client/booking/booking_status_screen.dart';
import '../../features/client/booking/my_bookings_screen.dart';
import '../../features/client/profile/client_profile_screen.dart';
import '../../features/client/profile/edit_profile_screen.dart';
import '../../features/client/profile/manage_address_screen.dart';
import '../../features/client/profile/update_address_screen.dart';
import '../../features/client/profile/refer_earn_screen.dart';
import '../../features/client/profile/rate_us_screen.dart';
import '../../features/client/profile/about_us_screen.dart';
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
import '../../features/client/services/client_category_screen.dart';
import '../../features/client/services/category_detail_screen.dart';
import '../../features/client/cart/cart_screen.dart';
import '../../features/client/cart/client_checkout_review_screen.dart';
import '../../features/client/services/service_review_screen.dart';
import '../../features/client/booking/live_tracking_screen.dart';
import '../../features/professional/notifications/incoming_request_screen.dart';
import '../../features/client/services/client_service_types_screen.dart';
import '../../features/client/profile/client_wallet_screen.dart';
import '../../features/professional/orders/professional_kit_store_screen.dart';

// Dummy screens for initial setup
class PlaceholderScreen extends StatelessWidget {
  final String title;
  const PlaceholderScreen(this.title, {super.key});
  @override
  Widget build(BuildContext context) => Scaffold(body: Center(child: Text(title)));
}

final AppRouter = GoRouter(
  initialLocation: '/',
  redirect: (context, state) {
    final location = state.uri.path;
    
    // Safety check: prevent Professional flavor from accessing Client routes
    if (AppConfig.isProfessional && location.startsWith('/client')) {
      return '/professional/dashboard';
    }
    
    // Safety check: prevent Client flavor from accessing Professional routes
    if (AppConfig.isClient && location.startsWith('/professional')) {
      return '/client/home';
    }
    
    return null;
  },
  routes: [
    GoRoute(
      path: '/',
      builder: (context, state) => const SplashScreen(),
    ),
    GoRoute(
      path: '/onboarding',
      builder: (context, state) => const OnboardingScreen(),
    ),
    // Client Routes
    GoRoute(
      path: '/client/login',
      builder: (context, state) => const ClientLoginScreen(),
    ),
    GoRoute(
      path: '/client/verify-otp',
      builder: (context, state) =>
          ClientOTPVerifyScreen(phoneNumber: state.extra as String),
    ),
    GoRoute(
      path: '/client/location-picker',
      builder: (context, state) => const ClientLocationPickerScreen(),
    ),
    GoRoute(
      path: '/client/home',
      builder: (context, state) => const ClientHomeScreen(),
    ),
    /* ... other client routes ... */
    GoRoute(
      path: '/client/services/:category',
      builder: (context, state) => ClientCategoryScreen(categoryName: state.pathParameters['category']!),
    ),
    GoRoute(
      path: '/client/category-detail/:name',
      builder: (context, state) => CategoryDetailScreen(categoryName: state.pathParameters['name']!),
    ),
    GoRoute(
      path: '/client/service-types/:category',
      builder: (context, state) => ClientServiceTypesScreen(category: state.pathParameters['category']!),
    ),
    GoRoute(
      path: '/client/service-detail/:id',
      builder: (context, state) => ServiceDetailScreen(serviceId: state.pathParameters['id']!),
    ),
    GoRoute(
      path: '/client/cart',
      builder: (context, state) => const CartScreen(),
    ),
    GoRoute(
      path: '/client/booking',
      builder: (context, state) => const BookingScreen(),
    ),
    GoRoute(
      path: '/client/booking-status',
      builder: (context, state) => const BookingStatusScreen(),
    ),
    GoRoute(
      path: '/client/live-tracking/:bookingId',
      builder: (context, state) => LiveTrackingScreen(bookingId: state.pathParameters['bookingId']!),
    ),
    GoRoute(
      path: '/client/my-bookings',
      builder: (context, state) => const MyBookingsScreen(),
    ),
    GoRoute(
      path: '/client/service-review/:bookingId',
      builder: (context, state) => ServiceReviewScreen(bookingId: state.pathParameters['bookingId']!),
    ),
    GoRoute(
      path: '/client/profile',
      builder: (context, state) => const ClientProfileScreen(),
    ),
    GoRoute(
      path: '/client/profile/manage-address',
      builder: (context, state) => const ManageAddressScreen(),
    ),
    GoRoute(
      path: '/client/profile/update-address',
      builder: (context, state) => const UpdateAddressScreen(),
    ),
    GoRoute(
      path: '/client/profile/refer-earn',
      builder: (context, state) => const ReferEarnScreen(),
    ),
    GoRoute(
      path: '/client/profile/rate-us',
      builder: (context, state) => const RateUsScreen(),
    ),
    GoRoute(
      path: '/client/profile/about-us',
      builder: (context, state) => const AboutUsScreen(),
    ),
    GoRoute(
      path: '/client/profile/edit-profile',
      builder: (context, state) => const EditProfileScreen(),
    ),
    GoRoute(
      path: '/client/wallet',
      builder: (context, state) => const ClientWalletScreen(),
    ),
    // Professional Routes
    GoRoute(
      path: '/professional/login',
      builder: (context, state) => const ProfessionalLoginScreen(),
    ),
    GoRoute(
      path: '/professional/verify-otp',
      builder: (context, state) => OTPVerifyScreen(phoneNumber: state.extra as String),
    ),
    GoRoute(
      path: '/professional/signup',
      builder: (context, state) => const ProfessionalSignupScreen(),
    ),
    GoRoute(
      path: '/professional/verification-status',
      builder: (context, state) => VerificationStatusScreen(applicantName: state.extra as String?),
    ),
    GoRoute(
      path: '/professional/dashboard',
      builder: (context, state) => const ProfessionalDashboardScreen(),
    ),
    GoRoute(
      path: '/professional/orders',
      builder: (context, state) => const ProfessionalOrderListScreen(),
    ),
    GoRoute(
      path: '/professional/earnings',
      builder: (context, state) => const ProfessionalEarningsScreen(),
    ),
    GoRoute(
      path: '/professional/profile',
      builder: (context, state) => const ProfessionalProfileScreen(),
    ),
    GoRoute(
      path: '/professional/jobs',
      builder: (context, state) => const ProfessionalJobsScreen(),
    ),
    GoRoute(
      path: '/professional/wallet',
      builder: (context, state) => const ProfessionalWalletScreen(),
    ),
    GoRoute(
      path: '/professional/schedule',
      builder: (context, state) => const ProfessionalScheduleScreen(),
    ),
    GoRoute(
      path: '/professional/edit-profile',
      builder: (context, state) => const ProfessionalEditProfileScreen(),
    ),
    GoRoute(
      path: '/professional/requests',
      builder: (context, state) => const ProfessionalBookingRequestsScreen(),
    ),
    GoRoute(
      path: '/professional/booking-detail/:id',
      builder: (context, state) => ProfessionalBookingDetailScreen(bookingId: state.pathParameters['id']!),
    ),
    GoRoute(
      path: '/professional/availability',
      builder: (context, state) => const ProfessionalAvailabilityScreen(),
    ),
    GoRoute(
      path: '/professional/incoming-request',
      builder: (context, state) => const IncomingRequestScreen(),
    ),
    GoRoute(
      path: '/professional/kit-store',
      builder: (context, state) => const ProfessionalKitStoreScreen(),
    ),
    GoRoute(
      path: '/client/checkout-review',
      builder: (context, state) => ClientCheckoutReviewScreen(checkoutData: state.extra as Map<String, dynamic>),
    ),
  ],
);
