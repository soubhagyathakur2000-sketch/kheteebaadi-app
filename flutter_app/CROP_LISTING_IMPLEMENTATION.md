# Crop Listing Feature Implementation - Phase 4

## Overview
Complete implementation of the Crop Listing feature for the Kheteebaadi Flutter app, following clean architecture with separation of concerns across domain, data, and presentation layers.

## Architecture

### 1. Domain Layer

#### Entities
- **`crop_listing.dart`** - Contains:
  - `CropListing` entity class with all crop listing properties
  - `CropListingStatus` enum (draft, pendingSync, synced, sold)
  - Status extension methods for display names and value conversion
  - `copyWith` method for immutable updates

#### Repositories
- **`crop_listing_repository.dart`** - Abstract repository defining:
  - `getListings(userId)` - Fetch user's crop listings
  - `getListingById(id)` - Get single listing by ID
  - `createListing(listing)` - Create new crop listing
  - `updateListingStatus(id, status)` - Update listing status
  - `getUnsyncedListings()` - Get offline-created listings
  - `uploadListingImages(listingId, paths)` - Upload crop photos

### 2. Data Layer

#### Models
- **`crop_listing_model.dart`** - Extends CropListing entity with:
  - `fromJson` factory for API deserialization
  - `fromEntity` factory for entity-to-model conversion
  - `fromDriftEntity` factory for Drift database conversion (handles JSON image paths)
  - `toJson` for API serialization
  - `toCompanion` for Drift insert/update operations
  - `copyWith` for model cloning

#### Local Data Source
- **`crop_listing_local_datasource.dart`** - Drift SQLite operations:
  - Save/update crop listings locally
  - Query user's listings with ordering
  - Status updates
  - Fetch unsynced listings (offline queue)
  - No network dependency - pure local operations

#### Remote Data Source
- **`crop_listing_remote_datasource.dart`** - API operations:
  - Create listing on server (POST)
  - Fetch user's listings from server (GET)
  - Multipart image upload with proper FormData handling
  - Error handling with DioException
  - Validates response structure before parsing

#### Repository Implementation
- **`crop_listing_repository_impl.dart`** - Implements CropListingRepository:
  - **Cache-first strategy**: Always reads from local DB first
  - **Smart sync**: Auto-syncs with remote when online
  - **Offline support**: Queues for sync via SyncEngine when offline
  - **Idempotent operations**: Uses unique idempotency keys
  - **Graceful degradation**: Returns local data if remote fetch fails
  - Properly converts entities through models at each layer

### 3. Presentation Layer

#### State Management
- **`crop_listing_provider.dart`** - Riverpod providers:
  - `cropListingRepositoryProvider` - Singleton repository instance
  - `userListingsProvider` - FutureProvider.family for user's listings
  - `cropListingByIdProvider` - FutureProvider.family for single listing
  - `cropListingFormProvider` - StateNotifierProvider.family for form state
  - `unsyncedListingsProvider` - FutureProvider for offline queue

#### Form State Notifier
- **`CropListingFormNotifier`** - Manages:
  - Form field state (cropType, cropName, quantity, price, description, images)
  - Form validation (all required fields present, at least 1 image)
  - Image management (add/remove, max 3 images)
  - Form submission with offline detection
  - Error handling and user feedback
  - Auto-reset on successful submission

#### Screens

##### 1. Crop Listing Screen
- **`crop_listing_screen.dart`** - Main form for creating listings:
  - Large, touch-friendly UI elements (min 48dp targets)
  - Image capture section:
    - Grid display of thumbnails (max 3)
    - Camera capture button
    - Gallery picker option
    - Image deletion with visual feedback
  - Crop type dropdown selector
  - Crop name text field with voice-to-text
  - Quantity stepper with increment/decrement buttons
  - Expected price input field
  - Description text area with voice-to-text
  - Offline indicator at top
  - Submit button with loading state
  - Color-coded UI following AppTheme
  - Speech-to-text integration for accessibility

##### 2. Listing Preview Screen
- **`listing_preview_screen.dart`** - Review before final submission:
  - Image carousel with page indicators
  - Grouped detail cards for information hierarchy
  - Status badge showing current listing state
  - Color-coded status indicators
  - Edit button to go back and modify
  - Confirm & Submit button for final submission
  - Empty and error states with helpful messaging
  - Beautiful card-based layout

##### 3. My Listings Screen
- **`my_listings_screen.dart`** - View all farmer's listings:
  - Grouped by status (Draft, Pending Sync, Published, Sold)
  - Pull-to-refresh for manual sync
  - Status badges with icons and colors
  - Quick stats (quantity, expected price, image count)
  - Relative timestamps (e.g., "2h ago")
  - Empty state with illustration
  - FAB for creating new listing
  - Error state with retry option
  - Large, low-literacy friendly design

## Features

