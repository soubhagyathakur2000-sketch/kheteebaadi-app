# Kheteebaadi - Agricultural Marketplace Flutter App

A complete, production-grade Flutter application for an agricultural marketplace platform. This app implements an offline-first architecture with clean code principles, designed specifically for low-end devices and Indian farmers.

## Project Overview

**Kheteebaadi** is an agricultural marketplace that connects farmers directly with markets. The app provides:

- Real-time mandi (market) prices with local language support
- Order management system with offline-first sync
- User authentication via OTP
- Complete offline functionality with automatic sync when online
- Multi-language support (English, Hindi, Marathi)
- Optimized UI for low-end devices

## Architecture Overview

The app follows **Clean Architecture** principles with clear separation of concerns:

```
lib/
├── core/                    # Core functionality
│   ├── constants/          # API & app constants
│   ├── di/                 # Dependency injection (Riverpod)
│   ├── network/            # Networking layer
│   ├── theme/              # Material design theme
│   └── utils/              # Helpers (Either type, Failures)
├── database/               # Drift local database
├── features/               # Feature modules
│   ├── auth/              # Authentication
│   ├── home/              # Home dashboard
│   ├── mandi/             # Market prices
│   ├── orders/            # Order management
│   ├── profile/           # User profile
│   └── sync/              # Data synchronization
├── l10n/                   # Localization files
└── main.dart              # App entry point
```

## Key Features

### 1. Offline-First Architecture
- All data is stored locally in Drift SQLite database
- Automatic sync queuing when offline
- Data merging strategies for conflict resolution
- Idempotent API calls with unique keys

### 2. Real-Time Synchronization
- `SyncEngine` class manages batch sync operations
- Exponential backoff retry logic
- Per-item success/failure tracking
- Persistent pending sync queue in database
- Automatic sync trigger on connectivity change

### 3. Authentication System
- OTP-based login (no passwords)
- Secure token storage using `flutter_secure_storage`
- JWT token injection via interceptors
- Token refresh mechanism
- Session validation on app launch

### 4. Network Layer
- Dio-based HTTP client with interceptors
- Automatic retry with exponential backoff
- Connectivity check before every request
- Request/response logging
- Typed error handling (ServerFailure, NetworkFailure, etc.)

### 5. State Management
- `flutter_riverpod` for reactive state
- `StateNotifier` pattern for complex state
- Async operations with `FutureProvider`
- Stream-based real-time updates (sync status, connectivity)

### 6. Local Storage
- **Drift**: SQLite database with type-safe queries
- **Hive**: Fast NoSQL for auth tokens and settings
- **SharedPreferences**: App-wide preferences
- **flutter_secure_storage**: Encrypted credential storage

### 7. UI Optimization
- Minimal animations for low-end device performance
- Shimmer loading placeholders
- Large touch targets (56dp minimum)
- Material Design 3 theming
- Responsive layouts

### 8. Multilingual Support
- English, Hindi, Marathi translations
- ARB file format for easy management
- Language preference persistence
- Regional locale awareness

## Database Schema

### Core Tables

**Users**
```sql
id (PK) | name | phone (UQ) | village_id | language_pref | avatar_url | created_at | updated_at
```

**MandiPrices**
```sql
id (PK) | crop_name | crop_name_local | price_per_quintal | mandi_name |
mandi_id | region_id | unit | price_change | fetched_at | is_cached
```

**Orders**
```sql
id (PK) | user_id | items_json | total_amount | status |
created_at | updated_at | synced
```

**PendingSync**
```sql
id (PK) | entity_type | entity_id | payload_json | idempotency_key (UQ) |
created_at | retry_count | last_retry_at | status | failure_reason
```

**Villages**
```sql
id (PK) | name | district | state | latitude | longitude
```

## API Integration

### Authentication Endpoints
- `POST /auth/request-otp` - Request OTP
- `POST /auth/verify-otp` - Verify OTP and get tokens
- `POST /auth/refresh-token` - Refresh JWT token

### Market Endpoints
- `GET /mandi/prices?region_id=&page=&limit=` - Get market prices
- `GET /mandi/search-crops?q=` - Search crops
- `GET /mandi/detail/{mandiId}` - Get mandi details

