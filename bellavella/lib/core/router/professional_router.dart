import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../routes/app_routes.dart';
import '../widgets/professional_scaffold.dart';
import '../../features/client/splash/splash_screen.dart';
import '../../features/client/auth/onboarding_screen.dart';
import '../../features/client/auth/role_selection_screen.dart';
import '../../features/professional/auth/professional_login_screen.dart';
import '../../features/professional/auth/otp_verify_screen.dart';
import '../../features/professional/auth/professional_signup_screen.dart';
import '../../features/professional/auth/verification_status_screen.dart';
import '../../features/professional/orders/professional_order_list_screen.dart';
import '../../features/professional/dashboard/professional_dashboard_screen.dart';
import '../../features/professional/profile/professional_profile_screen.dart';
import '../../features/professional/profile/kyc_documents_screen.dart';
import '../../features/professional/profile/document_view_screen.dart';
import '../../features/professional/earnings/professional_jobs_screen.dart';
import '../../features/professional/earnings/professional_wallet_screen.dart';
import '../../features/professional/earnings/professional_schedule_screen.dart';
import '../../features/professional/profile/professional_edit_profile_screen.dart';
import '../../features/professional/bookings/professional_booking_requests_screen.dart';
import '../../features/professional/bookings/professional_booking_detail_screen.dart';
import '../../features/professional/earnings/professional_availability_screen.dart';
import '../../features/professional/earnings/professional_transaction_history_screen.dart';
import '../../features/professional/earnings/withdrawal_request_screen.dart';
import '../../features/professional/earnings/withdrawal_history_screen.dart';
import '../../features/professional/earnings/professional_refer_earn_screen.dart';
import '../../features/professional/notifications/incoming_request_screen.dart';
import '../../features/professional/screens/kit_store/kit_store_screen.dart';
import '../../features/professional/navigation/professional_navigation_screen.dart';
import '../../features/professional/job_workflow/screens/pro_arrival_screen.dart';
import '../../features/professional/job_workflow/screens/pro_kit_scan_screen.dart';
import '../../features/professional/job_workflow/screens/pro_service_screen.dart';
import '../../features/professional/job_workflow/screens/pro_payment_screen.dart';
import '../../features/professional/job_workflow/screens/pro_completion_screen.dart';
import '../../features/professional/job_workflow/screens/job_workflow_container_screen.dart';
import '../../features/professional/notifications/professional_notifications_screen.dart';
import '../../features/professional/screens/profile/edit_personal_information_screen.dart';
import '../../features/professional/screens/profile/edit_service_area_screen.dart';
import '../../features/professional/screens/profile/edit_working_hours_screen.dart';
import '../../features/professional/screens/profile/edit_contact_details_screen.dart';
import '../../features/professional/screens/profile/payment_details_screen.dart';
import '../../features/professional/screens/profile/notification_settings_screen.dart';
import '../../features/professional/screens/profile/change_password_screen.dart';
import '../../features/professional/screens/profile/language_settings_screen.dart';
import '../../features/professional/screens/kit_store/kit_order_history_screen.dart';
import '../../features/professional/screens/kit_store/payment_success_screen.dart';
import '../../features/professional/screens/kit_store/kit_order_details_screen.dart';
import '../../features/professional/leave/leave_apply_screen.dart';
import '../../features/professional/auth/suspended_screen.dart';
import '../../core/models/data_models.dart';
import 'package:bellavella/features/professional/models/professional_models.dart';

final proNavigatorKey = GlobalKey<NavigatorState>();