### Offline Support
- All listings saved locally immediately
- Form state preserved during offline usage
- SyncEngine queues unsaved data for automatic sync
- Idempotency keys prevent duplicate submissions
- Graceful error handling with retry capability

### Image Management
- Up to 3 photos per listing
- Camera capture integration
- Gallery picker support
- Automatic compression via ImageCompressionService
- Multipart upload to server
- Visual thumbnail previews

### Accessibility
- Voice-to-text for crop name and description fields
- Large touch targets (48dp minimum)
- High contrast status colors
- Clear visual hierarchy
- Simple, icon-based interface design
- Works for low-literacy users

### Smart Sync
- Automatic sync when online
- Manual refresh via pull-to-refresh
- Shows sync status and pending count
- Batch processing via SyncEngine
- Exponential backoff retry logic
- Failed items tracked and retried

## Data Flow

### Create Listing Flow
```
User Input Form
    ↓
CropListingFormNotifier.submit()
    ↓
Create local CropListing entity
    ↓
Save to SQLite via LocalDataSource
    ↓
If Online:
  Try RemoteDataSource.createListing()
    ├─ Success → Update status to SYNCED
    └─ Failure → Queue for sync, status PENDING_SYNC
Else (Offline):
  Queue for sync via SyncEngine, status PENDING_SYNC
    ↓
Return listing ID to UI
```

### Offline Sync Flow
```
SyncEngine detects online connection
    ↓
Fetch pending items from database
    ↓
Batch items (max 50 per batch)
    ↓
POST to /sync/batch endpoint
    ↓
For each item:
  ├─ Success → Mark as SYNCED, remove from queue
  ├─ Permanent Error → Mark as FAILED, keep for review
  └─ Transient Error → Increment retry count, re-queue
    ↓
Update sync status stream with results
```

## Database Schema (Drift)

The `CropListings` table stores:
- `id` (String, Primary Key)
- `userId` (String)
- `cropType` (String)
- `cropName` (String)
- `quantityQuintals` (Real)
- `expectedPricePerQuintal` (Real, nullable)
- `description` (String, nullable)
- `imagePathsJson` (String, JSON array)
- `status` (String enum)
- `villageId` (String)
- `synced` (Boolean)
- `createdAt` (DateTime)
- `updatedAt` (DateTime)

## API Endpoints Used

- `POST /listings/create` - Create new listing
- `GET /listings` - Fetch user listings (query param: user_id)
- `POST /listings/upload` - Upload listing images (multipart)
- `POST /sync/batch` - Batch sync pending items

## Dependencies

- **flutter_riverpod** - State management
- **drift** - Local SQLite database
- **dio** - HTTP client
- **uuid** - Unique ID generation
- **json_annotation** - JSON serialization
- **speech_to_text** - Voice input
- **image_picker** - Gallery/camera access
- **custom services** - ImageCompressionService, CameraService

## Error Handling

- NetworkFailure for connectivity issues
- ServerFailure for API errors
- CacheFailure for database operations
- Form validation with user-friendly messages
- Try-catch blocks at repository boundaries
- User feedback via SnackBars
- Error states in UI with retry options

## Testing Considerations

Each layer can be tested independently:
- **Domain**: No dependencies, pure Dart
- **Data**: Mock API client and database
- **Presentation**: Mock providers with test values
- Forms: Test validation logic
- UI: Widget tests for interactions

## File Structure

```
lib/features/crop_listing/
├── domain/
│   ├── entities/
│   │   └── crop_listing.dart
│   └── repositories/
│       └── crop_listing_repository.dart
├── data/
│   ├── datasources/
│   │   ├── crop_listing_local_datasource.dart
│   │   └── crop_listing_remote_datasource.dart
│   ├── models/
│   │   └── crop_listing_model.dart
│   └── repositories/
│       └── crop_listing_repository_impl.dart
└── presentation/
    ├── providers/
    │   └── crop_listing_provider.dart
    └── screens/
        ├── crop_listing_screen.dart
        ├── listing_preview_screen.dart
        └── my_listings_screen.dart
```

## Integration Notes

To integrate into the app:

1. Add providers to main app providers file
2. Add screens to navigation/routing
3. Ensure SyncEngine is initialized in DI
4. Configure speech_to_text permissions in Android/iOS
5. Setup camera and gallery permissions
6. Add crop_listing feature to pubspec.yaml if modular

## Performance Optimizations

- FutureProvider caching with .family for per-user caching
- Batch sync operations
- Image compression before upload
- Lazy loading of listings
- Pull-to-refresh for manual sync
- Status updates don't refetch all data

## Future Enhancements

- Search/filter listings by crop type
- Advanced filters (date range, price range, location)
- Buyer inquiry notifications
- Rating/reviews system
- Analytics on listing views
- Crop price comparisons
- Scheduled listing posts
- Bulk upload multiple crops
