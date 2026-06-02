import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'dart:convert';

import '../../features/auth/data/auth_models.dart';

class TokenStorage {
  TokenStorage() : _storage = const FlutterSecureStorage();

  static const String _tokenKey = 'auth_token';
  static const String _userKey = 'auth_user';

  final FlutterSecureStorage _storage;

  Future<void> saveToken(String token) async {
    await _storage.write(key: _tokenKey, value: token);
  }

  Future<void> saveUser(AuthUser user) async {
    await _storage.write(key: _userKey, value: jsonEncode(user.toJson()));
  }

  Future<String?> getToken() async {
    return _storage.read(key: _tokenKey);
  }

  Future<AuthUser?> getUser() async {
    final value = await _storage.read(key: _userKey);
    if (value == null || value.isEmpty) {
      return null;
    }

    final json = jsonDecode(value);
    return json is Map<String, dynamic> ? AuthUser.fromJson(json) : null;
  }

  Future<void> deleteToken() async {
    await Future.wait([
      _storage.delete(key: _tokenKey),
      _storage.delete(key: _userKey),
    ]);
  }
}
