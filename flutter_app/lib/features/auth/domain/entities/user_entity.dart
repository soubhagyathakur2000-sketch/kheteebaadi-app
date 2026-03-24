class UserEntity {
  final String id;
  final String name;
  final String phone;
  final String villageId;
  final String languagePref;
  final String? avatarUrl;
  final String token;
  final String refreshToken;

  const UserEntity({
    required this.id,
    required this.name,
    required this.phone,
    required this.villageId,
    required this.languagePref,
    this.avatarUrl,
    required this.token,
    required this.refreshToken,
  });
}
