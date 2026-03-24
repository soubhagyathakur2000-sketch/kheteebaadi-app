import 'package:kheteebaadi/database/app_database.dart';
import 'package:kheteebaadi/features/store/data/models/product_model.dart';

abstract class StoreLocalDataSource {
  Future<void> cacheProducts(List<ProductModel> products);
  Future<void> cacheCategories(List<String> categories);
  Future<List<ProductModel>> getCachedProducts();
  Future<List<String>> getCachedCategories();
  Future<List<ProductModel>> getProductsByCategory(String category);
  Future<ProductModel?> getProductById(int id);
  Future<void> clearCache();
}

class StoreLocalDataSourceImpl implements StoreLocalDataSource {
  final AppDatabase database;

  StoreLocalDataSourceImpl({required this.database});

  @override
  Future<void> cacheProducts(List<ProductModel> products) async {
    await database.batch((batch) {
      batch.insertAllOnConflictUpdate(
        database.products,
        products.map((p) => p.toCompanion()).toList(),
      );
    });
  }

  @override
  Future<void> cacheCategories(List<String> categories) async {
    // Note: Categories are typically stored as part of products
    // This is a placeholder for if you decide to have a separate categories table
  }

  @override
  Future<List<ProductModel>> getCachedProducts() async {
    final entities = await database.products.select().get();
    return entities.map((e) => ProductModel.fromProductEntity(e)).toList();
  }

  @override
  Future<List<String>> getCachedCategories() async {
    final products = await getCachedProducts();
    final categories = <String>{};
    for (final product in products) {
      categories.add(product.category);
    }
    return categories.toList();
  }

  @override
  Future<List<ProductModel>> getProductsByCategory(String category) async {
    final query = database.products.select()
      ..where((tbl) => tbl.category.equals(category));
    final entities = await query.get();
    return entities.map((e) => ProductModel.fromProductEntity(e)).toList();
  }

  @override
  Future<ProductModel?> getProductById(int id) async {
    try {
      final entity = await (database.products.select()
            ..where((tbl) => tbl.id.equals(id)))
          .getSingleOrNull();
      return entity != null ? ProductModel.fromProductEntity(entity) : null;
    } catch (e) {
      return null;
    }
  }

  @override
  Future<void> clearCache() async {
    await database.products.delete().go();
  }
}
