import 'dart:convert';
import 'package:uuid/uuid.dart';
import 'package:kheteebaadi/core/network/network_info.dart';
import 'package:kheteebaadi/core/utils/either.dart';
import 'package:kheteebaadi/core/utils/failure.dart';
import 'package:kheteebaadi/database/app_database.dart';
import 'package:kheteebaadi/features/crop_listing/data/datasources/crop_listing_local_datasource.dart';
import 'package:kheteebaadi/features/crop_listing/data/datasources/crop_listing_remote_datasource.dart';
import 'package:kheteebaadi/features/crop_listing/data/models/crop_listing_model.dart';
import 'package:kheteebaadi/features/crop_listing/domain/entities/crop_listing.dart';
import 'package:kheteebaadi/features/crop_listing/domain/repositories/crop_listing_repository.dart';
import 'package:kheteebaadi/features/sync/data/sync_engine.dart';

class CropListingRepositoryImpl implements CropListingRepository {
  final CropListingLocalDataSource _localDataSource;
  final CropListingRemoteDataSource _remoteDataSource;
  final NetworkInfo _networkInfo;
  final SyncEngine _syncEngine;
  final AppDatabase _database;

  CropListingRepositoryImpl({
    required CropListingLocalDataSource localDataSource,
    required CropListingRemoteDataSource remoteDataSource,
    required NetworkInfo networkInfo,
    required SyncEngine syncEngine,
    required AppDatabase database,
  })  : _localDataSource = localDataSource,
        _remoteDataSource = remoteDataSource,
        _networkInfo = networkInfo,
        _syncEngine = syncEngine,
        _database = database;

  @override
  Future<Either<Failure, List<CropListing>>> getListings(String userId) async {
    try {
      // Always try to get from local cache first
      final localListings = await _localDataSource.getUserListings(userId);

      final isConnected = await _networkInfo.isConnected();
      if (!isConnected) {
        return Right(localListings);
      }

      // Sync with remote if connected
      try {
        final remoteListings = await _remoteDataSource.getListings(userId);

        // Update local cache with remote data
        for (final listing in remoteListings) {
          await _localDataSource.updateListing(listing);
        }

        return Right(remoteListings);
      } catch (e) {
        // If remote fetch fails, return local data
        return Right(localListings);
      }
    } on Failure catch (e) {
      return Left(e);
    } catch (e) {
      return Left(
        CacheFailure(message: 'Failed to fetch listings: ${e.toString()}'),
      );
    }
  }

  @override
  Future<Either<Failure, CropListing>> getListingById(String id) async {
    try {
      // Try local first
      final localListing = await _localDataSource.getListingById(id);
      if (localListing != null) {
        return Right(localListing);
      }

      // If not in local and no connection, return error
      final isConnected = await _networkInfo.isConnected();
      if (!isConnected) {
        return Left(
          CacheFailure(message: 'Listing not found and no internet'),
        );
      }

      return Left(
        CacheFailure(message: 'Listing not found'),
      );
    } on Failure catch (e) {
      return Left(e);
    } catch (e) {
      return Left(
        CacheFailure(message: 'Failed to fetch listing: ${e.toString()}'),
      );
    }
  }

  @override
  Future<Either<Failure, CropListing>> createListing(
    CropListing listing,
  ) async {
    try {
      // Create model from entity
      final model = CropListingModel.fromEntity(listing);

      // Always save locally first
      await _localDataSource.insertListing(model);

      final isConnected = await _networkInfo.isConnected();

      if (isConnected) {
        // Try to sync immediately if connected
        try {
          final remoteModel = await _remoteDataSource.createListing(model);
          await _localDataSource.updateListing(remoteModel);
          await _localDataSource.updateListingStatus(
            remoteModel.id,
            CropListingStatus.synced,
          );
          return Right(remoteModel);
        } catch (e) {
          // If remote fails, queue for sync
          await _queueListingForSync(model);
          await _localDataSource.updateListingStatus(
            model.id,
            CropListingStatus.pendingSync,
          );
          return Right(model);
        }
      } else {
        // Queue for sync if offline
        await _queueListingForSync(model);
        await _localDataSource.updateListingStatus(
          model.id,
          CropListingStatus.pendingSync,
        );
        return Right(model);
      }
    } on Failure catch (e) {
      return Left(e);
    } catch (e) {
      return Left(
        ServerFailure(message: 'Failed to create listing: ${e.toString()}'),
      );
    }
  }

  @override
  Future<Either<Failure, void>> updateListingStatus(
    String id,
    CropListingStatus status,
  ) async {
    try {
      await _localDataSource.updateListingStatus(id, status);
      return const Right(null);
    } on Failure catch (e) {
      return Left(e);
    } catch (e) {
      return Left(
        CacheFailure(message: 'Failed to update status: ${e.toString()}'),
      );
    }
  }

  @override
  Future<Either<Failure, List<CropListing>>> getUnsyncedListings() async {
    try {
      final listings = await _localDataSource.getUnsyncedListings();
      return Right(listings);
    } on Failure catch (e) {
      return Left(e);
    } catch (e) {
      return Left(
        CacheFailure(message: 'Failed to fetch unsynced listings: ${e.toString()}'),
      );
    }
  }

  @override
  Future<Either<Failure, void>> uploadListingImages(
    String listingId,
    List<String> imagePaths,
  ) async {
    try {
      final isConnected = await _networkInfo.isConnected();
      if (!isConnected) {
        return Left(
          NetworkFailure(message: 'No internet connection'),
        );
      }

      await _remoteDataSource.uploadListingImages(listingId, imagePaths);
      return const Right(null);
    } on Failure catch (e) {
      return Left(e);
    } catch (e) {
      return Left(
        ServerFailure(message: 'Failed to upload images: ${e.toString()}'),
      );
    }
  }

  Future<void> _queueListingForSync(CropListingModel listing) async {
    final payload = {
      'id': listing.id,
      'user_id': listing.userId,
      'crop_type': listing.cropType,
      'crop_name': listing.cropName,
      'quantity_quintals': listing.quantityQuintals,
      'expected_price_per_quintal': listing.expectedPricePerQuintal,
      'description': listing.description,
      'image_paths': listing.imagePaths,
      'village_id': listing.villageId,
      'created_at': listing.createdAt.toIso8601String(),
      'updated_at': listing.updatedAt.toIso8601String(),
    };

    await _syncEngine.addPendingSync(
      entityType: 'crop_listing',
      entityId: listing.id,
      payload: payload,
      idempotencyKey: 'crop_listing_${listing.id}',
    );
  }
}
