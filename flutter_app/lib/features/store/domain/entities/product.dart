class Product {
  final int id;
  final String name;
  final String nameLocal;
  final String category;
  final String description;
  final double price;
  final double mrp;
  final String unit;
  final String imageUrl;
  final int stockQuantity;
  final bool inStock;
  final String? brand;

  Product({
    required this.id,
    required this.name,
    required this.nameLocal,
    required this.category,
    required this.description,
    required this.price,
    required this.mrp,
    required this.unit,
    required this.imageUrl,
    required this.stockQuantity,
    required this.inStock,
    this.brand,
  });

  bool get isDiscounted => mrp > price;
  double get discountPercentage => isDiscounted ? ((mrp - price) / mrp * 100) : 0;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Product &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          name == other.name &&
          price == other.price;

  @override
  int get hashCode => id.hashCode ^ name.hashCode ^ price.hashCode;
}
