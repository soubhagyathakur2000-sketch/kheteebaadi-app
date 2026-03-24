import 'package:kheteebaadi/features/store/domain/entities/cart_item.dart';
import 'package:kheteebaadi/database/app_database.dart';

class CartItemModel extends CartItem {
  CartItemModel({
    required super.id,
    required super.productId,
    required super.productName,
    required super.unitPrice,
    required super.quantity,
    required super.imageUrl,
    required super.addedAt,
  });

  factory CartItemModel.fromJson(Map<String, dynamic> json) {
    return CartItemModel(
      id: json['id'] as int,
      productId: json['product_id'] as int,
      productName: json['product_name'] as String,
      unitPrice: (json['unit_price'] as num).toDouble(),
      quantity: json['quantity'] as int,
      imageUrl: json['image_url'] as String? ?? '',
      addedAt: json['added_at'] != null
          ? DateTime.parse(json['added_at'] as String)
          : DateTime.now(),
    );
  }

  factory CartItemModel.fromEntity(CartItem cartItem) {
    return CartItemModel(
      id: cartItem.id,
      productId: cartItem.productId,
      productName: cartItem.productName,
      unitPrice: cartItem.unitPrice,
      quantity: cartItem.quantity,
      imageUrl: cartItem.imageUrl,
      addedAt: cartItem.addedAt,
    );
  }

  factory CartItemModel.fromCartItemEntity(CartItemEntity entity) {
    return CartItemModel(
      id: entity.id,
      productId: entity.productId,
      productName: entity.productName,
      unitPrice: entity.unitPrice,
      quantity: entity.quantity,
      imageUrl: entity.imageUrl,
      addedAt: entity.addedAt,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'product_id': productId,
      'product_name': productName,
      'unit_price': unitPrice,
      'quantity': quantity,
      'image_url': imageUrl,
      'added_at': addedAt.toIso8601String(),
    };
  }

  CartItemsCompanion toCompanion() {
    return CartItemsCompanion(
      id: drift.Value(id),
      productId: drift.Value(productId),
      productName: drift.Value(productName),
      unitPrice: drift.Value(unitPrice),
      quantity: drift.Value(quantity),
      imageUrl: drift.Value(imageUrl),
      addedAt: drift.Value(addedAt),
    );
  }

  CartItem toEntity() => this;
}
