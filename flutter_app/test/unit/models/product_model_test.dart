import 'package:flutter_test/flutter_test.dart';
import 'package:kheteebaadi/features/store/data/models/product_model.dart';

void main() {
  group('ProductModel', () {
    group('fromJson', () {
      test('should create instance from complete JSON data', () {
        final json = {
          'id': 1,
          'name': 'Urea Fertilizer',
          'name_local': 'यूरिया खाद',
          'category': 'Fertilizer',
          'description': '46% nitrogen content',
          'price': 150.0,
          'mrp': 200.0,
          'unit': 'bag',
          'image_url': 'https://example.com/image.jpg',
          'stock_quantity': 100,
          'in_stock': true,
          'brand': 'Agro',
        };

        final model = ProductModel.fromJson(json);

        expect(model.id, 1);
        expect(model.name, 'Urea Fertilizer');
        expect(model.nameLocal, 'यूरिया खाद');
        expect(model.category, 'Fertilizer');
        expect(model.description, '46% nitrogen content');
        expect(model.price, 150.0);
        expect(model.mrp, 200.0);
        expect(model.unit, 'bag');
        expect(model.imageUrl, 'https://example.com/image.jpg');
        expect(model.stockQuantity, 100);
        expect(model.inStock, true);
        expect(model.brand, 'Agro');
      });

      test('should use name as nameLocal when nameLocal is null', () {
        final json = {
          'id': 2,
          'name': 'DAP Fertilizer',
          'category': 'Fertilizer',
          'description': 'Diammonium phosphate',
          'price': 500.0,
          'mrp': 600.0,
          'unit': 'kg',
          'stock_quantity': 50,
          'in_stock': true,
        };

        final model = ProductModel.fromJson(json);

        expect(model.nameLocal, 'DAP Fertilizer');
      });

      test('should default unit to "unit" when null', () {
        final json = {
          'id': 3,
          'name': 'Pesticide',
          'name_local': 'कीटनाशक',
          'category': 'Pesticide',
          'price': 250.0,
          'mrp': 300.0,
          'stock_quantity': 20,
          'in_stock': true,
        };

        final model = ProductModel.fromJson(json);

        expect(model.unit, 'unit');
      });

      test('should default imageUrl to empty string when null', () {
        final json = {
          'id': 4,
          'name': 'Seeds',
          'name_local': 'बीज',
          'category': 'Seeds',
          'price': 100.0,
          'mrp': 150.0,
          'unit': 'pack',
          'stock_quantity': 200,
          'in_stock': true,
        };

        final model = ProductModel.fromJson(json);

        expect(model.imageUrl, '');
      });

      test('should default description to empty string when null', () {
        final json = {
          'id': 5,
          'name': 'Compost',
          'name_local': 'खाद',
          'category': 'Fertilizer',
          'price': 50.0,
          'mrp': 75.0,
          'unit': 'bag',
          'stock_quantity': 300,
          'in_stock': true,
        };

        final model = ProductModel.fromJson(json);

        expect(model.description, '');
      });

      test('should default stockQuantity to 0 when null', () {
        final json = {
          'id': 6,
          'name': 'Fungicide',
          'name_local': 'फफूंदनाशी',
          'category': 'Pesticide',
          'description': 'Prevents fungal diseases',
          'price': 300.0,
          'mrp': 400.0,
          'unit': 'liter',
          'in_stock': true,
        };

        final model = ProductModel.fromJson(json);

        expect(model.stockQuantity, 0);
      });

      test('should default inStock to true when null', () {
        final json = {
          'id': 7,
          'name': 'Herbicide',
          'name_local': 'शाकनाशी',
          'category': 'Pesticide',
          'price': 200.0,
          'mrp': 250.0,
          'unit': 'liter',
          'stock_quantity': 10,
        };

        final model = ProductModel.fromJson(json);

        expect(model.inStock, true);
      });

      test('should handle numeric values correctly', () {
        final json = {
          'id': 8,
          'name': 'Product',
          'name_local': 'उत्पाद',
          'category': 'Category',
          'price': 99,
          'mrp': 150,
          'unit': 'unit',
          'stock_quantity': 5,
          'in_stock': false,
        };

        final model = ProductModel.fromJson(json);

        expect(model.price, 99.0);
        expect(model.mrp, 150.0);
        expect(model.inStock, false);
      });
    });

    group('toJson and round-trip', () {
      test('should convert to JSON and back with all fields', () {
        final original = ProductModel(
          id: 1,
          name: 'Urea Fertilizer',
          nameLocal: 'यूरिया खाद',
          category: 'Fertilizer',
          description: '46% nitrogen content',
          price: 150.0,
          mrp: 200.0,
          unit: 'bag',
          imageUrl: 'https://example.com/image.jpg',
          stockQuantity: 100,
          inStock: true,
          brand: 'Agro',
        );

        final json = original.toJson();
        final restored = ProductModel.fromJson(json);

        expect(restored.id, original.id);
        expect(restored.name, original.name);
        expect(restored.nameLocal, original.nameLocal);
        expect(restored.category, original.category);
        expect(restored.description, original.description);
        expect(restored.price, original.price);
        expect(restored.mrp, original.mrp);
        expect(restored.unit, original.unit);
        expect(restored.imageUrl, original.imageUrl);
        expect(restored.stockQuantity, original.stockQuantity);
        expect(restored.inStock, original.inStock);
        expect(restored.brand, original.brand);
      });

      test('should handle null optional fields in round-trip', () {
        final original = ProductModel(
          id: 2,
          name: 'DAP',
          nameLocal: 'डीएपी',
          category: 'Fertilizer',
          description: '',
          price: 500.0,
          mrp: 600.0,
          unit: 'unit',
          imageUrl: '',
          stockQuantity: 0,
          inStock: true,
          brand: null,
        );

        final json = original.toJson();
        final restored = ProductModel.fromJson(json);

        expect(restored.brand, null);
        expect(restored.description, '');
        expect(restored.imageUrl, '');
      });
    });

    group('fromEntity', () {
      test('should create ProductModel from Product entity', () {
        final entity = ProductModel(
          id: 1,
          name: 'Urea',
          nameLocal: 'यूरिया',
          category: 'Fertilizer',
          description: 'Nitrogen fertilizer',
          price: 150.0,
          mrp: 200.0,
          unit: 'bag',
          imageUrl: 'https://example.com/image.jpg',
          stockQuantity: 50,
          inStock: true,
          brand: 'TestBrand',
        );

        final model = ProductModel.fromEntity(entity);

        expect(model.id, entity.id);
        expect(model.name, entity.name);
        expect(model.nameLocal, entity.nameLocal);
        expect(model.category, entity.category);
        expect(model.description, entity.description);
        expect(model.price, entity.price);
        expect(model.mrp, entity.mrp);
        expect(model.unit, entity.unit);
        expect(model.imageUrl, entity.imageUrl);
        expect(model.stockQuantity, entity.stockQuantity);
        expect(model.inStock, entity.inStock);
        expect(model.brand, entity.brand);
      });
    });

    group('toEntity', () {
      test('should convert ProductModel to Product entity', () {
        final model = ProductModel(
          id: 1,
          name: 'Urea',
          nameLocal: 'यूरिया',
          category: 'Fertilizer',
          description: 'Nitrogen fertilizer',
          price: 150.0,
          mrp: 200.0,
          unit: 'bag',
          imageUrl: 'https://example.com/image.jpg',
          stockQuantity: 50,
          inStock: true,
          brand: 'TestBrand',
        );

        final entity = model.toEntity();

        expect(entity.id, model.id);
        expect(entity.name, model.name);
        expect(entity.nameLocal, model.nameLocal);
        expect(entity.category, model.category);
        expect(entity.description, model.description);
        expect(entity.price, model.price);
        expect(entity.mrp, model.mrp);
        expect(entity.unit, model.unit);
        expect(entity.imageUrl, model.imageUrl);
        expect(entity.stockQuantity, model.stockQuantity);
        expect(entity.inStock, model.inStock);
        expect(entity.brand, model.brand);
      });
    });

    group('fromJson defaults', () {
      test('should apply all defaults correctly for minimal JSON', () {
        final json = {
          'id': 10,
          'name': 'Minimal Product',
          'category': 'TestCategory',
          'price': 100.0,
          'mrp': 150.0,
        };

        final model = ProductModel.fromJson(json);

        expect(model.id, 10);
        expect(model.name, 'Minimal Product');
        expect(model.nameLocal, 'Minimal Product');
        expect(model.category, 'TestCategory');
        expect(model.description, '');
        expect(model.price, 100.0);
        expect(model.mrp, 150.0);
        expect(model.unit, 'unit');
        expect(model.imageUrl, '');
        expect(model.stockQuantity, 0);
        expect(model.inStock, true);
        expect(model.brand, null);
      });
    });
  });
}
