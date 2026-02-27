class AppRoutes {
  // Common Routes
  static const String root = '/';
  static const String onboarding = '/onboarding';

  // Client Routes
  static const String clientLogin = '/client/login';
  static const String clientVerifyOtp = '/client/verify-otp';
  static const String clientLocationPicker = '/client/location-picker';
  static const String clientHome = '/client/home';
  static const String clientCategory = '/client/services/:category';
  static const String clientCategoryDetail = '/client/category-detail/:name';
  static const String clientServiceTypes = '/client/service-types/:category';
  static const String clientServiceDetail = '/client/service-detail/:id';
  static const String clientCart = '/client/cart';
  static const String clientBooking = '/client/booking';
  static const String clientBookingStatus = '/client/booking-status';
  static const String clientLiveTracking = '/client/live-tracking/:bookingId';
  static const String clientMyBookings = '/client/my-bookings';
  static const String clientServiceReview = '/client/service-review/:bookingId';
  static const String clientProfile = '/client/profile';
  static const String clientManageAddress = '/client/profile/manage-address';
  static const String clientUpdateAddress = '/client/profile/update-address';
  static const String clientReferEarn = '/client/profile/refer-earn';
  static const String clientRateUs = '/client/profile/rate-us';
  static const String clientAboutUs = '/client/profile/about-us';
  static const String clientEditProfile = '/client/profile/edit-profile';
  static const String clientWallet = '/client/wallet';
  static const String clientCheckoutReview = '/client/checkout-review';

  // Professional Routes
  static const String proLogin = '/professional/login';
  static const String proVerifyOtp = '/professional/verify-otp';
  static const String proSignup = '/professional/signup';
  static const String proVerificationStatus = '/professional/verification-status';
  static const String proDashboard = '/professional/dashboard';
  static const String proOrders = '/professional/orders';
  static const String proEarnings = '/professional/earnings';
  static const String proProfile = '/professional/profile';
  static const String proJobs = '/professional/jobs';
  static const String proWallet = '/professional/wallet';
  static const String proSchedule = '/professional/schedule';
  static const String proEditProfile = '/professional/edit-profile';
  static const String proRequests = '/professional/requests';
  static const String proBookingDetail = '/professional/booking-detail/:id';
  static const String proAvailability = '/professional/availability';
  static const String proIncomingRequest = '/professional/incoming-request';
  static const String proKitStore = '/professional/kit-store';

  // Route Names (for context.goNamed)
  static const String rootName = 'root';
  static const String onboardingName = 'onboarding';

  static const String clientLoginName = 'clientLogin';
  static const String clientVerifyOtpName = 'clientVerifyOtp';
  static const String clientLocationPickerName = 'clientLocationPicker';
  static const String clientHomeName = 'clientHome';
  static const String clientCategoryName = 'clientCategory';
  static const String clientCategoryDetailName = 'clientCategoryDetail';
  static const String clientServiceTypesName = 'clientServiceTypes';
  static const String clientServiceDetailName = 'clientServiceDetail';
  static const String clientCartName = 'clientCart';
  static const String clientBookingName = 'clientBooking';
  static const String clientBookingStatusName = 'clientBookingStatus';
  static const String clientLiveTrackingName = 'clientLiveTracking';
  static const String clientMyBookingsName = 'clientMyBookings';
  static const String clientServiceReviewName = 'clientServiceReview';
  static const String clientProfileName = 'clientProfile';
  static const String clientManageAddressName = 'clientManageAddress';
  static const String clientUpdateAddressName = 'clientUpdateAddress';
  static const String clientReferEarnName = 'clientReferEarn';
  static const String clientRateUsName = 'clientRateUs';
  static const String clientAboutUsName = 'clientAboutUs';
  static const String clientEditProfileName = 'clientEditProfile';
  static const String clientWalletName = 'clientWallet';
  static const String clientCheckoutReviewName = 'clientCheckoutReview';

  static const String proLoginName = 'proLogin';
  static const String proVerifyOtpName = 'proVerifyOtp';
  static const String proSignupName = 'proSignup';
  static const String proVerificationStatusName = 'proVerificationStatus';
  static const String proDashboardName = 'proDashboard';
  static const String proOrdersName = 'proOrders';
  static const String proEarningsName = 'proEarnings';
  static const String proProfileName = 'proProfile';
  static const String proJobsName = 'proJobs';
  static const String proWalletName = 'proWallet';
  static const String proScheduleName = 'proSchedule';
  static const String proEditProfileName = 'proEditProfile';
  static const String proRequestsName = 'proRequests';
  static const String proBookingDetailName = 'proBookingDetail';
  static const String proAvailabilityName = 'proAvailability';
  static const String proIncomingRequestName = 'proIncomingRequest';
  static const String proKitStoreName = 'proKitStore';
}
