import 'dart:convert';
import 'package:json_annotation/json_annotation.dart';
import 'package:drift/drift.dart' show Value;
import 'package:kheteebaadi/database/app_database.dart';
import 'package:kheteebaadi/features/crop_listing/domain/entities/crop_listing.dart';

part 'crop_listing_model.g.dart';

@JsonSerializable()
class CropListingModel extends CropListing {
  const CropListingModel({
    required super.id,
    required super.userId,
    required super.cropType,
    required super.cropName,
    required super.quantityQuintals,
    super.expectedPricePerQuintal,
    super.description,
    required super.imagePaths,
    required super.status,
    required super.villageId,
    required super.synced,
    required super.createdAt,
    required super.updatedAt,
  });

  factory CropListingModel.fromJson(Map<String, dynamic> json) =>
      _$CropListingModelFromJson(json);

  factory CropListingModel.fromEntity(CropListing entity) {
    return CropListingModel(
      id: entity.id,
      userId: entity.userId,
      cropType: entity.cropType,
      cropName: entity.cropName,
      quantityQuintals: entity.quantityQuintals,
      expectedPricePerQuintal: entity.expectedPricePerQuintal,
      description: entity.description,
      imagePaths: entity.imagePaths,
      status: entity.status,
      villageId: entity.villageId,
      synced: entity.synced,
      createdAt: entity.createdAt,
      updatedAt: entity.updatedAt,
    );
  }

  factory CropListingModel.fromDriftEntity(CropListingEntity entity) {
    final imagePathsJson = entity.imagePathsJson;
    List<String> imagePaths = [];
    try {
      if (imagePathsJson.isNotEmpty && imagePathsJson != '[]') {
        final decoded = jsonDecode(imagePathsJson);
        if (decoded is List) {
          imagePaths = decoded.cast<String>();
        }
      }
    } catch (e) {
      imagePaths = [];
    }

    return CropListingModel(
      id: entity.id,
      userId: entity.userId,
      cropType: entity.cropType,
      cropName: entity.cropName,
      quantityQuintals: entity.quantityQuintals,
      expectedPricePerQuintal: entity.expectedPricePerQuintal,
      description: entity.description,
      imagePaths: imagePaths,
      status: CropListingStatus.fromValue(entity.status),
      villageId: entity.villageId,
      synced: entity.synced,
      createdAt: entity.createdAt,
      updatedAt: entity.updatedAt,
    );
  }

  Map<String, dynamic> toJson() => _$CropListingModelToJson(this);

  CropListingsCompanion toCompanion() {
    return CropListingsCompanion(
      id: Value(id),
      userId: Value(userId),
      cropType: Value(cropType),
      cropName: Value(cropName),
      quantityQuintals: Value(quantityQuintals),
      expectedPricePerQuintal: expectedPricePerQuintal != null
          ? Value(expectedPricePerQuintal!)
          : const Value.absent(),
      description:
          description != null ? Value(description!) : const Value.absent(),
      imagePathsJson: Value(jsonEncode(imagePaths)),
      status: Value(status.value),
      villageId: Value(villageId),
      synced: Value(synced),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
    );
  }

  CropListingModel copyWith({
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
    return CropListingModel(
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
}