### Order Endpoints
- `POST /orders/create` - Create new order
- `GET /orders?user_id=` - List user orders
- `GET /orders/{orderId}` - Get order details
- `POST /orders/{orderId}/cancel` - Cancel order

### Sync Endpoint
- `POST /sync/batch` - Batch sync with idempotency
  - Payload: `{ items: [{ id, entity_type, entity_id, payload, idempotency_key }] }`
  - Response: `{ results: [{ id, success, error }] }`

## Data Flow Examples

### Online Order Creation
1. User creates order in UI
2. Order saved to local database (synced=false)
3. Added to PendingSync queue
4. Network call attempts immediately
5. On success, order marked as synced
6. UI updates from local database + remote merge

### Offline Scenario
1. User creates order (no internet)
2. Order stored locally with synced=false
3. SyncEngine queues in PendingSync
4. UI shows "Will sync when online" indicator
5. App detects connectivity change
6. SyncEngine runs batch sync operation
7. Failed items retry with exponential backoff
8. UI syncs with user notification

### Mandi Prices Cache Strategy
- **First load**: Fetch from API, cache in DB
- **Cache valid** (< 15 min): Return cached
- **Cache stale**: Return cached while fetching remote
- **Offline**: Return cached data
- **No cache + offline**: Show error with retry

## Performance Optimizations

### For Low-End Devices
- Single animations disabled in theme
- Shimmer instead of full page skeletons
- Pagination (default 20 items per page)
- Image caching with `cached_network_image`
- Database query optimization
- Minimal dependencies

### Network Optimization
- Request batching (max 50 items per sync batch)
- Exponential backoff (1s, 2s, 4s, 8s...)
- Connection timeout: 15 seconds
- Receive timeout: 30 seconds
- Automatic retry on transient failures

## Testing Guides

### Offline Mode Testing
```
1. Turn off internet (WiFi + Mobile Data)
2. Create order / view prices
3. Verify "offline" indicator shows
4. Turn internet back on
5. Watch SyncStatusWidget show "syncing..."
6. Verify orders synced successfully
```

### Sync Failure Handling
```
1. Create order while offline
2. Go online, watch sync start
3. Kill internet during sync
4. Verify retry mechanism kicks in
5. Sync completes on next connectivity change
```

### Multi-Language Testing
```
1. Login screen → Change language dropdown
2. Verify UI updates to selected language
3. Navigate to Profile → Change preference
4. Restart app → Verify language persists
```

## Build & Run

### Prerequisites
```bash
flutter --version  # >= 3.10.0
dart --version     # >= 3.0.0
```

### Setup
```bash
# Get dependencies
flutter pub get

# Generate code (models, freezed, json)
flutter pub run build_runner build --delete-conflicting-outputs

# Run app
flutter run

# Build APK
flutter build apk --release

# Build Play Store Bundle
flutter build appbundle --release
```

## Key Files Reference

### Core
- `lib/core/network/api_client.dart` - HTTP client with retry logic
- `lib/core/network/connectivity_service.dart` - Network status monitoring
- `lib/core/di/injection.dart` - All Riverpod providers
- `lib/core/theme/app_theme.dart` - Material theme definition

### Database
- `lib/database/app_database.dart` - Drift database with all DAOs

### Authentication
- `lib/features/auth/presentation/providers/auth_provider.dart` - Auth state
- `lib/features/auth/data/repositories/auth_repository_impl.dart` - Auth logic
- `lib/features/auth/presentation/screens/login_screen.dart` - Login UI
- `lib/features/auth/presentation/screens/otp_screen.dart` - OTP verification

### Sync Engine (Critical)
- `lib/features/sync/data/sync_engine.dart` - Batch sync orchestration
- `lib/features/sync/presentation/providers/sync_provider.dart` - Sync state
- `lib/features/sync/presentation/widgets/sync_status_widget.dart` - Sync status UI

### Feature Modules
- `lib/features/mandi/presentation/screens/mandi_prices_screen.dart` - Market prices
- `lib/features/mandi/presentation/widgets/price_card.dart` - Price display
- `lib/features/orders/presentation/screens/orders_screen.dart` - Orders list
- `lib/features/home/presentation/screens/home_screen.dart` - Dashboard
- `lib/features/profile/presentation/screens/profile_screen.dart` - User profile

