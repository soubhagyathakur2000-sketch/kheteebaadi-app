import 'package:dio/dio.dart';
import 'package:kheteebaadi/core/constants/api_constants.dart';
import 'package:kheteebaadi/core/network/api_client.dart';
import 'package:kheteebaadi/core/utils/failure.dart';
import 'package:kheteebaadi/features/crop_listing/data/models/crop_listing_model.dart';
import 'package:kheteebaadi/features/crop_listing/domain/entities/crop_listing.dart';

abstract class CropListingRemoteDataSource {
  Future<CropListingModel> createListing(CropListingModel listing);
  Future<List<CropListingModel>> getListings(String userId);
  Future<void> uploadListingImages(String listingId, List<String> imagePaths);
}

class CropListingRemoteDataSourceImpl implements CropListingRemoteDataSource {
  final ApiClient _apiClient;

  CropListingRemoteDataSourceImpl({required ApiClient apiClient})
      : _apiClient = apiClient;

  @override
  Future<CropListingModel> createListing(CropListingModel listing) async {
    try {
      final payload = {
        'user_id': listing.userId,
        'crop_type': listing.cropType,
        'crop_name': listing.cropName,
        'quantity_quintals': listing.quantityQuintals,
        'expected_price_per_quintal': listing.expectedPricePerQuintal,
        'description': listing.description,
        'village_id': listing.villageId,
        'image_paths': listing.imagePaths,
      };

      final response = await _apiClient.post(
        ApiConstants.createListingEndpoint,
        data: payload,
      );

      if (response.statusCode != 200 && response.statusCode != 201) {
        throw ServerFailure(
          message: 'Failed to create listing: ${response.statusCode}',
        );
      }

      if (response.data is! Map<String, dynamic>) {
        throw ServerFailure(message: 'Invalid response format');
      }

      final responseData = response.data as Map<String, dynamic>;
      final listingData = responseData['data'] as Map<String, dynamic>?;

      if (listingData == null) {
        throw ServerFailure(message: 'No listing data in response');
      }

      return CropListingModel.fromJson({
        ...listingData,
        'image_paths': listingData['image_paths'] ?? [],
      });
    } on DioException catch (e) {
      throw ServerFailure(
        message: 'Network error: ${e.message}',
      );
    } catch (e) {
      throw ServerFailure(
        message: 'Failed to create listing: ${e.toString()}',
      );
    }
  }

  @override
  Future<List<CropListingModel>> getListings(String userId) async {
    try {
      final response = await _apiClient.get(
        ApiConstants.getListingsEndpoint,
        queryParameters: {'user_id': userId},
      );

      if (response.statusCode != 200) {
        throw ServerFailure(
          message: 'Failed to fetch listings: ${response.statusCode}',
        );
      }

      if (response.data is! Map<String, dynamic>) {
        throw ServerFailure(message: 'Invalid response format');
      }

      final responseData = response.data as Map<String, dynamic>;
      final listingsData = responseData['data'] as List?;

      if (listingsData == null) {
        return [];
      }

      return listingsData
          .whereType<Map<String, dynamic>>()
          .map((data) => CropListingModel.fromJson({
                ...data,
                'image_paths': data['image_paths'] ?? [],
              }))
          .toList();
    } on DioException catch (e) {
      throw ServerFailure(
        message: 'Network error: ${e.message}',
      );
    } catch (e) {
      throw ServerFailure(
        message: 'Failed to fetch listings: ${e.toString()}',
      );
    }
  }

  @override
  Future<void> uploadListingImages(
    String listingId,
    List<String> imagePaths,
  ) async {
    try {
      final formData = FormData();
      formData.fields.add(MapEntry('listing_id', listingId));

      for (int i = 0; i < imagePaths.length; i++) {
        final imagePath = imagePaths[i];
        try {
          formData.files.add(
            MapEntry(
              'images',
              await MultipartFile.fromFile(
                imagePath,
                filename: 'listing_${listingId}_image_$i.jpg',
              ),
            ),
          );
        } catch (e) {
          throw ServerFailure(
            message: 'Failed to prepare image $i: ${e.toString()}',
          );
        }
      }

      final response = await _apiClient.post(
        ApiConstants.uploadListingImageEndpoint,
        data: formData,
      );

      if (response.statusCode != 200 && response.statusCode != 201) {
        throw ServerFailure(
          message: 'Failed to upload images: ${response.statusCode}',
        );
      }
    } on DioException catch (e) {
      throw ServerFailure(
        message: 'Network error during upload: ${e.message}',
      );
    } catch (e) {
      throw ServerFailure(
        message: 'Failed to upload images: ${e.toString()}',
      );
    }
  }
}
