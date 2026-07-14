import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'dart:convert';

import 'package:flutter/foundation.dart';

import '../../features/auth/data/auth_models.dart';

class TokenStorage {
  TokenStorage() : _storage = const FlutterSecureStorage();

  static const String _tokenKey = 'auth_token';
  static const String _userKey = 'auth_user';

  final FlutterSecureStorage _storage;

  Future<void> saveToken(String token) async {
    if (kDebugMode) {
      final previousToken = await _storage.read(key: _tokenKey);
      debugPrint(
        '[AuthStorage] saveToken old=${_maskToken(previousToken)} new=${_maskToken(token)}',
      );
    }
    await _storage.write(key: _tokenKey, value: token);
  }

  Future<void> saveUser(AuthUser user) async {
    if (kDebugMode) {
      debugPrint(
        '[AuthStorage] saveUser user=${user.email} role=${user.role} expiresAt=${user.expiresAt?.toUtc().toIso8601String()}',
      );
    }
    await _storage.write(key: _userKey, value: jsonEncode(user.toJson()));
  }

  Future<String?> getToken() async {
    final token = await _storage.read(key: _tokenKey);
    if (kDebugMode) {
      debugPrint('[AuthStorage] getToken stored=${_maskToken(token)}');
    }
    return token;
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
    if (kDebugMode) {
      debugPrint('[AuthStorage] deleteToken');
    }
    await Future.wait([
      _storage.delete(key: _tokenKey),
      _storage.delete(key: _userKey),
    ]);
  }

  String _maskToken(String? token) {
    if (token == null || token.isEmpty) {
      return '<empty>';
    }

    if (token.length <= 16) {
      return '$token(len=${token.length})';
    }

    return '${token.substring(0, 12)}...${token.substring(token.length - 8)}(len=${token.length})';
  }
}
