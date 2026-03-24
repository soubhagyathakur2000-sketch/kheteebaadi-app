import 'package:json_annotation/json_annotation.dart';
import 'package:kheteebaadi/features/mandi/domain/entities/mandi_price_entity.dart';

part 'mandi_price_model.g.dart';

@JsonSerializable()
class MandiPriceModel extends MandiPriceEntity {
  const MandiPriceModel({
    required super.id,
    required super.cropName,
    super.cropNameLocal,
    required super.pricePerQuintal,
    required super.mandiName,
    required super.mandiId,
    required super.regionId,
    required super.updatedAt,
    required super.unit,
    super.priceChange,
  });

  factory MandiPriceModel.fromJson(Map<String, dynamic> json) =>
      _$MandiPriceModelFromJson(json);

  Map<String, dynamic> toJson() => _$MandiPriceModelToJson(this);

  MandiPriceModel copyWith({
    String? id,
    String? cropName,
    String? cropNameLocal,
    double? pricePerQuintal,
    String? mandiName,
    String? mandiId,
    String? regionId,
    DateTime? updatedAt,
    String? unit,
    double? priceChange,
  }) {
    return MandiPriceModel(
      id: id ?? this.id,
      cropName: cropName ?? this.cropName,
      cropNameLocal: cropNameLocal ?? this.cropNameLocal,
      pricePerQuintal: pricePerQuintal ?? this.pricePerQuintal,
      mandiName: mandiName ?? this.mandiName,
      mandiId: mandiId ?? this.mandiId,
      regionId: regionId ?? this.regionId,
      updatedAt: updatedAt ?? this.updatedAt,
      unit: unit ?? this.unit,
      priceChange: priceChange ?? this.priceChange,
    );
  }
}
