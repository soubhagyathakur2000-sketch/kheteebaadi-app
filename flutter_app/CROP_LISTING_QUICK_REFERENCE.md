# Crop Listing Feature - Quick Reference

## File Locations

### Domain Layer
```
lib/features/crop_listing/domain/
├── entities/crop_listing.dart          (CropListing, CropListingStatus enum)
└── repositories/crop_listing_repository.dart  (Abstract interface)
```

### Data Layer
```
lib/features/crop_listing/data/
├── datasources/
│   ├── crop_listing_local_datasource.dart     (SQLite operations)
│   └── crop_listing_remote_datasource.dart    (API operations)
├── models/
│   └── crop_listing_model.dart         (JSON serialization, Drift conversion)
└── repositories/
    └── crop_listing_repository_impl.dart      (Cache-first sync logic)
```

### Presentation Layer
```
lib/features/crop_listing/presentation/
├── providers/crop_listing_provider.dart       (Riverpod providers & form state)
└── screens/
    ├── crop_listing_screen.dart        (Form to create listing)
    ├── listing_preview_screen.dart     (Review before submit)
    └── my_listings_screen.dart         (View all listings)
```

## Key Classes

### Entities
- **`CropListing`** - Main domain entity
- **`CropListingStatus`** - Enum: draft, pendingSync, synced, sold

### Models
- **`CropListingModel`** - Extends CropListing with JSON serialization

### Providers
- **`cropListingRepositoryProvider`** - Repository singleton
- **`userListingsProvider(userId)`** - User's listings (cached)
- **`cropListingByIdProvider(id)`** - Single listing (cached)
- **`cropListingFormProvider(userId, villageId)`** - Form state
- **`unsyncedListingsProvider`** - Offline queue

### Notifiers
- **`CropListingFormNotifier`** - Manages form state and submission

## Common Usage Patterns

### Using the Form Provider
```dart
// Get form state
final formState = ref.watch(cropListingFormProvider(
  (userId: userId, villageId: villageId),
));

// Update fields
ref.read(cropListingFormProvider(
  (userId: userId, villageId: villageId),
).notifier).setCropName('Rice');

// Submit
final listingId = await ref.read(cropListingFormProvider(
  (userId: userId, villageId: villageId),
).notifier).submit();
```

### Fetching User Listings
```dart
final listings = ref.watch(userListingsProvider(userId));
listings.whenData((list) {
  // list is List<CropListing>
});
```

### Refreshing Data
```dart
ref.refresh(userListingsProvider(userId));
```

## UI Components

### CropListingScreen (Create/Edit)
- Image capture (camera + gallery)
- Crop type dropdown
- Quantity stepper
- Text fields with voice-to-text
- Offline indicator
- Submit button with loading state

### ListingPreviewScreen (Review)
- Image carousel
- Grouped detail cards
- Status badge
- Edit/Confirm buttons

### MyListingsScreen (List View)
- Grouped by status
- Pull-to-refresh
- Status icons/colors
- Empty state
- FAB to create new

## Integration Points

### Required DI Setup
- `AppDatabase` - Must be available in getIt
- `ApiClient` - Must be available in getIt
- `NetworkInfo` - Must be available in getIt
- `SyncEngine` - Must be available in getIt
- `CameraService` - Must be available in getIt
- `ImageCompressionService` - Must be available in getIt

### Navigation
```dart
// Go to form
Navigator.push(context, MaterialPageRoute(
  builder: (_) => CropListingScreen(
    userId: userId,
    villageId: villageId,
  ),
));

// Go to preview
Navigator.push(context, MaterialPageRoute(
  builder: (_) => ListingPreviewScreen(
    listingId: listingId,
    userId: userId,
  ),
));

// Go to my listings
Navigator.push(context, MaterialPageRoute(
  builder: (_) => MyListingsScreen(
    userId: userId,
    villageId: villageId,
  ),
));
```

## API Contract

### Create Listing
```
POST /api/v1/listings/create
Body: {
  "user_id": "string",
  "crop_type": "string",
  "crop_name": "string",
  "quantity_quintals": number,
  "expected_price_per_quintal": number (optional),
  "description": "string (optional)",
  "village_id": "string",
  "image_paths": ["string"]
}
Response: {
  "data": {
    "id": "string",
    "user_id": "string",
    "crop_type": "string",
    "crop_name": "string",
    "quantity_quintals": number,
    "expected_price_per_quintal": number,
    "description": "string",
    "village_id": "string",
    "image_paths": ["string"],
    "status": "synced",
    "synced": true,
    "created_at": "ISO8601",
    "updated_at": "ISO8601"
  }
}
```

### Get Listings
```
GET /api/v1/listings?user_id=xxx
Response: {
  "data": [
    { ...listing... }
  ]
}
```

### Upload Images
```
POST /api/v1/listings/upload
Content-Type: multipart/form-data
Body:
  listing_id: "string"
  images: [File, File, File]
```

### Batch Sync
```
POST /api/v1/sync/batch
Body: {
  "items": [
    {
      "id": "string",
      "entity_type": "crop_listing",
      "entity_id": "string",
      "payload": { ...data... },
      "idempotency_key": "string"
    }
  ]
}
Response: {
  "results": [
    {
      "id": "string",
      "success": boolean,
      "error": "string (optional)"
    }
  ]
}
```

## Status Flow

```
DRAFT
  ↓ (User submits offline)
PENDING_SYNC
  ↓ (SyncEngine syncs when online)
SYNCED
  ↓ (Buyer purchases)
SOLD
```

## Database Queries

All handled via AppDatabase methods:
- `getUserListings(userId)` - List user's crops
- `getCropListingById(id)` - Get single listing
- `insertCropListing(companion)` - Save new/update
- `updateCropListingStatus(id, status)` - Change status
- `getUnsyncedListings()` - Get offline queue

## Offline Behavior

1. User creates listing → Saved locally as DRAFT
2. Form submitted → Status → PENDING_SYNC, queued for sync
3. When online → SyncEngine sends to API
4. Server confirms → Status → SYNCED
5. Network error → Stays PENDING_SYNC, auto-retries

## Error Handling

### Form Errors
- All displayed as SnackBar with error message
- Form state includes error field
- User can retry submission

### Image Upload Errors
- Shown in dialog with option to retry
- Compression errors caught gracefully
- File access errors handled

### Network Errors
- Offline indicator shown at top
- Data queued for later sync
- No data loss - saved locally

### Sync Errors
- Logged with reason
- Automatic retry with exponential backoff
- Manual refresh available via pull-to-refresh

## Testing Strategy

### Unit Tests
- CropListingStatus enum parsing
- Form validation logic
- Date formatting utilities
- Status color/icon mapping

### Widget Tests
- CropListingScreen form interactions
- Image addition/removal
- Quantity stepper
- Voice-to-text button state

### Integration Tests
- Full create → preview → submit flow
- Offline sync flow
- Pull-to-refresh behavior

## Performance Tips

1. Use `.family` modifiers for per-user caching
2. Don't unnecessarily refresh listings
3. Images are compressed before upload
4. Batch operations reduce API calls
5. Pull-to-refresh only on user action

## Common Issues & Solutions

### Images not saving
- Check ImageCompressionService configuration
- Verify file permissions granted
- Check disk space availability

### Offline sync not working
- Ensure SyncEngine is initialized
- Check NetworkInfo implementation
- Verify API endpoint is correct

### Form state not persisting
- Ensure form provider is family-based
- Check that repository is singleton
- Verify database queries work

### Status not updating
- Check updateCropListingStatus implementation
- Verify database write operations
- Confirm sync updates status correctly
