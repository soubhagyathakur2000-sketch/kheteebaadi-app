class MandiPriceEntity {
  final String id;
  final String cropName;
  final String? cropNameLocal;
  final double pricePerQuintal;
  final String mandiName;
  final String mandiId;
  final String regionId;
  final DateTime updatedAt;
  final String unit;
  final double? priceChange;

  const MandiPriceEntity({
    required this.id,
    required this.cropName,
    this.cropNameLocal,
    required this.pricePerQuintal,
    required this.mandiName,
    required this.mandiId,
    required this.regionId,
    required this.updatedAt,
    required this.unit,
    this.priceChange,
  });
}
