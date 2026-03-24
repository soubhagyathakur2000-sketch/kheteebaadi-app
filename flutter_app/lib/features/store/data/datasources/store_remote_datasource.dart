import 'package:kheteebaadi/core/network/api_client.dart';
import 'package:kheteebaadi/core/constants/api_constants.dart';
import 'package:kheteebaadi/features/store/data/models/product_model.dart';

abstract class StoreRemoteDataSource {
  Future<List<String>> getCategories();
  Future<List<ProductModel>> getProductsByCategory(String category);
  Future<List<ProductModel>> searchProducts(String query);
  Future<ProductModel> getProductById(int id);
}

class StoreRemoteDataSourceImpl implements StoreRemoteDataSource {
  final ApiClient apiClient;

  StoreRemoteDataSourceImpl({required this.apiClient});

  @override
  Future<List<String>> getCategories() async {
    try {
      final response = await apiClient.get(
        ApiConstants.storeCategoriesEndpoint,
      );
      final List<dynamic> data = response['data'] as List<dynamic>;
      return data.map((e) => e as String).toList();
    } catch (e) {
      throw Exception('Failed to fetch categories: $e');
    }
  }

  @override
  Future<List<ProductModel>> getProductsByCategory(String category) async {
    try {
      final response = await apiClient.get(
        ApiConstants.storeProductsEndpoint,
        queryParameters: {'category': category},
      );
      final List<dynamic> data = response['data'] as List<dynamic>;
      return data.map((e) => ProductModel.fromJson(e as Map<String, dynamic>)).toList();
    } catch (e) {
      throw Exception('Failed to fetch products: $e');
    }
  }

  @override
  Future<List<ProductModel>> searchProducts(String query) async {
    try {
      final response = await apiClient.get(
        ApiConstants.storeProductsEndpoint,
        queryParameters: {'search': query},
      );
      final List<dynamic> data = response['data'] as List<dynamic>;
      return data.map((e) => ProductModel.fromJson(e as Map<String, dynamic>)).toList();
    } catch (e) {
      throw Exception('Failed to search products: $e');
    }
  }

  @override
  Future<ProductModel> getProductById(int id) async {
    try {
      final response = await apiClient.get(
        ApiConstants.storeProductDetailEndpoint.replaceFirst('{id}', id.toString()),
      );
      return ProductModel.fromJson(response['data'] as Map<String, dynamic>);
    } catch (e) {
      throw Exception('Failed to fetch product: $e');
    }
  }
}