final professionalRouter = GoRouter(
  navigatorKey: proNavigatorKey,
  initialLocation: AppRoutes.splash,
  routes: [
    ..._rootRoutes,
    ..._authRoutes,
    ShellRoute(
      builder: (context, state, child) => ProfessionalScaffold(child: child),
      routes: [
        ..._shellRoutes,
        ..._proOtherRoutes,
      ],
    ),
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
  GoRoute(
    path: AppRoutes.proIncomingRequest,
    name: AppRoutes.proIncomingRequestName,
    builder: (context, state) {
      final notification = state.extra as Map<String, dynamic>? ?? {};
      return IncomingRequestScreen(notification: notification);
    },
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
      final extra = state.extra;
      if (extra is String) {
        return OTPVerifyScreen(phoneNumber: extra);
      } else if (extra is Map) {
        return OTPVerifyScreen(
          phoneNumber: extra['phone'] as String? ?? '',
          referralCode: extra['referral_code'] as String?,
          autoFillOtp: extra['auto_fill_otp'] as String?,
        );
      }
      return const ProfessionalLoginScreen();
    },
  ),
  GoRoute(
    path: AppRoutes.proSignup,
    name: AppRoutes.proSignupName,
    builder: (context, state) {
      final extra = state.extra;
      if (extra is String) {
        return ProfessionalSignupScreen(phoneNumber: extra);
      } else if (extra is Map) {
        return ProfessionalSignupScreen(
          phoneNumber: extra['phone'] as String?,
          referralCode: extra['referral_code'] as String?,
        );
      }
      return const ProfessionalSignupScreen();
    },
  ),
  GoRoute(
    path: AppRoutes.proVerificationStatus,
    name: AppRoutes.proVerificationStatusName,
    builder: (context, state) => VerificationStatusScreen(
      applicantName: state.extra as String?,
    ),
  ),
  GoRoute(
    path: AppRoutes.proSuspended,
    name: AppRoutes.proSuspendedName,
    builder: (context, state) => const SuspendedScreen(),
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
    path: AppRoutes.proWallet,
    name: AppRoutes.proWalletName,
    builder: (context, state) => const ProfessionalWalletScreen(),
  ),
  GoRoute(
    path: AppRoutes.proProfile,
    name: AppRoutes.proProfileName,
    builder: (context, state) => const ProfessionalProfileScreen(),
  ),
  GoRoute(
    path: AppRoutes.proKitStore,
    name: AppRoutes.proKitStoreName,
    builder: (context, state) => const KitStoreScreen(),
  ),
  GoRoute(
    path: AppRoutes.proTransactions,
    name: AppRoutes.proTransactionsName,
    builder: (context, state) => const ProfessionalTransactionHistoryScreen(),
  ),
  GoRoute(
    path: AppRoutes.proWithdrawalHistory,
    name: AppRoutes.proWithdrawalHistoryName,
    builder: (context, state) => const WithdrawalHistoryScreen(),
  ),
];

