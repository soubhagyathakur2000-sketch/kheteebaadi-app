class OrderItem {
  final String cropId;
  final String cropName;
  final double quantity;
  final double unitPrice;
  final double totalPrice;

  const OrderItem({
    required this.cropId,
    required this.cropName,
    required this.quantity,
    required this.unitPrice,
    required this.totalPrice,
  });
}

class OrderEntity {
  final String id;
  final String userId;
  final List<OrderItem> items;
  final double totalAmount;
  final String status;
  final DateTime createdAt;
  final DateTime updatedAt;
  final bool synced;

  const OrderEntity({
    required this.id,
    required this.userId,
    required this.items,
    required this.totalAmount,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
    required this.synced,
  });
}
