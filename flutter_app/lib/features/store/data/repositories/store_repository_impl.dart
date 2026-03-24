import 'package:kheteebaadi/features/store/domain/entities/product.dart';
import 'package:kheteebaadi/features/store/domain/repositories/store_repository.dart';
import 'package:kheteebaadi/features/store/data/datasources/store_remote_datasource.dart';
import 'package:kheteebaadi/features/store/data/datasources/store_local_datasource.dart';

class StoreRepositoryImpl implements StoreRepository {
  final StoreRemoteDataSource remoteDataSource;
  final StoreLocalDataSource localDataSource;

  StoreRepositoryImpl({
    required this.remoteDataSource,
    required this.localDataSource,
  });

  @override
  Future<List<String>> getCategories() async {
    try {
      // Try to fetch from API
      final categories = await remoteDataSource.getCategories();
      await localDataSource.cacheCategories(categories);
      return categories;
    } catch (e) {
      // Fall back to cached categories
      try {
        return await localDataSource.getCachedCategories();
      } catch (cacheError) {
        throw Exception('Failed to fetch categories: $e');
      }
    }
  }

  @override
  Future<List<Product>> getProductsByCategory(String category) async {
    try {
      // Try to fetch from API
      final products = await remoteDataSource.getProductsByCategory(category);
      await localDataSource.cacheProducts(products);
      return products;
    } catch (e) {
      // Fall back to cached products
      try {
        return await localDataSource.getProductsByCategory(category);
      } catch (cacheError) {
        throw Exception('Failed to fetch products: $e');
      }
    }
  }

  @override
  Future<List<Product>> searchProducts(String query) async {
    try {
      // Search is primarily API-driven
      return await remoteDataSource.searchProducts(query);
    } catch (e) {
      // Fallback: search in cached products locally
      try {
        final cachedProducts = await localDataSource.getCachedProducts();
        return cachedProducts
            .where((p) =>
                p.name.toLowerCase().contains(query.toLowerCase()) ||
                p.nameLocal.toLowerCase().contains(query.toLowerCase()) ||
                p.description.toLowerCase().contains(query.toLowerCase()))
            .toList();
      } catch (cacheError) {
        throw Exception('Failed to search products: $e');
      }
    }
  }

  @override
  Future<Product> getProductById(int id) async {
    try {
      // Try cache first
      final cached = await localDataSource.getProductById(id);
      if (cached != null) {
        return cached;
      }

      // Fetch from API if not in cache
      final product = await remoteDataSource.getProductById(id);
      await localDataSource.cacheProducts([product]);
      return product;
    } catch (e) {
      throw Exception('Failed to fetch product: $e');
    }
  }
}
