import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:kheteebaadi/core/constants/app_constants.dart';
import 'package:kheteebaadi/features/auth/data/models/user_model.dart';

abstract class AuthLocalDataSource {
  Future<void> saveUser(UserModel user);
  Future<UserModel?> getUser();
  Future<void> saveTokens(String token, String refreshToken);
  Future<void> saveToken(String token);
  Future<String?> getToken();
  Future<String?> getRefreshToken();
  Future<void> clearAuth();
  Future<bool> hasValidSession();
}

class AuthLocalDataSourceImpl implements AuthLocalDataSource {
  final FlutterSecureStorage _secureStorage;
  final Box<dynamic> _box;

  static const String _tokenKey = 'auth_token';
  static const String _refreshTokenKey = 'refresh_token';
  static const String _userKey = 'current_user';

  AuthLocalDataSourceImpl({
    required FlutterSecureStorage secureStorage,
    required Box<dynamic> box,
  })  : _secureStorage = secureStorage,
        _box = box;

  @override
  Future<void> saveUser(UserModel user) async {
    await _box.put(_userKey, user.toJson());
  }

  @override
  Future<UserModel?> getUser() async {
    final userJson = _box.get(_userKey);
    if (userJson != null && userJson is Map) {
      try {
        return UserModel.fromJson(Map<String, dynamic>.from(userJson));
      } catch (e) {
        return null;
      }
    }
    return null;
  }

  @override
  Future<void> saveTokens(String token, String refreshToken) async {
    await _secureStorage.write(key: _tokenKey, value: token);
    await _secureStorage.write(key: _refreshTokenKey, value: refreshToken);
  }

  @override
  Future<void> saveToken(String token) async {
    await _secureStorage.write(key: _tokenKey, value: token);
  }

  @override
  Future<String?> getToken() async {
    return _secureStorage.read(key: _tokenKey);
  }

  @override
  Future<String?> getRefreshToken() async {
    return _secureStorage.read(key: _refreshTokenKey);
  }

  @override
  Future<void> clearAuth() async {
    await _secureStorage.delete(key: _tokenKey);
    await _secureStorage.delete(key: _refreshTokenKey);
    await _box.delete(_userKey);
  }

  @override
  Future<bool> hasValidSession() async {
    final token = await getToken();
    final user = await getUser();
    return token != null && token.isNotEmpty && user != null;
  }
}
