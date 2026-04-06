# Database and Wallet Models

## Project Database Scope

The Laravel backend stores financial and domain data in MySQL via Laravel migrations.

### Wallet subsystem

#### Primary tables

- `wallets`
- `wallet_transactions`

These tables manage balance state for both customers and professionals.

## Wallet Schema

### `wallets`

- `id`: primary key
- `holder_type`: string — owner type, usually `professional` or `customer`
- `holder_id`: unsigned bigint — owner ID
- `type`: string — wallet type, usually `cash` or `coin`
- `balance`: bigint — stored as paise for cash wallets, or raw coin units for coin wallets
- `version`: unsigned integer — optimistic lock version
- timestamps

### `wallet_transactions`

- `id`
- `wallet_id`
- `type`: string — `credit` or `debit`
- `amount`: bigint — positive amount
- `balance_after`: bigint
- `source`: string — transaction source label
- `reference_id`: nullable bigint
- `reference_type`: nullable string
- `description`: nullable text
- `expires_at`: nullable timestamp
- timestamps

## Wallet Models

### `App\Models\Wallet`

- Attributes:
  - `holder_type`
  - `holder_id`
  - `type`
  - `balance`
  - `version`
- Relations:
  - `transactions()` — hasMany `WalletTransaction`
  - `holder()` — morphTo polymorphic owner relationship
- Methods:
  - `credit(int $amount, string $source, ?string $description = null, $referenceId = null, $referenceType = null)`
  - `debit(int $amount, string $source, ?string $description = null, $referenceId = null, $referenceType = null)`
- Concurrency control:
  - Uses optimistic locking via `version`
  - Throws on version conflict or insufficient balance

### `App\Models\WalletTransaction`

- Attributes include transaction metadata and `meta` casted as an array.
- Scopes:
  - `credits()`
  - `debits()`
  - `expired()`
  - `matured(int $delayDays = 7)`

## Professional Wallet Semantics

### Owner relation

- `App\Models\Professional::wallet()` returns the polymorphic wallet relation.
- `Professional::cashWallet()` filters the wallet by `type = cash`.

### Balance types

- `cash` wallet
  - Cash-based wallet used for payouts and withdrawal calculations
  - Stored in paise
- `coin` wallet
  - Coin-based wallet used for professional kit purchases and other in-app wallet actions
  - Stored in coin units

### Current implementation details

- Professional `GET /api/professional/wallet` creates or fetches both cash and coin wallets.
- The endpoint returns `cash_balance` converted to rupees and `coins_balance` directly as integer.
- The same endpoint also returns `active_balance` based on the selected `tab` parameter.

### Client wallet semantics

- Client wallet is implemented as `coin` wallet only.
- The client wallet controller explicitly selects `coinWallet` and returns:
  - `wallet_type: coin`
  - `balance` as coin units
  - `currency_label: BellaVella Coins`
  - `exchange_rate: 1 Coin = ₹1.00`

## Known wallet coding notes

- The app mixes two wallet concepts:
  - cash wallet for professionals (`cash` / paise)
  - coin wallet for both professionals and clients (`coin` / coins)
- In the backend, `wallets.balance` is unit-specific and should not be interpreted as rupees unless the wallet type is `cash`.
- `App\Models\Wallet::getFormattedBalanceAttribute()` formats `coin` wallets as coins and cash as rupees.

## Related Models and Flows

### `KitOrder`

- `App\Models\KitOrder`
- `payment_method` may be `Wallet` or `Razorpay`
- `status` may be `Assigned`, `Processing`, and includes stock and inventory updates

### `KitProduct`

- Maintains product listings, stock, and price
- Used by professional kit storefront and order flow

### Concurrency and Idempotency

- Professional wallet purchases use:
  - `Cache::lock(...)`
  - `lockForUpdate()` on wallet and kit product rows
  - idempotency keys/hashes stored with orders
- Wallet credit/debit operations use atomic SQL updates and version checks.
