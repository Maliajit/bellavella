# Backend Architecture

## Overview

The backend is a Laravel API application located at `c:\xampp\htdocs\bellavellaa`.

It exposes a versioned API under `/api` and `/api/v1` with three primary groups:

- `client` — customer-facing mobile API
- `professional` — professional-facing mobile API
- `admin` — admin panel API

The route group configuration is located in `routes/api.php`.

## Auth and Guards

Authentication is JWT-based.

### Client auth

- `POST /api/client/auth/send-otp`
- `POST /api/client/auth/verify-otp`
- Protected client routes use `auth:api` middleware.

### Professional auth

- `POST /api/professional/send-otp`
- `POST /api/professional/verify-otp`
- `POST /api/professional/register`
- `POST /api/professional/login`
- Protected routes use `auth:professional-api`.
- Some professional routes are further protected by `professional.suspended` middleware.

### Admin auth

- `POST /api/admin/auth/login`
- Admin protected routes use `jwt.admin` middleware.

## API Route Organization

### Client

Public routes:

- `GET /api/client/homepage`
- `GET /api/client/categories`
- `GET /api/client/categories/{slug}`
- `GET /api/client/categories/{slug}/screen`
- `GET /api/client/categories/{slug}/page`
- `GET /api/client/categories/{slug}/details`
- `GET /api/client/categories/{slug}/service-groups`
- `GET /api/client/service-groups/{id}`
- `GET /api/client/services/{id}`
- `GET /api/client/service-hierarchy/{nodeKey}`
- `GET /api/client/packages/featured`
- `GET /api/client/packages`
- `GET /api/client/packages/{package}/config`
- `GET /api/client/services/{id}/reviews`
- Legacy service/category compatibility endpoints

Protected routes include:

- profile, wallet, scratch cards, addresses, bookings, cart, slots, reviews, offers, promotions, and referrals.

### Professional

Public auth routes:

- `POST /api/professional/send-otp`
- `POST /api/professional/verify-otp`
- `POST /api/professional/register`
- `POST /api/professional/login`

Protected professional routes include:

- `GET /api/professional/me`
- `GET /api/professional/verification-status`
- `POST /api/professional/refresh`
- `POST /api/professional/logout`
- `GET /api/professional/profile`
- `POST /api/professional/update-fcm-token`
- `POST /api/professional/update-bank-details`
- `POST /api/professional/update-upi-details`
- dashboard, booking requests, bookings, jobs, wallet, withdrawals, kit products, kit orders, notifications, referrals, leaves, profile update, and documents.

### Admin

Protected admin routes include customers, packages, services, offers, reviews, settings, assignments, banners, videos, media, homepage, professionals management, leave requests, kit products, kit orders, and withdrawals.

## Wallet System

### Tables

- `wallets`
- `wallet_transactions`

### Models

- `App\Models\Wallet`
- `App\Models\WalletTransaction`

### Wallet storage semantics

- `wallets.holder_type` — identifies the owner type, e.g. `professional` or `customer`.
- `wallets.holder_id` — owner ID.
- `wallets.type` — wallet type, typically `cash` or `coin`.
- `wallets.balance` — stored as an integer representing paise for cash wallets, and coin units for coin wallets.

### Professional wallet details

Professionals have both:

- `type = cash` — stores cash balance in paise.
- `type = coin` — stores coin balance.

#### `GET /api/professional/wallet`

- Returns both cash and coin balances.
- Uses the `tab` query parameter to select the active wallet view (`earnings` maps to cash, `coins` maps to coin wallet).
- Returns `cash_balance`, `coins_balance`, `total_balance`, and transaction history.

### Professional kit wallet purchase

- `POST /api/professional/orders`
- Deducts from the professional's coin wallet using `type = coin`
- Secures the purchase with:
  - distributed lock
  - transaction-scoped row lock on wallet and product stock
  - idempotency key and hash
  - `WalletService::deduct`

### Razorpay kit purchase

- `POST /api/professional/payment/create-order`
- `POST /api/professional/payment/verify`

This flow creates a Razorpay order server-side and verifies payment signatures before creating a `KitOrder`.

## Important Controllers

- `app/Http/Controllers/Api/Client/WalletController.php`
- `app/Http/Controllers/Api/Professionals/KitController.php`
- `app/Http/Controllers/Api/Professionals/EarningsController.php`
- `app/Http/Controllers/Api/Professionals/AuthController.php`
- `app/Http/Controllers/Api/Admin/AuthController.php`

## Transaction and Concurrency Safeguards

- Wallet credits and debits use optimistic locking via `wallet.version`.
- Kit wallet checkout uses MySQL row-level locking with `lockForUpdate()`.
- Razorpay verification uses idempotency keys and response caching for replay protection.

## Backend Notes

- `wallets.balance` is intentionally stored in the smallest unit for cash wallets (paise) and integer coin units for coin wallets.
- Some controller actions return numeric values as floats for frontend convenience, especially cash balances converted to rupees.
- The backend has a dedicated `images` proxy route for serving stored public images via `/api/images/{path}`.
