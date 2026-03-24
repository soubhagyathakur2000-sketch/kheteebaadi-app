import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import 'package:kheteebaadi/core/di/injection.dart';
import 'package:kheteebaadi/core/network/api_client.dart';
import 'package:kheteebaadi/core/network/network_info.dart';
import 'package:kheteebaadi/database/app_database.dart';
import 'package:kheteebaadi/features/crop_listing/data/datasources/crop_listing_local_datasource.dart';
import 'package:kheteebaadi/features/crop_listing/data/datasources/crop_listing_remote_datasource.dart';
import 'package:kheteebaadi/features/crop_listing/data/repositories/crop_listing_repository_impl.dart';
import 'package:kheteebaadi/features/crop_listing/domain/entities/crop_listing.dart';
import 'package:kheteebaadi/features/crop_listing/domain/repositories/crop_listing_repository.dart';
import 'package:kheteebaadi/features/sync/data/sync_engine.dart';

// Repository provider
final cropListingRepositoryProvider = Provider<CropListingRepository>((ref) {
  final database = getIt<AppDatabase>();
  final apiClient = getIt<ApiClient>();
  final networkInfo = getIt<NetworkInfo>();
  final syncEngine = getIt<SyncEngine>();

  final localDataSource = CropListingLocalDataSourceImpl(database: database);
  final remoteDataSource =
      CropListingRemoteDataSourceImpl(apiClient: apiClient);

  return CropListingRepositoryImpl(
    localDataSource: localDataSource,
    remoteDataSource: remoteDataSource,
    networkInfo: networkInfo,
    syncEngine: syncEngine,
    database: database,
  );
});

// User listings provider
final userListingsProvider =
    FutureProvider.family<List<CropListing>, String>((ref, userId) async {
  final repository = ref.watch(cropListingRepositoryProvider);
  final result = await repository.getListings(userId);
  return result.fold(
    (failure) => [],
    (listings) => listings,
  );
});

// Single listing provider
final cropListingByIdProvider =
    FutureProvider.family<CropListing?, String>((ref, listingId) async {
  final repository = ref.watch(cropListingRepositoryProvider);
  final result = await repository.getListingById(listingId);
  return result.fold(
    (failure) => null,
    (listing) => listing,
  );
});

// Form state class
class CropListingFormState {
  final String cropType;
  final String cropName;
  final double quantity;
  final double? expectedPrice;
  final String? description;
  final List<String> imagePaths;
  final bool isSubmitting;
  final String? error;
  final bool isOnline;

  const CropListingFormState({
    this.cropType = '',
    this.cropName = '',
    this.quantity = 0,
    this.expectedPrice,
    this.description,
    this.imagePaths = const [],
    this.isSubmitting = false,
    this.error,
    this.isOnline = true,
  });

  CropListingFormState copyWith({
    String? cropType,
    String? cropName,
    double? quantity,
    double? expectedPrice,
    String? description,
    List<String>? imagePaths,
    bool? isSubmitting,
    String? error,
    bool? isOnline,
  }) {
    return CropListingFormState(
      cropType: cropType ?? this.cropType,
      cropName: cropName ?? this.cropName,
      quantity: quantity ?? this.quantity,
      expectedPrice: expectedPrice ?? this.expectedPrice,
      description: description ?? this.description,
      imagePaths: imagePaths ?? this.imagePaths,
      isSubmitting: isSubmitting ?? this.isSubmitting,
      error: error,
      isOnline: isOnline ?? this.isOnline,
    );
  }

  bool get isValid =>
      cropType.isNotEmpty &&
      cropName.isNotEmpty &&
      quantity > 0 &&
      imagePaths.isNotEmpty;
}

// Form state notifier
class CropListingFormNotifier extends StateNotifier<CropListingFormState> {
  final CropListingRepository _repository;
  final String _userId;
  final String _villageId;
  final NetworkInfo _networkInfo;

  CropListingFormNotifier({
    required CropListingRepository repository,
    required String userId,
    required String villageId,
    required NetworkInfo networkInfo,
  })  : _repository = repository,
        _userId = userId,
        _villageId = villageId,
        _networkInfo = networkInfo,
        super(const CropListingFormState());

  void setCropType(String value) {
    state = state.copyWith(cropType: value);
  }

  void setCropName(String value) {
    state = state.copyWith(cropName: value);
  }

  void setQuantity(double value) {
    state = state.copyWith(quantity: value);
  }

  void setExpectedPrice(double? value) {
    state = state.copyWith(expectedPrice: value);
  }

  void setDescription(String? value) {
    state = state.copyWith(description: value);
  }

  void addImage(String imagePath) {
    final newPaths = [...state.imagePaths];
    if (newPaths.length < 3) {
      newPaths.add(imagePath);
      state = state.copyWith(imagePaths: newPaths);
    }
  }

  void removeImage(String imagePath) {
    final newPaths = state.imagePaths.where((p) => p != imagePath).toList();
    state = state.copyWith(imagePaths: newPaths);
  }

  void setField(String fieldName, dynamic value) {
    switch (fieldName) {
      case 'cropType':
        setCropType(value as String);
        break;
      case 'cropName':
        setCropName(value as String);
        break;
      case 'quantity':
        setQuantity(value as double);
        break;
      case 'expectedPrice':
        setExpectedPrice(value as double?);
        break;
      case 'description':
        setDescription(value as String?);
        break;
      case 'imagePaths':
        state = state.copyWith(imagePaths: value as List<String>);
        break;
    }
  }

  Future<String?> submit() async {
    if (!state.isValid) {
      state = state.copyWith(error: 'Please fill in all required fields');
      return null;
    }

    state = state.copyWith(isSubmitting: true, error: null);

    try {
      final isOnline = await _networkInfo.isConnected();
      state = state.copyWith(isOnline: isOnline);

      final listing = CropListing(
        id: const Uuid().v4(),
        userId: _userId,
        cropType: state.cropType,
        cropName: state.cropName,
        quantityQuintals: state.quantity,
        expectedPricePerQuintal: state.expectedPrice,
        description: state.description,
        imagePaths: state.imagePaths,
        status: isOnline ? CropListingStatus.synced : CropListingStatus.draft,
        villageId: _villageId,
        synced: isOnline,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      final result = await _repository.createListing(listing);

      return result.fold(
        (failure) {
          state = state.copyWith(
            isSubmitting: false,
            error: failure.message,
          );
          return null;
        },
        (createdListing) {
          state = const CropListingFormState();
          return createdListing.id;
        },
      );
    } catch (e) {
      state = state.copyWith(
        isSubmitting: false,
        error: 'Failed to create listing: ${e.toString()}',
      );
      return null;
    }
  }

  void reset() {
    state = const CropListingFormState();
  }
}

// Form notifier provider
final cropListingFormProvider =
    StateNotifierProvider.family<CropListingFormNotifier, CropListingFormState,
        ({String userId, String villageId})>((ref, params) {
  final repository = ref.watch(cropListingRepositoryProvider);
  final networkInfo = getIt<NetworkInfo>();

  return CropListingFormNotifier(
    repository: repository,
    userId: params.userId,
    villageId: params.villageId,
    networkInfo: networkInfo,
  );
});

// Unsynced listings provider
final unsyncedListingsProvider =
    FutureProvider<List<CropListing>>((ref) async {
  final repository = ref.watch(cropListingRepositoryProvider);
  final result = await repository.getUnsyncedListings();
  return result.fold(
    (failure) => [],
    (listings) => listings,
  );
});