final _proOtherRoutes = [
  GoRoute(
    path: AppRoutes.proJobs,
    name: AppRoutes.proJobsName,
    builder: (context, state) => const ProfessionalJobsScreen(),
  ),
  GoRoute(
    path: AppRoutes.proSchedule,
    name: AppRoutes.proScheduleName,
    builder: (context, state) => const ProfessionalScheduleScreen(),
  ),
  GoRoute(
    path: AppRoutes.proWithdrawalRequest,
    name: AppRoutes.proWithdrawalRequestName,
    builder: (context, state) => const WithdrawalRequestScreen(),
  ),
  GoRoute(
    path: AppRoutes.proReferEarn,
    name: AppRoutes.proReferEarnName,
    builder: (context, state) => const ProfessionalReferEarnScreen(),
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
    path: AppRoutes.proNavigation,
    name: AppRoutes.proNavigationName,
    builder: (context, state) {
      final id = state.pathParameters['id'] ?? '';
      final extra = state.extra;
      ProfessionalBooking booking;
      if (extra is ProfessionalBooking) {
        booking = extra;
      } else if (extra is Map<String, dynamic>) {
        booking = ProfessionalBooking.fromJson(extra);
      } else {
        booking = ProfessionalBooking.empty().copyWith(id: id);
      }
      return ProfessionalNavigationScreen(booking: booking);
    },
  ),
  GoRoute(
    path: AppRoutes.proActiveJob,
    name: AppRoutes.proActiveJobName,
    builder: (context, state) {
      final id = state.pathParameters['id'] ?? '';
      return JobWorkflowContainerScreen(bookingId: id);
    },
  ),
  GoRoute(
    path: AppRoutes.proArrive,
    name: AppRoutes.proArriveName,
    builder: (context, state) {
      final id = state.pathParameters['id'] ?? '';
      return JobWorkflowContainerScreen(bookingId: id);
    },
  ),
  GoRoute(
    path: AppRoutes.proScanKit,
    name: AppRoutes.proScanKitName,
    builder: (context, state) {
      final id = state.pathParameters['id'] ?? '';
      return JobWorkflowContainerScreen(bookingId: id);
    },
  ),
  GoRoute(
    path: AppRoutes.proCollectPayment,
    name: AppRoutes.proCollectPaymentName,
    builder: (context, state) {
      final id = state.pathParameters['id'] ?? '';
      return JobWorkflowContainerScreen(bookingId: id);
    },
  ),
  GoRoute(
    path: AppRoutes.proJobComplete,
    name: AppRoutes.proJobCompleteName,
    builder: (context, state) {
      final id = state.pathParameters['id'] ?? '';
      return JobWorkflowContainerScreen(bookingId: id);
    },
  ),
  GoRoute(
    path: AppRoutes.proNotifications,
    name: AppRoutes.proNotificationsName,
    builder: (context, state) => const ProfessionalNotificationsScreen(),
  ),
  GoRoute(
    path: AppRoutes.proEditPersonalInfo,
    name: AppRoutes.proEditPersonalInfoName,
    builder: (context, state) => const EditPersonalInformationScreen(),
  ),
  GoRoute(
    path: AppRoutes.proEditServiceArea,
    name: AppRoutes.proEditServiceAreaName,
    builder: (context, state) => const EditServiceAreaScreen(),
  ),
  GoRoute(
    path: AppRoutes.proEditWorkingHours,
    name: AppRoutes.proEditWorkingHoursName,
    builder: (context, state) => const EditWorkingHoursScreen(),
  ),
  GoRoute(
    path: AppRoutes.proEditContactDetails,
    name: AppRoutes.proEditContactDetailsName,
    builder: (context, state) => const EditContactDetailsScreen(),
  ),
  GoRoute(
    path: AppRoutes.proEditBankDetails,
    name: AppRoutes.proEditBankDetailsName,
    builder: (context, state) => const PaymentDetailsScreen(),
  ),
  GoRoute(
    path: AppRoutes.proEditUPIDetails,
    name: AppRoutes.proEditUPIDetailsName,
    builder: (context, state) => const PaymentDetailsScreen(),
  ),
  GoRoute(
    path: AppRoutes.proEditSkills,
    name: AppRoutes.proEditSkillsName,
    builder: (context, state) => const EditPersonalInformationScreen(), // Placeholder
  ),
  GoRoute(
    path: AppRoutes.proEditPortfolio,
    name: AppRoutes.proEditPortfolioName,
    builder: (context, state) => const EditPersonalInformationScreen(), // Placeholder
  ),
  GoRoute(
    path: AppRoutes.proNotificationSettings,
    name: AppRoutes.proNotificationSettingsName,
    builder: (context, state) => const NotificationSettingsScreen(),
  ),
  GoRoute(
    path: AppRoutes.proChangePassword,
    name: AppRoutes.proChangePasswordName,
    builder: (context, state) => const ChangePasswordScreen(),
  ),
  GoRoute(
    path: AppRoutes.proLanguageSettings,
    name: AppRoutes.proLanguageSettingsName,
    builder: (context, state) => const LanguageSettingsScreen(),
  ),
  GoRoute(
    path: AppRoutes.proKitOrders,
    name: AppRoutes.proKitOrdersName,
    builder: (context, state) => const KitOrderHistoryScreen(),
  ),
  GoRoute(
    path: AppRoutes.proKitPaymentSuccess,
    name: AppRoutes.proKitPaymentSuccessName,
    builder: (context, state) {
      final extra = state.extra as Map<String, dynamic>? ?? {};
      return PaymentSuccessScreen(
        orderId: extra['orderId']?.toString() ?? '',
        amount: (extra['amount'] as num?)?.toDouble() ?? 0,
        kitName: extra['kitName']?.toString() ?? '',
        paymentId: extra['paymentId']?.toString() ?? '',
      );
    },
  ),
  GoRoute(
    path: AppRoutes.proKitOrderDetails,
    name: AppRoutes.proKitOrderDetailsName,
    builder: (context, state) => KitOrderDetailsScreen(
      orderId: state.pathParameters['id'] ?? '',
    ),
  ),
  GoRoute(
    path: AppRoutes.proLeaveApply,
    name: AppRoutes.proLeaveApplyName,
    builder: (context, state) => const LeaveApplyScreen(),
  ),
  GoRoute(
    path: AppRoutes.proKycDocuments,
    name: AppRoutes.proKycDocumentsName,
    builder: (context, state) {
      final professional = state.extra as Professional;
      return KycDocumentsScreen(professional: professional);
    },
  ),
  GoRoute(
    path: AppRoutes.proDocumentView,
    name: AppRoutes.proDocumentViewName,
    builder: (context, state) {
      final extra = state.extra as Map<String, dynamic>;
      return DocumentViewScreen(
        title: extra['title'] as String,
        imageUrl: extra['imageUrl'] as String,
      );
    },
  ),
];
