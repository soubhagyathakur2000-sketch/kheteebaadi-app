import 'package:json_annotation/json_annotation.dart';
import 'package:kheteebaadi/features/auth/domain/entities/user_entity.dart';

part 'user_model.g.dart';

@JsonSerializable()
class UserModel extends UserEntity {
  const UserModel({
    required super.id,
    required super.name,
    required super.phone,
    required super.villageId,
    required super.languagePref,
    required super.avatarUrl,
    required super.token,
    required super.refreshToken,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) =>
      _$UserModelFromJson(json);

  Map<String, dynamic> toJson() => _$UserModelToJson(this);

  UserModel copyWith({
    String? id,
    String? name,
    String? phone,
    String? villageId,
    String? languagePref,
    String? avatarUrl,
    String? token,
    String? refreshToken,
  }) {
    return UserModel(
      id: id ?? this.id,
      name: name ?? this.name,
      phone: phone ?? this.phone,
      villageId: villageId ?? this.villageId,
      languagePref: languagePref ?? this.languagePref,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      token: token ?? this.token,
      refreshToken: refreshToken ?? this.refreshToken,
    );
  }
}
