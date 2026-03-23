import 'package:go_router/go_router.dart';
import '../routes/app_routes.dart';
import '../widgets/main_scaffold.dart';
import '../../features/client/splash/splash_screen.dart';
import '../../features/client/auth/client_login_screen.dart';
import '../../features/client/auth/onboarding_screen.dart';
import '../../features/client/auth/client_otp_verify_screen.dart';
import '../../features/client/auth/client_location_picker_screen.dart';
import '../../features/client/home/client_home_screen.dart';
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
import '../../features/client/cart/checkout_address_screen.dart';
import '../../features/client/cart/checkout_slot_screen.dart';
import '../../features/client/cart/client_checkout_review_screen.dart';
import '../../features/client/services/service_review_screen.dart';
import '../../features/client/booking/live_tracking_screen.dart';
import '../../features/client/services/client_service_types_screen.dart';
import '../../features/client/services/service_hierarchy_screen.dart';
import '../../features/client/profile/client_wallet_screen.dart';
import '../../features/client/auth/role_selection_screen.dart';
import '../../features/client/home/models/story_model.dart';
import '../../features/client/home/screens/story_viewer_screen.dart';
import '../../features/client/services/models/service_models.dart';

final clientRouter = GoRouter(
  initialLocation: AppRoutes.splash,
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
    path: AppRoutes.splash,
    name: AppRoutes.rootName,
    builder: (context, state) => const SplashScreen(),
  ),
  GoRoute(
    path: AppRoutes.roleSelection,
    name: AppRoutes.roleSelectionName,
    builder: (context, state) => const RoleSelectionScreen(),
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
      final extra = state.extra;

      if (extra is String) {
        return ClientOTPVerifyScreen(phoneNumber: extra);
      }

      if (extra is Map<String, dynamic>) {
        final phoneNumber = extra['phone'] as String?;
        if (phoneNumber == null) return const ClientLoginScreen();

        return ClientOTPVerifyScreen(
          phoneNumber: phoneNumber,
          autoFillOtp: extra['auto_fill_otp'] as String?,
        );
      }

      return const ClientLoginScreen();
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
    path: AppRoutes.clientServices,
    name: AppRoutes.clientServicesName,
    builder: (context, state) => const ClientCategoryScreen(),
  ),
  GoRoute(
    path: AppRoutes.clientCategory,
    name: AppRoutes.clientCategoryName,
    builder: (context, state) => ClientCategoryScreen(
      categorySlug: state.pathParameters['slug'],
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
  GoRoute(
    path: AppRoutes.clientManageAddress,
    name: AppRoutes.clientManageAddressName,
    builder: (context, state) => const ManageAddressScreen(),
  ),
  GoRoute(
    path: AppRoutes.clientUpdateAddress,
    name: AppRoutes.clientUpdateAddressName,
    builder: (context, state) => UpdateAddressScreen.fromExtra(state.extra),
  ),
  GoRoute(
    path: AppRoutes.clientReferEarn,
    name: AppRoutes.clientReferEarnName,
    builder: (context, state) => const ReferEarnScreen(),
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
];

final _featureRoutes = [
  GoRoute(
    path: AppRoutes.clientServiceHierarchy,
    name: AppRoutes.clientServiceHierarchyName,
    builder: (context, state) {
      final extra = state.extra as Map<String, dynamic>?;
      final seedNodeRaw = extra?['seedNode'] as Map<String, dynamic>?;
      final breadcrumbsRaw = extra?['breadcrumbs'] as List? ?? const [];

      return ServiceHierarchyScreen(
        nodeKey: state.pathParameters['nodeKey'] ?? '',
        seedNode: seedNodeRaw == null
            ? null
            : ServiceHierarchyNode.fromJson(seedNodeRaw),
        breadcrumbs: breadcrumbsRaw
            .whereType<Map>()
            .map(
              (item) => ServiceHierarchyNode.fromJson(
                Map<String, dynamic>.from(item),
              ),
            )
            .toList(),
      );
    },
  ),
  GoRoute(
    path: AppRoutes.clientCategoryDetail,
    name: AppRoutes.clientCategoryDetailName,
    builder: (context, state) {
      final extra = state.extra as Map<String, dynamic>?;
      final seedNodeRaw = extra?['seedNode'] as Map<String, dynamic>?;
      final breadcrumbsRaw = extra?['breadcrumbs'] as List? ?? const [];

      return CategoryDetailScreen(
        categoryName: state.pathParameters['name'] ?? 'Detail',
        targetGroupId: extra?['targetGroupId'] as int?,
        targetTypeId: extra?['targetTypeId']?.toString(),
        hierarchyNodeKey: extra?['hierarchyNodeKey']?.toString(),
        hierarchySeedNode: seedNodeRaw == null
            ? null
            : ServiceHierarchyNode.fromJson(seedNodeRaw),
        hierarchyBreadcrumbs: breadcrumbsRaw
            .whereType<Map>()
            .map(
              (item) => ServiceHierarchyNode.fromJson(
                Map<String, dynamic>.from(item),
              ),
            )
            .toList(),
      );
    },
  ),
  GoRoute(
    path: AppRoutes.clientServiceTypes,
    name: AppRoutes.clientServiceTypesName,
    builder: (context, state) => ClientServiceTypesScreen(
      category: state.pathParameters['category'] ?? 'General',
    ),
  ),
  GoRoute(
    path: AppRoutes.clientCart,
    name: AppRoutes.clientCartName,
    builder: (context, state) => const CartScreen(),
  ),
  GoRoute(
    path: AppRoutes.clientCheckoutAddress,
    name: AppRoutes.clientCheckoutAddressName,
    builder: (context, state) => const CheckoutAddressScreen(),
  ),
  GoRoute(
    path: AppRoutes.clientCheckoutSlots,
    name: AppRoutes.clientCheckoutSlotsName,
    builder: (context, state) {
      final extra = state.extra as Map<String, dynamic>? ?? {};
      return CheckoutSlotScreen(addressData: extra['addressData'] ?? {});
    },
  ),
  GoRoute(
    path: AppRoutes.clientBooking,
    name: AppRoutes.clientBookingName,
    builder: (context, state) {
      final extra = state.extra as Map<String, dynamic>? ?? {};
      return BookingScreen(bookingData: extra);
    },
  ),
  GoRoute(
    path: AppRoutes.clientBookingStatus,
    name: AppRoutes.clientBookingStatusName,
    builder: (context, state) =>
        BookingStatusScreen(bookingId: state.pathParameters['bookingId'] ?? ''),
  ),
  GoRoute(
    path: AppRoutes.clientLiveTracking,
    name: AppRoutes.clientLiveTrackingName,
    builder: (context, state) =>
        LiveTrackingScreen(bookingId: state.pathParameters['bookingId'] ?? ''),
  ),
  GoRoute(
    path: AppRoutes.clientServiceReview,
    name: AppRoutes.clientServiceReviewName,
    builder: (context, state) =>
        ServiceReviewScreen(bookingId: state.pathParameters['bookingId'] ?? ''),
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
    path: AppRoutes.clientCheckoutReview,
    name: AppRoutes.clientCheckoutReviewName,
    builder: (context, state) {
      final data = state.extra as Map<String, dynamic>?;
      if (data == null) return const CartScreen();
      return ClientCheckoutReviewScreen(checkoutData: data);
    },
  ),
  GoRoute(
    path: AppRoutes.clientStoryViewer,
    name: AppRoutes.clientStoryViewerName,
    builder: (context, state) {
      final extra = state.extra as Map<String, dynamic>;
      final List<Story> stories = extra['stories'] as List<Story>;
      final int initialIndex = extra['initialIndex'] as int;
      return StoryViewerScreen(stories: stories, initialIndex: initialIndex);
    },
  ),
];
