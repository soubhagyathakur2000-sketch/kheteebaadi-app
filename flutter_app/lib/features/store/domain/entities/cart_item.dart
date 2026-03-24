class CartItem {
  final int id;
  final int productId;
  final String productName;
  final double unitPrice;
  final int quantity;
  final String imageUrl;
  final DateTime addedAt;

  CartItem({
    required this.id,
    required this.productId,
    required this.productName,
    required this.unitPrice,
    required this.quantity,
    required this.imageUrl,
    required this.addedAt,
  });

  double get totalPrice => unitPrice * quantity;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CartItem &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          productId == other.productId;

  @override
  int get hashCode => id.hashCode ^ productId.hashCode;
}
