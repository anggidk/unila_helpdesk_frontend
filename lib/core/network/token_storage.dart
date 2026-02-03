import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:unila_helpdesk_frontend/core/models/user_models.dart';

class TokenStorage {
  TokenStorage({FlutterSecureStorage? storage})
      : _storage = storage ?? const FlutterSecureStorage();

  static const _tokenKey = 'auth_token';
  static const _refreshTokenKey = 'refresh_token';
  static const _userKey = 'auth_user';

  final FlutterSecureStorage _storage;

  Future<String?> readToken() async {
    final token = await _storage.read(key: _tokenKey);
    if (kDebugMode) {
      debugPrint(
        '[TokenStorage] read token: ${token == null ? 'null' : 'len ${token.length}'}',
      );
    }
    return token;
  }

  Future<String?> readRefreshToken() async {
    final token = await _storage.read(key: _refreshTokenKey);
    if (kDebugMode) {
      debugPrint(
        '[TokenStorage] read refresh token: ${token == null ? 'null' : 'len ${token.length}'}',
      );
    }
    return token;
  }

  Future<UserProfile?> readUser() async {
    final raw = await _storage.read(key: _userKey);
    if (raw == null || raw.isEmpty) {
      return null;
    }
    try {
      final decoded = jsonDecode(raw);
      if (decoded is Map<String, dynamic>) {
        return UserProfile.fromJson(decoded);
      }
    } catch (_) {
      // Ignore invalid stored user payload.
    }
    return null;
  }

  Future<void> saveToken(String token) async {
    await _storage.write(
      key: _tokenKey,
      value: token,
    );
    if (kDebugMode) {
      debugPrint('[TokenStorage] save token: len ${token.length}');
    }
  }

  Future<void> saveRefreshToken(String token) async {
    await _storage.write(
      key: _refreshTokenKey,
      value: token,
    );
    if (kDebugMode) {
      debugPrint('[TokenStorage] save refresh token: len ${token.length}');
    }
  }

  Future<void> saveUser(UserProfile user) async {
    final raw = jsonEncode(user.toJson());
    await _storage.write(
      key: _userKey,
      value: raw,
    );
    if (kDebugMode) {
      debugPrint('[TokenStorage] save user: ${user.role.name}');
    }
  }

  Future<void> clearToken() async {
    await _storage.delete(key: _tokenKey);
    await _storage.delete(key: _refreshTokenKey);
    await _storage.delete(key: _userKey);
    if (kDebugMode) {
      debugPrint('[TokenStorage] clear tokens');
    }
  }
}
