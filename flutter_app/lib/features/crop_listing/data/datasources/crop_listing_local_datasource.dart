import 'package:drift/drift.dart';
import 'package:kheteebaadi/database/app_database.dart';
import 'package:kheteebaadi/features/crop_listing/data/models/crop_listing_model.dart';
import 'package:kheteebaadi/features/crop_listing/domain/entities/crop_listing.dart';

abstract class CropListingLocalDataSource {
  Future<List<CropListingModel>> getUserListings(String userId);
  Future<CropListingModel?> getListingById(String id);
  Future<void> insertListing(CropListingModel listing);
  Future<void> updateListing(CropListingModel listing);
  Future<void> updateListingStatus(String id, CropListingStatus status);
  Future<List<CropListingModel>> getUnsyncedListings();
}

class CropListingLocalDataSourceImpl implements CropListingLocalDataSource {
  final AppDatabase _database;

  CropListingLocalDataSourceImpl({required AppDatabase database})
      : _database = database;

  @override
  Future<List<CropListingModel>> getUserListings(String userId) async {
    final entities = await _database.getUserListings(userId);
    return entities.map((e) => CropListingModel.fromDriftEntity(e)).toList();
  }

  @override
  Future<CropListingModel?> getListingById(String id) async {
    final entity = await _database.getCropListingById(id);
    return entity != null ? CropListingModel.fromDriftEntity(entity) : null;
  }

  @override
  Future<void> insertListing(CropListingModel listing) async {
    await _database.insertCropListing(listing.toCompanion());
  }

  @override
  Future<void> updateListing(CropListingModel listing) async {
    await _database.insertCropListing(listing.toCompanion());
  }

  @override
  Future<void> updateListingStatus(String id, CropListingStatus status) async {
    await _database.updateCropListingStatus(
      id,
      status.value,
      synced: status == CropListingStatus.synced,
    );
  }

  @override
  Future<List<CropListingModel>> getUnsyncedListings() async {
    final entities = await _database.getUnsyncedListings();
    return entities.map((e) => CropListingModel.fromDriftEntity(e)).toList();
  }
}
