import 'dart:convert';
import 'package:json_annotation/json_annotation.dart';
import 'package:kheteebaadi/features/orders/domain/entities/order_entity.dart';

part 'order_model.g.dart';

@JsonSerializable()
class OrderItemModel {
  final String cropId;
  final String cropName;
  final double quantity;
  final double unitPrice;
  final double totalPrice;

  OrderItemModel({
    required this.cropId,
    required this.cropName,
    required this.quantity,
    required this.unitPrice,
    required this.totalPrice,
  });

  factory OrderItemModel.fromJson(Map<String, dynamic> json) =>
      _$OrderItemModelFromJson(json);

  Map<String, dynamic> toJson() => _$OrderItemModelToJson(this);

  OrderItem toEntity() => OrderItem(
        cropId: cropId,
        cropName: cropName,
        quantity: quantity,
        unitPrice: unitPrice,
        totalPrice: totalPrice,
      );
}

@JsonSerializable()
class OrderModel extends OrderEntity {
  const OrderModel({
    required super.id,
    required super.userId,
    required super.items,
    required super.totalAmount,
    required super.status,
    required super.createdAt,
    required super.updatedAt,
    required super.synced,
  });

  factory OrderModel.fromJson(Map<String, dynamic> json) =>
      _$OrderModelFromJson(json);

  Map<String, dynamic> toJson() => _$OrderModelToJson(this);

  OrderModel copyWith({
    String? id,
    String? userId,
    List<OrderItem>? items,
    double? totalAmount,
    String? status,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? synced,
  }) {
    return OrderModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      items: items ?? this.items,
      totalAmount: totalAmount ?? this.totalAmount,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      synced: synced ?? this.synced,
    );
  }

  static OrderModel fromDatabaseJson(String itemsJson, String id, String userId,
      double totalAmount, String status, DateTime createdAt, DateTime updatedAt, bool synced) {
    final List<dynamic> decoded = jsonDecode(itemsJson);
    final items = decoded
        .map((item) => OrderItem(
              cropId: item['cropId'],
              cropName: item['cropName'],
              quantity: (item['quantity'] as num).toDouble(),
              unitPrice: (item['unitPrice'] as num).toDouble(),
              totalPrice: (item['totalPrice'] as num).toDouble(),
            ))
        .toList();

    return OrderModel(
      id: id,
      userId: userId,
      items: items,
      totalAmount: totalAmount,
      status: status,
      createdAt: createdAt,
      updatedAt: updatedAt,
      synced: synced,
    );
  }

  static String itemsToJson(List<OrderItem> items) {
    return jsonEncode(
      items
          .map((item) => {
                'cropId': item.cropId,
                'cropName': item.cropName,
                'quantity': item.quantity,
                'unitPrice': item.unitPrice,
                'totalPrice': item.totalPrice,
              })
          .toList(),
    );
  }
}
