import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:unila_helpdesk_frontend/core/models/user_models.dart';

class TokenStorage {
  TokenStorage({FlutterSecureStorage? storage})
      : _storage = storage ?? const FlutterSecureStorage();

  static const _tokenKey = 'auth_token';
  static const _tokenExpiresAtKey = 'auth_token_expires_at';
  static const _refreshTokenKey = 'refresh_token';
  static const _refreshTokenExpiresAtKey = 'refresh_token_expires_at';
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

  Future<DateTime?> readTokenExpiresAt() async {
    final raw = await _storage.read(key: _tokenExpiresAtKey);
    if (raw == null || raw.isEmpty) {
      return null;
    }
    return DateTime.tryParse(raw)?.toUtc();
  }

  Future<DateTime?> readRefreshTokenExpiresAt() async {
    final raw = await _storage.read(key: _refreshTokenExpiresAtKey);
    if (raw == null || raw.isEmpty) {
      return null;
    }
    return DateTime.tryParse(raw)?.toUtc();
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

  Future<void> saveTokenExpiresAt(DateTime? expiresAt) async {
    if (expiresAt == null) {
      await _storage.delete(key: _tokenExpiresAtKey);
      return;
    }
    await _storage.write(
      key: _tokenExpiresAtKey,
      value: expiresAt.toUtc().toIso8601String(),
    );
  }

  Future<void> saveRefreshToken(String token) async {
    if (token.isEmpty) {
      await clearRefreshToken();
      return;
    }
    await _storage.write(
      key: _refreshTokenKey,
      value: token,
    );
    if (kDebugMode) {
      debugPrint('[TokenStorage] save refresh token: len ${token.length}');
    }
  }

  Future<void> saveRefreshTokenExpiresAt(DateTime? expiresAt) async {
    if (expiresAt == null) {
      await _storage.delete(key: _refreshTokenExpiresAtKey);
      return;
    }
    await _storage.write(
      key: _refreshTokenExpiresAtKey,
      value: expiresAt.toUtc().toIso8601String(),
    );
  }

  Future<void> clearRefreshToken() async {
    await _storage.delete(key: _refreshTokenKey);
    await _storage.delete(key: _refreshTokenExpiresAtKey);
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
    await _storage.delete(key: _tokenExpiresAtKey);
    await _storage.delete(key: _refreshTokenKey);
    await _storage.delete(key: _refreshTokenExpiresAtKey);
    await _storage.delete(key: _userKey);
    if (kDebugMode) {
      debugPrint('[TokenStorage] clear tokens');
    }
  }

  Future<bool> hasActiveSession({bool requireStoredExpiry = false}) async {
    final token = await readToken();
    final user = await readUser();
    if (token == null || token.isEmpty || user == null) {
      return false;
    }

    final expiresAt = await readTokenExpiresAt();
    if (expiresAt == null) {
      if (requireStoredExpiry) {
        await clearToken();
        return false;
      }
      return true;
    }

    if (DateTime.now().toUtc().isAfter(expiresAt)) {
      await clearToken();
      return false;
    }
    return true;
  }
}
