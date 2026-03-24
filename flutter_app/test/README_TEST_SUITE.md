# Kheteebaadi App - Flutter Unit Test Suite

Complete unit test suite for the Kheteebaadi agricultural marketplace app.

## Test Files Overview

### 1. Test Helpers (`test/helpers/test_helpers.dart`)
Shared utilities for testing:
- **MockApiClient**: Simulates API client with failure scenarios
- **MockNetworkInfo**: Controls network connectivity state
- **TestCropListingFactory**: Factory for creating test CropListingModel instances
- **TestProductFactory**: Factory for creating test ProductModel instances
- **TestPaymentFactory**: Factory for creating test PaymentModel instances

### 2. Model Tests

#### `test/unit/models/crop_listing_model_test.dart` (13 KB)
Tests for CropListingModel serialization and conversion:
- **fromJson tests**: Complete data, null optional fields, missing keys
- **toJson round-trip**: Serialization/deserialization consistency
- **CropListingStatus.fromValue**: All 4 status values (draft, pendingSync, synced, sold)
- **fromDriftEntity tests**: Valid JSON, empty paths, malformed JSON handling
- **toCompanion tests**: Drift companion creation with proper field mapping
- **copyWith tests**: Immutable updates

#### `test/unit/models/payment_model_test.dart` (13 KB)
Tests for PaymentModel and payment status:
- **fromJson tests**: All fields, null optional fields, defaults (currency=INR, pollCount=0)
- **PaymentStatus.fromJson**: All 7 enum values (initiated, authorized, captured, failed, timeout, refundInitiated, refundCompleted)
- **Payment.isSuccessful**: True for captured and authorized
- **Payment.isFailed**: True for failed and timeout
- **Payment.isPending**: True for initiated and authorized
- **toJson round-trip**: Full serialization cycle

#### `test/unit/models/product_model_test.dart` (9.5 KB)
Tests for ProductModel and product data:
- **fromJson tests**: Complete data, null defaults (nameLocal, unit, imageUrl, description, stockQuantity, inStock, brand)
- **toJson round-trip**: Serialization consistency
- **fromEntity/toEntity**: Entity conversion
- **Minimal JSON handling**: All defaults applied correctly

### 3. Database Tests

#### `test/unit/database/app_database_test.dart` (28 KB)
Comprehensive database operations using in-memory Drift database:

**User Operations**:
- Insert and retrieve users
- Get user by phone
- Get all users
- Delete users

**Crop Listing Operations**:
- Insert and retrieve listings
- Verify listings returned in descending order by createdAt
- Update listing status
- Get unsynced listings (pending_sync + draft)

**Cart Operations**:
- Add items to cart
- Update item quantity
- Remove items from cart
- Clear all cart items
- Stream emits on changes

**Payment Operations**:
- Insert payment pending records
- Get payment by order ID
- Get payment by Razorpay order ID
- Update payment status
- Increment poll count

**PendingSync Operations**:
- Insert sync records
- Get pending items in ascending createdAt order
- Update sync status
- Increment retry count

**Product Operations**:
- Insert and retrieve products
- Search by name
- Search by nameLocal

**Cleanup**:
- deleteAllData clears all 9 tables

### 4. Sync Engine Tests

#### `test/unit/sync/sync_engine_test.dart` (7.5 KB)
Tests for background synchronization engine:
- **sync() method**:
  - Does nothing when already syncing
  - Does nothing when offline
  - Emits isSyncing true/false at stages
  - Handles API errors with retry count increment
  
- **addPendingSync() method**:
  - Creates records with UUID
  - Updates pending count
  - Uses idempotency key for deduplication

- **statusStream**:
  - Broadcast stream support
  - Emits SyncStatus objects
  - Status properties validation

- **SyncStatus**: Defaults and copyWith support
- **SyncFailureItem**: Stores failure details

### 5. Payment State Machine Tests

#### `test/unit/payment/payment_state_machine_test.dart` (9.4 KB)
Tests for payment status state transitions:

**Valid Transitions**:
- initiated → authorized, failed, timeout
- authorized → captured, failed
- captured → refundInitiated
- refundInitiated → refundCompleted
- timeout → initiated (retry)

**Invalid Transitions**:
- captured → initiated (backward)
- failed → any state (terminal)
- refundCompleted → any state (terminal)

**Happy Paths**:
- initiated → authorized → captured
- captured → refundInitiated → refundCompleted
- initiated → failed
- timeout and retry flow

**Edge Cases**:
- Same state identity transitions
- All enum values validation

### 6. Image Compression Service Tests

#### `test/unit/services/image_compression_service_test.dart` (11 KB)
Tests for image compression with quality management:

**Single Image Compression**:
- Correct quality parameter (70)
- Correct width parameter (800)
- JPEG format
- Failure handling
- Path return validation

**Re-compression**:
- Triggers when file > 300KB
- Uses lower quality (50)
- Deletes original file
- Returns re-compressed path

**Multiple Images**:
- Concurrent processing
- List of paths returned
- Handles empty list

**File Operations**:
- Delete compressed images
- Get file size in KB

**Constants Integration**:
- Uses AppConstants.imageQuality
- Uses AppConstants.maxImageWidth
- Re-compresses at maxImageSizeKb * 2

## Test Statistics

| File | Lines | Tests |
|------|-------|-------|
| test_helpers.dart | 171 | - |
| crop_listing_model_test.dart | 417 | 21 |
| payment_model_test.dart | 402 | 27 |
| product_model_test.dart | 306 | 17 |
| app_database_test.dart | 885 | 35 |
| sync_engine_test.dart | 230 | 13 |
| payment_state_machine_test.dart | 284 | 30 |
| image_compression_service_test.dart | 350 | 22 |
| **TOTAL** | **3,045** | **165+** |

## Running Tests

Run all tests:
```bash
flutter test
```

Run specific test file:
```bash
flutter test test/unit/models/crop_listing_model_test.dart
```

Run with coverage:
```bash
flutter test --coverage
```

Run specific test group:
```bash
flutter test test/unit/models/ -k "CropListingModel"
```

## Key Features

- **No External Mocks**: Uses manual mocks instead of mockito (not in dependencies)
- **In-Memory Database**: All database tests use Drift in-memory for isolation
- **Comprehensive Coverage**: Tests happy paths, error cases, edge cases, and state transitions
- **Self-Contained**: Each test file is independent and compilable
- **Clear Test Names**: Descriptive test names following given/when/then pattern
- **Factory Methods**: Convenient test data creation with customizable defaults

## Notes

- All tests use flutter_test framework
- Tests follow AAA (Arrange-Act-Assert) pattern
- Mock classes are self-implemented for simplicity
- Database tests use in-memory Drift for speed and isolation
- No external dependencies beyond flutter_test
