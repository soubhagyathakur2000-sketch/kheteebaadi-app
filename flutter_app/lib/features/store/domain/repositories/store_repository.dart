import 'package:kheteebaadi/features/store/domain/entities/product.dart';

abstract class StoreRepository {
  Future<List<String>> getCategories();
  Future<List<Product>> getProductsByCategory(String category);
  Future<List<Product>> searchProducts(String query);
  Future<Product> getProductById(int id);
}
