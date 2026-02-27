import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../router/route_names.dart';
import '../widgets/main_scaffold.dart';
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
import '../../features/client/services/client_category_screen.dart';
import '../../features/client/services/category_detail_screen.dart';
import '../../features/client/cart/cart_screen.dart';
import '../../features/client/cart/client_checkout_review_screen.dart';
import '../../features/client/services/service_review_screen.dart';
import '../../features/client/booking/live_tracking_screen.dart';
import '../../features/client/services/client_service_types_screen.dart';
import '../../features/client/profile/client_wallet_screen.dart';

final clientRouter = GoRouter(
  initialLocation: AppRoutes.root,
  routes: [
    ..._rootRoutes,
    ..._authRoutes,
    ShellRoute(
      builder: (context, state, child) => MainScaffold(child: child),
      routes: _shellRoutes,
    ),
    ..._featureRoutes,
  ],
);

final _rootRoutes = [
  GoRoute(
    path: AppRoutes.root,
    name: AppRoutes.rootName,
    builder: (context, state) => const SplashScreen(),
  ),
  GoRoute(
    path: AppRoutes.onboarding,
    name: AppRoutes.onboardingName,
    builder: (context, state) => const OnboardingScreen(),
  ),
];

final _authRoutes = [
  GoRoute(
    path: AppRoutes.clientLogin,
    name: AppRoutes.clientLoginName,
    builder: (context, state) => const ClientLoginScreen(),
  ),
  GoRoute(
    path: AppRoutes.clientVerifyOtp,
    name: AppRoutes.clientVerifyOtpName,
    builder: (context, state) {
      final String? phoneNumber = state.extra as String?;
      if (phoneNumber == null) return const ClientLoginScreen();
      return ClientOTPVerifyScreen(phoneNumber: phoneNumber);
    },
  ),
  GoRoute(
    path: AppRoutes.clientLocationPicker,
    name: AppRoutes.clientLocationPickerName,
    builder: (context, state) => const ClientLocationPickerScreen(),
  ),
];

final _shellRoutes = [
  GoRoute(
    path: AppRoutes.clientHome,
    name: AppRoutes.clientHomeName,
    builder: (context, state) => const ClientHomeScreen(),
  ),
  GoRoute(
    path: AppRoutes.clientCategory,
    name: AppRoutes.clientCategoryName,
    builder: (context, state) => ClientCategoryScreen(
      categoryName: state.pathParameters['category'] ?? 'Category',
    ),
  ),
  GoRoute(
    path: AppRoutes.clientMyBookings,
    name: AppRoutes.clientMyBookingsName,
    builder: (context, state) => const MyBookingsScreen(),
  ),
  GoRoute(
    path: AppRoutes.clientProfile,
    name: AppRoutes.clientProfileName,
    builder: (context, state) => const ClientProfileScreen(),
  ),
];

final _featureRoutes = [
  GoRoute(
    path: AppRoutes.clientCategoryDetail,
    name: AppRoutes.clientCategoryDetailName,
    builder: (context, state) => CategoryDetailScreen(
      categoryName: state.pathParameters['name'] ?? 'Detail',
    ),
  ),
  GoRoute(
    path: AppRoutes.clientServiceTypes,
    name: AppRoutes.clientServiceTypesName,
    builder: (context, state) => ClientServiceTypesScreen(
      category: state.pathParameters['category'] ?? 'General',
    ),
  ),
  GoRoute(
    path: AppRoutes.clientServiceDetail,
    name: AppRoutes.clientServiceDetailName,
    builder: (context, state) => ServiceDetailScreen(
      serviceId: state.pathParameters['id'] ?? '',
    ),
  ),
  GoRoute(
    path: AppRoutes.clientCart,
    name: AppRoutes.clientCartName,
    builder: (context, state) => const CartScreen(),
  ),
  GoRoute(
    path: AppRoutes.clientBooking,
    name: AppRoutes.clientBookingName,
    builder: (context, state) => const BookingScreen(),
  ),
  GoRoute(
    path: AppRoutes.clientBookingStatus,
    name: AppRoutes.clientBookingStatusName,
    builder: (context, state) => const BookingStatusScreen(),
  ),
  GoRoute(
    path: AppRoutes.clientLiveTracking,
    name: AppRoutes.clientLiveTrackingName,
    builder: (context, state) => LiveTrackingScreen(
      bookingId: state.pathParameters['bookingId'] ?? '',
    ),
  ),
  GoRoute(
    path: AppRoutes.clientServiceReview,
    name: AppRoutes.clientServiceReviewName,
    builder: (context, state) => ServiceReviewScreen(
      bookingId: state.pathParameters['bookingId'] ?? '',
    ),
  ),
  GoRoute(
    path: AppRoutes.clientManageAddress,
    name: AppRoutes.clientManageAddressName,
    builder: (context, state) => const ManageAddressScreen(),
  ),
  GoRoute(
    path: AppRoutes.clientUpdateAddress,
    name: AppRoutes.clientUpdateAddressName,
    builder: (context, state) => const UpdateAddressScreen(),
  ),
  GoRoute(
    path: AppRoutes.clientReferEarn,
    name: AppRoutes.clientReferEarnName,
    builder: (context, state) => const ReferEarnScreen(),
  ),
  GoRoute(
    path: AppRoutes.clientRateUs,
    name: AppRoutes.clientRateUsName,
    builder: (context, state) => const RateUsScreen(),
  ),
  GoRoute(
    path: AppRoutes.clientAboutUs,
    name: AppRoutes.clientAboutUsName,
    builder: (context, state) => const AboutUsScreen(),
  ),
  GoRoute(
    path: AppRoutes.clientEditProfile,
    name: AppRoutes.clientEditProfileName,
    builder: (context, state) => const EditProfileScreen(),
  ),
  GoRoute(
    path: AppRoutes.clientWallet,
    name: AppRoutes.clientWalletName,
    builder: (context, state) => const ClientWalletScreen(),
  ),
  GoRoute(
    path: AppRoutes.clientCheckoutReview,
    name: AppRoutes.clientCheckoutReviewName,
    builder: (context, state) {
      final data = state.extra as Map<String, dynamic>?;
      if (data == null) return const CartScreen();
      return ClientCheckoutReviewScreen(checkoutData: data);
    },
  ),
];
