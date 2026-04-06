# API Reference

## Base URL and Versioning

- API base URL is configured in Flutter via `API_BASE_URL`.
- Laravel automatically exposes versioned routes at both `/api` and `/api/v1`.

## Public Utility Endpoints

- `GET /api/images/{path}` — image proxy for public storage assets.
- `GET /api/theme` — theme metadata.
- `POST /api/razorpay/webhook` — Razorpay webhook receiver.

## Client API

### Public Client Routes

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
- Legacy compatibility endpoints for categories and services

### Client Authentication

- `POST /api/client/auth/send-otp`
- `POST /api/client/auth/verify-otp`

### Protected Client Routes

#### Profile
- `GET /api/client/profile`
- `POST /api/client/profile/update`
- `POST /api/client/profile/update-fcm-token`

#### Wallet
- `GET /api/client/wallet`
- `POST /api/client/wallet/deposit`
- `POST /api/client/wallet/withdraw`

#### Scratch cards
- `GET /api/client/scratch-cards`
- `POST /api/client/scratch-cards/{id}/scratch`

#### Addresses
- `apiResource('addresses')` — standard CRUD routes for addresses

#### Bookings
- `GET /api/client/bookings`
- `GET /api/client/bookings/{booking}`
- `POST /api/client/bookings/{booking}/cancel`
- `POST /api/client/bookings/{booking}/reschedule`

#### Notifications
- `GET /api/client/notifications`
- `POST /api/client/notifications/{id}/read`
- `POST /api/client/notifications/read-all`
- `DELETE /api/client/notifications/{id}`

#### Cart and Checkout
- `GET /api/client/cart`
- `POST /api/client/cart`
- `PUT /api/client/cart/{cart}`
- `DELETE /api/client/cart/{cart}`
- `POST /api/client/cart/clear`
- `POST /api/client/cart/sync`
- `POST /api/client/cart/checkout/preview`
- `POST /api/client/cart/checkout`
- `POST /api/client/cart/checkout/verify`
- `GET /api/client/slots-from-cart`

#### Reviews and Feedback
- `POST /api/client/bookings/{bookingId}/reviews`
- `POST /api/client/review/professional`
- `POST /api/client/app-feedback`

#### Offers and Referrals
- `GET /api/client/offers`
- `POST /api/client/offers/validate`
- `GET /api/client/promotions`
- `POST /api/client/promotions/validate`
- `GET /api/client/slots`
- `GET /api/client/referrals`

## Professional API

### Public Professional Routes
- `POST /api/professional/send-otp`
- `POST /api/professional/verify-otp`
- `POST /api/professional/register`
- `POST /api/professional/login`

### Protected Professional Routes

#### Auth and Profile
- `GET /api/professional/me`
- `GET /api/professional/verification-status`
- `POST /api/professional/refresh`
- `POST /api/professional/logout`
- `GET /api/professional/profile`
- `POST /api/professional/update-fcm-token`
- `POST /api/professional/update-bank-details`
- `POST /api/professional/update-upi-details`
- `PUT /api/professional/profile`
- `POST /api/professional/upload-profile-image`
- `POST /api/professional/upload-documents`
- `PUT /api/professional/change-password`

#### Dashboard and Availability
- `GET /api/professional/dashboard`
- `GET /api/professional/active-job`
- `POST /api/professional/toggle-availability`
- `POST /api/professional/update-online-status`
- `GET /api/professional/leaderboard`
- `GET /api/professional/schedule`
- `POST /api/professional/schedule/slots`

#### Bookings and Requests
- `GET /api/professional/booking-requests`
- `GET /api/professional/bookings`
- `GET /api/professional/bookings/{id}`
- `POST /api/professional/bookings/{id}/accept`
- `POST /api/professional/bookings/{id}/reject`

#### Job Workflow
- `POST /api/professional/jobs/{id}/arrived`
- `POST /api/professional/jobs/{id}/start-journey`
- `POST /api/professional/jobs/{id}/start-service`
- `POST /api/professional/jobs/{id}/finish-service`
- `POST /api/professional/jobs/{id}/scan-kit`
- `POST /api/professional/jobs/{id}/complete`
- `POST /api/professional/jobs/{id}/collect-cash`
- `POST /api/professional/jobs/{id}/payment/create-order`
- `POST /api/professional/jobs/{id}/payment/verify`

#### Earnings and Wallet
- `GET /api/professional/earnings`
- `GET /api/professional/wallet`
- `POST /api/professional/wallet/deposit/create-order`
- `POST /api/professional/wallet/deposit/verify`
- `GET /api/professional/jobs-history`
- `GET /api/professional/withdrawals/history`
- `POST /api/professional/withdraw`

#### Kit Store
- `GET /api/professional/kit-products`
- `POST /api/professional/orders` — wallet purchase
- `GET /api/professional/orders`
- `GET /api/professional/orders/{id}`
- `POST /api/professional/payment/create-order`
- `POST /api/professional/payment/verify`

#### Notifications
- `GET /api/professional/notifications`
- `POST /api/professional/notifications/{id}/read`
- `POST /api/professional/notifications/read-all`
- `DELETE /api/professional/notifications/{id}`

#### Reviews and Referrals
- `POST /api/professional/review/client`
- `GET /api/professional/referrals`
- `POST /api/professional/referrals/submit`

#### Leave
- `GET /api/professional/leaves`
- `POST /api/professional/leaves`
- `DELETE /api/professional/leaves/{id}`

## Admin API

### Auth
- `POST /api/admin/auth/login`
- `GET /api/admin/auth/me`
- `POST /api/admin/auth/refresh`
- `POST /api/admin/auth/logout`

### Management
- `apiResource('customers')`
- `apiResource('packages')`
- `apiResource('services')`
- `apiResource('offers')`
- `apiResource('reviews')->except(['store'])`
- `GET /api/admin/settings`
- `GET /api/admin/settings/{key}`
- `POST /api/admin/settings`
- `GET /api/admin/assignments`
- `POST /api/admin/assignments`
- `apiResource('banners')`
- `apiResource('videos')`
- `apiResource('media')`
- `apiResource('homepage')`
- `POST /api/admin/homepage/reorder`
- `apiResource('professionals')`
- `POST /api/admin/professionals/{id}/reactivate`
- `GET /api/admin/professionals-verification`
- `POST /api/admin/professionals/{id}/verify`
- `GET /api/admin/professionals/{id}/orders`
- `GET /api/admin/professionals/{id}/history`
- `apiResource('leave-requests')`
- `apiResource('kit/products')`
- `apiResource('kit/orders')`
- `GET /api/admin/withdrawals`
- `POST /api/admin/withdrawals/{id}/approve`
- `POST /api/admin/withdrawals/{id}/reject`
- `GET /api/admin/areas`

## Notes

- `GET /api/v1/...` routes are an alias of `/api/...` via route group registration.
- `apiResource` routes support RESTful CRUD methods automatically.
- The professional wallet API returns both cash and coin balances; the front-end may choose the active view using `tab=earnings` or `tab=coins`.
