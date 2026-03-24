import 'package:dio/dio.dart';
import 'package:kheteebaadi/core/constants/api_constants.dart';
import 'package:kheteebaadi/core/network/api_client.dart';
import 'package:kheteebaadi/core/utils/failure.dart';
import 'package:kheteebaadi/features/mandi/data/models/mandi_price_model.dart';

abstract class MandiRemoteDataSource {
  Future<List<MandiPriceModel>> getMandiPrices(
    String regionId, {
    int page = 1,
    int limit = 20,
  });
  Future<List<MandiPriceModel>> searchCrops(String query);
  Future<Map<String, dynamic>> getMandiDetail(String mandiId);
}

class MandiRemoteDataSourceImpl implements MandiRemoteDataSource {
  final ApiClient _apiClient;

  MandiRemoteDataSourceImpl({required ApiClient apiClient})
      : _apiClient = apiClient;

  @override
  Future<List<MandiPriceModel>> getMandiPrices(
    String regionId, {
    int page = 1,
    int limit = 20,
  }) async {
    try {
      final response = await _apiClient.get(
        ApiConstants.mandiPricesEndpoint,
        queryParameters: {
          'region_id': regionId,
          'page': page,
          'limit': limit,
        },
      );

      if (response.statusCode != 200) {
        throw ServerFailure(
          message: 'Failed to fetch mandi prices',
          statusCode: response.statusCode,
        );
      }

      final data = response.data;
      if (data is! Map<String, dynamic>) {
        throw ServerFailure(message: 'Invalid response format');
      }

      final prices = data['prices'];
      if (prices is! List) {
        throw ServerFailure(message: 'Invalid prices data');
      }

      return prices
          .whereType<Map<String, dynamic>>()
          .map((json) => MandiPriceModel.fromJson(json))
          .toList();
    } on DioException catch (e) {
      throw _handleDioError(e);
    } catch (e) {
      if (e is Failure) rethrow;
      throw ServerFailure(message: e.toString());
    }
  }

  @override
  Future<List<MandiPriceModel>> searchCrops(String query) async {
    try {
      final response = await _apiClient.get(
        ApiConstants.searchCropsEndpoint,
        queryParameters: {'q': query},
      );

      if (response.statusCode != 200) {
        throw ServerFailure(
          message: 'Failed to search crops',
          statusCode: response.statusCode,
        );
      }

      final data = response.data;
      if (data is! Map<String, dynamic>) {
        throw ServerFailure(message: 'Invalid response format');
      }

      final results = data['results'];
      if (results is! List) {
        throw ServerFailure(message: 'Invalid search results');
      }

      return results
          .whereType<Map<String, dynamic>>()
          .map((json) => MandiPriceModel.fromJson(json))
          .toList();
    } on DioException catch (e) {
      throw _handleDioError(e);
    } catch (e) {
      if (e is Failure) rethrow;
      throw ServerFailure(message: e.toString());
    }
  }

  @override
  Future<Map<String, dynamic>> getMandiDetail(String mandiId) async {
    try {
      final response = await _apiClient.get(
        '${ApiConstants.mandiDetailEndpoint}/$mandiId',
      );

      if (response.statusCode != 200) {
        throw ServerFailure(
          message: 'Failed to fetch mandi details',
          statusCode: response.statusCode,
        );
      }

      final data = response.data;
      if (data is! Map<String, dynamic>) {
        throw ServerFailure(message: 'Invalid response format');
      }

      return data;
    } on DioException catch (e) {
      throw _handleDioError(e);
    } catch (e) {
      if (e is Failure) rethrow;
      throw ServerFailure(message: e.toString());
    }
  }

  Failure _handleDioError(DioException error) {
    switch (error.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.receiveTimeout:
      case DioExceptionType.sendTimeout:
        return TimeoutFailure(message: 'Request timeout');
      case DioExceptionType.badResponse:
        final statusCode = error.response?.statusCode;
        final message = error.response?.data?['message'] ?? 'Server error';
        return ServerFailure(
          message: message,
          statusCode: statusCode,
        );
      case DioExceptionType.connectionError:
        return NetworkFailure(message: 'Network error');
      default:
        return ServerFailure(message: error.message ?? 'Unknown error');
    }
  }
}
