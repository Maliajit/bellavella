# Flutter Architecture

## App Entry and Flavoring

The Flutter app is designed as a single codebase with two entrypoints:

- `lib/main_client.dart`
  - Sets `AppConfig.type = AppType.client`
  - Launches the client-facing app router.
- `lib/main_professional.dart`
  - Sets `AppConfig.type = AppType.professional`
  - Initializes `NotificationService` and `FirebaseMessagingService`
  - Launches the professional-facing app router.
- `lib/main.dart`
  - Bootstrap file shared by both flavors
  - Initializes Firebase, token manager, and providers
  - Builds `MaterialApp.router` using the selected router

## Configuration

- `lib/core/config/app_config.dart`
  - Resolves `API_BASE_URL` through Dart defines or debug fallback
  - Derives API host, port, origin, and media origin
  - Controls app flavor with `AppConfig.type`
  - Provides Razorpay and Google Maps key resolution for environment config

## Networking

### `lib/core/services/api_service.dart`

Responsibilities:

- Builds REST API URLs using `AppConfig.baseUrl`
- Adds `Authorization: Bearer <token>` when available
- Supports GET, POST, PUT, PATCH, DELETE, and multipart requests
- Handles HTTP 401 with refresh token flow and login redirect
- Handles HTTP 403 suspended account flows for professionals
- Logs request and response metadata for debugging

### Token management

- `lib/core/services/token_manager.dart`
- Professional and client tokens are stored separately
- `ApiService` chooses the active token based on `AppConfig.isProfessional`

## Routing

### Route definitions

- `lib/core/routes/app_routes.dart`
  - Centralizes route paths and route names for both client and professional apps
- `lib/core/router/client_router.dart`
  - Defines client screens, authentication flow, onboarding, and customer features
- `lib/core/router/professional_router.dart`
  - Defines professional routing with a shell route for persistent navigation UI

### Schemes

- Uses `go_router` for declarative navigation and nested shell routes
- Supports route parameters such as `:id`, dynamic state extras, and named routes

## State Management

### Providers

The app uses `provider` for shared state and controllers.

Registered providers in `lib/main.dart`:

- `ProfessionalProfileController`
- `DashboardController.instance`
- `HomeProvider`
- `ServiceProvider`
- `PackageProvider`
- `CartProvider`

### Feature-level controllers

- Flutter features often follow the provider pattern with dedicated controllers for business logic.
- Example: `lib/features/client/cart/controllers/cart_provider.dart`

## Feature Modules

### Client features

- `lib/features/client/auth` — login, OTP verification, onboarding, role selection
- `lib/features/client/home` — homepage, service discovery, banners, stories
- `lib/features/client/services` — category, service detail, package browsing
- `lib/features/client/cart` — cart, checkout, address selection, slot picker
- `lib/features/client/profile` — wallet, scratch cards, refer & earn, address management, reviews

### Professional features

- `lib/features/professional/auth` — login, verify OTP, signup, verification status
- `lib/features/professional/dashboard` — professional dashboard, jobs, availability, schedule
- `lib/features/professional/bookings` — requests, booking detail, job workflow management
- `lib/features/professional/earnings` — wallet view, transactions, withdrawal history
- `lib/features/professional/notifications` — notification inbox, incoming request handling
- `lib/features/professional/screens/kit_store` — kit storefront, purchase flow, order history
- `lib/features/professional/profile` — profile, bank details, UPI details, KYC documents

## Wallet and Kit Store Flow

### Professional wallet flow

Implemented by `ProfessionalApiService.getWallet` calling `/professional/wallet`.

- `ProfessionalWallet` maps API wallet fields into app state.
- The API response includes:
  - `cash_balance`
  - `coins_balance`
  - `available_balance`
  - `total_balance`
  - `withdraw_unlocked`
  - transaction history

### Kit store flow

Implemented by `ProfessionalApiService` with two payment paths:

- Wallet purchase: `POST /professional/orders`
- Razorpay purchase: `POST /professional/payment/create-order` and `POST /professional/payment/verify`

The app uses idempotency keys stored in `SharedPreferences` for wallet and Razorpay order verification.

## Firebase and Notifications

- The professional app initializes FCM and local notification services in `main_professional.dart`.
- The shared bootstrap in `lib/main.dart` also initializes Firebase and listens to Firestore collections for debugging.

## Build and Run Notes

Recommended entry commands:

- Client flavor:
  - `flutter run -t lib/main_client.dart --dart-define=API_BASE_URL=...`
- Professional flavor:
  - `flutter run -t lib/main_professional.dart --dart-define=API_BASE_URL=...`

Use environment defines for API host and keys:

- `API_BASE_URL`
- `API_BASE_URL_DEBUG`
- `RAZORPAY_KEY_ID`
- `GOOGLE_MAPS_API_KEY`

## Key Files

- `lib/main.dart`
- `lib/main_client.dart`
- `lib/main_professional.dart`
- `lib/core/config/app_config.dart`
- `lib/core/services/api_service.dart`
- `lib/core/routes/app_routes.dart`
- `lib/core/router/client_router.dart`
- `lib/core/router/professional_router.dart`
- `lib/features/professional/services/professional_api_service.dart`
