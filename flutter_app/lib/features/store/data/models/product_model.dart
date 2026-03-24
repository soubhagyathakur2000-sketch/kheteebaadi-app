import 'package:kheteebaadi/features/store/domain/entities/product.dart';
import 'package:kheteebaadi/database/app_database.dart';

class ProductModel extends Product {
  ProductModel({
    required super.id,
    required super.name,
    required super.nameLocal,
    required super.category,
    required super.description,
    required super.price,
    required super.mrp,
    required super.unit,
    required super.imageUrl,
    required super.stockQuantity,
    required super.inStock,
    super.brand,
  });

  factory ProductModel.fromJson(Map<String, dynamic> json) {
    return ProductModel(
      id: json['id'] as int,
      name: json['name'] as String,
      nameLocal: json['name_local'] as String? ?? json['name'] as String,
      category: json['category'] as String,
      description: json['description'] as String? ?? '',
      price: (json['price'] as num).toDouble(),
      mrp: (json['mrp'] as num).toDouble(),
      unit: json['unit'] as String? ?? 'unit',
      imageUrl: json['image_url'] as String? ?? '',
      stockQuantity: json['stock_quantity'] as int? ?? 0,
      inStock: (json['in_stock'] as bool?) ?? true,
      brand: json['brand'] as String?,
    );
  }

  factory ProductModel.fromEntity(Product product) {
    return ProductModel(
      id: product.id,
      name: product.name,
      nameLocal: product.nameLocal,
      category: product.category,
      description: product.description,
      price: product.price,
      mrp: product.mrp,
      unit: product.unit,
      imageUrl: product.imageUrl,
      stockQuantity: product.stockQuantity,
      inStock: product.inStock,
      brand: product.brand,
    );
  }

  factory ProductModel.fromProductEntity(ProductEntity entity) {
    return ProductModel(
      id: entity.id,
      name: entity.name,
      nameLocal: entity.nameLocal,
      category: entity.category,
      description: entity.description,
      price: entity.price,
      mrp: entity.mrp,
      unit: entity.unit,
      imageUrl: entity.imageUrl,
      stockQuantity: entity.stockQuantity,
      inStock: entity.inStock,
      brand: entity.brand,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'name_local': nameLocal,
      'category': category,
      'description': description,
      'price': price,
      'mrp': mrp,
      'unit': unit,
      'image_url': imageUrl,
      'stock_quantity': stockQuantity,
      'in_stock': inStock,
      'brand': brand,
    };
  }

  ProductsCompanion toCompanion() {
    return ProductsCompanion(
      id: drift.Value(id),
      name: drift.Value(name),
      nameLocal: drift.Value(nameLocal),
      category: drift.Value(category),
      description: drift.Value(description),
      price: drift.Value(price),
      mrp: drift.Value(mrp),
      unit: drift.Value(unit),
      imageUrl: drift.Value(imageUrl),
      stockQuantity: drift.Value(stockQuantity),
      inStock: drift.Value(inStock),
      brand: drift.Value(brand),
    );
  }

  Product toEntity() => this;
}