### Localization
- `lib/l10n/app_en.arb` - English strings
- `lib/l10n/app_hi.arb` - Hindi strings (हिंदी)
- `lib/l10n/app_mr.arb` - Marathi strings (मराठी)

## Error Handling

### Failure Types
```dart
ServerFailure          // HTTP errors (4xx, 5xx)
NetworkFailure         // Connection issues
TimeoutFailure         // Request timeouts
AuthFailure            // Authentication issues
CacheFailure           // Local storage errors
ValidationFailure      // Input validation
SyncFailure            // Sync operation errors
```

### Either Type Pattern
```dart
// Usage in repositories
Future<Either<Failure, OrderEntity>> createOrder(OrderEntity order) {
  // Returns Left(failure) on error, Right(order) on success
}

// Usage in UI
result.fold(
  (failure) => setState(() => _error = failure.message),
  (order) => setState(() => _order = order),
);
```

## State Management Patterns

### Auth Provider
```dart
// Check session on app launch
await authNotifier.checkSession();

// OTP flow
await authNotifier.requestOtp(phone);
await authNotifier.verifyOtp(phone, otp);

// Logout
await authNotifier.logout();
```

### Orders Provider
```dart
// Load user orders
final ordersState = ref.watch(ordersProvider(userId));

// Create order (local + sync queue)
await ordersNotifier.createOrder(order);

// Refresh from remote
await ordersNotifier.refresh();
```

### Sync Status Stream
```dart
// Watch sync progress
final syncStatus = ref.watch(syncStatusProvider);

syncStatus.whenData((status) {
  print('Pending: ${status.pendingCount}');
  print('Syncing: ${status.isSyncing}');
  print('Failed: ${status.failedItems.length}');
});
```

## Production Deployment Checklist

- [ ] Replace `baseUrl` in `ApiConstants` with production API
- [ ] Update app signing configuration in `android/app/build.gradle`
- [ ] Set correct Android/iOS bundle IDs
- [ ] Enable Firebase Crashlytics for error tracking
- [ ] Configure ProGuard rules for release build
- [ ] Test on multiple device sizes and OS versions
- [ ] Verify offline functionality thoroughly
- [ ] Test sync with poor network conditions
- [ ] Configure app signing for Play Store
- [ ] Set up continuous deployment pipeline
- [ ] Review all API error messages for user clarity
- [ ] Verify all languages display correctly

## Development Notes

### Adding New Features
1. Create feature folder under `lib/features/`
2. Structure: `data/` → `domain/` → `presentation/`
3. Add new Drift tables if needed
4. Create Riverpod providers for state
5. Build UI screens
6. Add localization strings to `.arb` files

### Modifying Database Schema
1. Update table definitions in `app_database.dart`
2. Increment `schemaVersion`
3. Run: `flutter pub run build_runner build`
4. Test migration path

### Adding Languages
1. Create new `.arb` file in `lib/l10n/`
2. Add same keys as `app_en.arb`
3. Update `supportedLocales` in `app_constants.dart`
4. Add to language selector dropdowns

## Troubleshooting

### Build Issues
```
flutter clean
flutter pub get
flutter pub run build_runner clean
flutter pub run build_runner build --delete-conflicting-outputs
```

### Database Issues
```
// Reset local database
final db = ref.read(appDatabaseProvider);
await db.deleteAllData();
```

### Sync Stuck
```
// Clear stuck sync items
final syncEngine = ref.read(syncEngineProvider);
await syncEngine.clearSyncedItems();
```

## Dependencies

Key dependencies included:
- `flutter_riverpod` - State management
- `drift` - Type-safe SQLite
- `dio` - HTTP client
- `go_router` - Navigation
- `intl` - Internationalization
- `hive` - NoSQL storage
- `flutter_secure_storage` - Encrypted storage
- `connectivity_plus` - Network status
- `uuid` - ID generation
- `json_annotation` - JSON serialization
- `cached_network_image` - Image caching
- `shimmer` - Loading placeholders

## License

Proprietary - Kheteebaadi Private Limited

## Support

For issues, feature requests, or questions:
- Create an issue on the development platform
- Contact the development team
- Check documentation first

---

**Last Updated**: March 2026
**Version**: 1.0.0
**Flutter SDK**: 3.10.0+
**Dart SDK**: 3.0.0+
