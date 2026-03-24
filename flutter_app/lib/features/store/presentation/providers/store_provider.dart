import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kheteebaadi/core/network/api_client.dart';
import 'package:kheteebaadi/database/app_database.dart';
import 'package:kheteebaadi/features/store/domain/entities/product.dart';
import 'package:kheteebaadi/features/store/data/datasources/store_remote_datasource.dart';
import 'package:kheteebaadi/features/store/data/datasources/store_local_datasource.dart';
import 'package:kheteebaadi/features/store/data/repositories/store_repository_impl.dart';
import 'package:kheteebaadi/features/store/domain/repositories/store_repository.dart';

// Database provider
final appDatabaseProvider = Provider((ref) {
  return AppDatabase();
});

// API Client provider
final apiClientProvider = Provider((ref) {
  return ApiClient();
});

// Remote datasource provider
final storeRemoteDataSourceProvider = Provider((ref) {
  return StoreRemoteDataSourceImpl(
    apiClient: ref.watch(apiClientProvider),
  );
});

// Local datasource provider
final storeLocalDataSourceProvider = Provider((ref) {
  return StoreLocalDataSourceImpl(
    database: ref.watch(appDatabaseProvider),
  );
});

// Repository provider
final storeRepositoryProvider = Provider<StoreRepository>((ref) {
  return StoreRepositoryImpl(
    remoteDataSource: ref.watch(storeRemoteDataSourceProvider),
    localDataSource: ref.watch(storeLocalDataSourceProvider),
  );
});

// Categories provider
final categoriesProvider = FutureProvider<List<String>>((ref) async {
  final repository = ref.watch(storeRepositoryProvider);
  return repository.getCategories();
});

// Products by category provider
final productsByCategoryProvider =
    FutureProvider.family<List<Product>, String>((ref, category) async {
  final repository = ref.watch(storeRepositoryProvider);
  return repository.getProductsByCategory(category);
});

// Product detail provider
final productDetailProvider =
    FutureProvider.family<Product, int>((ref, id) async {
  final repository = ref.watch(storeRepositoryProvider);
  return repository.getProductById(id);
});

// Search products provider
final searchProductsProvider =
    FutureProvider.family<List<Product>, String>((ref, query) async {
  if (query.isEmpty) {
    return [];
  }
  final repository = ref.watch(storeRepositoryProvider);
  return repository.searchProducts(query);
});
