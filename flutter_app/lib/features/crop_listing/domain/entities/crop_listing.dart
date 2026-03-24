enum CropListingStatus {
  draft,
  pendingSync,
  synced,
  sold,
}

extension CropListingStatusExtension on CropListingStatus {
  String get displayName {
    switch (this) {
      case CropListingStatus.draft:
        return 'Draft';
      case CropListingStatus.pendingSync:
        return 'Pending Sync';
      case CropListingStatus.synced:
        return 'Published';
      case CropListingStatus.sold:
        return 'Sold';
    }
  }

  String get value {
    switch (this) {
      case CropListingStatus.draft:
        return 'draft';
      case CropListingStatus.pendingSync:
        return 'pending_sync';
      case CropListingStatus.synced:
        return 'synced';
      case CropListingStatus.sold:
        return 'sold';
    }
  }

  static CropListingStatus fromValue(String value) {
    switch (value.toLowerCase()) {
      case 'draft':
        return CropListingStatus.draft;
      case 'pending_sync':
        return CropListingStatus.pendingSync;
      case 'synced':
        return CropListingStatus.synced;
      case 'sold':
        return CropListingStatus.sold;
      default:
        return CropListingStatus.draft;
    }
  }
}

class CropListing {
  final String id;
  final String userId;
  final String cropType;
  final String cropName;
  final double quantityQuintals;
  final double? expectedPricePerQuintal;
  final String? description;
  final List<String> imagePaths;
  final CropListingStatus status;
  final String villageId;
  final bool synced;
  final DateTime createdAt;
  final DateTime updatedAt;

  const CropListing({
    required this.id,
    required this.userId,
    required this.cropType,
    required this.cropName,
    required this.quantityQuintals,
    this.expectedPricePerQuintal,
    this.description,
    required this.imagePaths,
    required this.status,
    required this.villageId,
    required this.synced,
    required this.createdAt,
    required this.updatedAt,
  });

  CropListing copyWith({
    String? id,
    String? userId,
    String? cropType,
    String? cropName,
    double? quantityQuintals,
    double? expectedPricePerQuintal,
    String? description,
    List<String>? imagePaths,
    CropListingStatus? status,
    String? villageId,
    bool? synced,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return CropListing(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      cropType: cropType ?? this.cropType,
      cropName: cropName ?? this.cropName,
      quantityQuintals: quantityQuintals ?? this.quantityQuintals,
      expectedPricePerQuintal:
          expectedPricePerQuintal ?? this.expectedPricePerQuintal,
      description: description ?? this.description,
      imagePaths: imagePaths ?? this.imagePaths,
      status: status ?? this.status,
      villageId: villageId ?? this.villageId,
      synced: synced ?? this.synced,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  String toString() => 'CropListing(id: $id, cropName: $cropName, '
      'quantityQuintals: $quantityQuintals, status: $status)';
}
