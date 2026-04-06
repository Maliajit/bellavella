# Bellavella Project Overview

## Project Scope

Bellavella is a two-part platform:

- **Client mobile app**: Allows customers to discover services, book appointments, manage a coin wallet, and track bookings.
- **Professional mobile app**: Enables service providers to manage bookings, track earnings, maintain a wallet, buy kits, and receive notifications.
- **Laravel backend**: Implements public APIs, client/professional/admin auth, wallet operations, kit ordering, Razorpay payment flows, and admin management.

## Workspace Layout

### Flutter app root

- `c:\flutter-project\bellavella`
- Main mobile application with both client and professional flavors.
- Key entrypoints:
  - `lib/main_client.dart` — client app flavor
  - `lib/main_professional.dart` — professional app flavor
  - `lib/main.dart` — shared app bootstrap and dependency wiring

### Backend root

- `c:\xampp\htdocs\bellavellaa`
- Laravel API backend, JWT auth, admin APIs, models, controllers, and migrations.
- Key route definitions:
  - `routes/api.php`

## Architectural Summary

### Flutter app

- Uses `go_router` for declarative navigation.
- Uses `provider` for app-wide state management.
- Uses a shared `ApiService` with JWT token handling, refresh logic, and auto redirect to login.
- Supports both client and professional app types using `AppConfig.type`.
- Integrates Firebase for push notifications and Firestore listeners.

### Backend

- Uses Laravel route groups:
  - `/api/client/*`
  - `/api/professional/*`
  - `/api/admin/*`
- Uses JWT-based authentication for clients, professionals, and admin users.
- Defines wallet logic via `Wallet` and `WalletTransaction` models.
- Uses optimistic locking and database transactions for wallet/debit operations.
- Supports professional kit store purchases via wallet or Razorpay payments.

## Current Key Findings

1. **Professional wallet storage** is in the `wallets` table. Each professional has two wallet rows:
   - `type = cash` — stores cash balance in paise.
   - `type = coin` — stores wallet coins.
2. **Client wallet storage** is also in `wallets`, but the client-facing wallet uses `type = coin` only.
3. **Kit wallet purchase** for professionals uses the `coin` wallet and debits coin balance in paise.
4. The project separates `cash_balance` and `coin_balance` in the professional wallet API, but `wallet.totalBalance` can be misleading if the app treats it as actual currency.

## Recommended Reading Order

1. `project-overview.md`
2. `flutter-architecture.md`
3. `backend-architecture.md`
4. `api-reference.md`
5. `database-wallet-models.md`
