import 'package:kheteebaadi/core/utils/either.dart';
import 'package:kheteebaadi/core/utils/failure.dart';
import 'package:kheteebaadi/features/crop_listing/domain/entities/crop_listing.dart';

abstract class CropListingRepository {
  Future<Either<Failure, List<CropListing>>> getListings(String userId);
  Future<Either<Failure, CropListing>> getListingById(String id);
  Future<Either<Failure, CropListing>> createListing(CropListing listing);
  Future<Either<Failure, void>> updateListingStatus(
    String id,
    CropListingStatus status,
  );
  Future<Either<Failure, List<CropListing>>> getUnsyncedListings();
  Future<Either<Failure, void>> uploadListingImages(
    String listingId,
    List<String> imagePaths,
  );
}
