import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:unila_helpdesk_frontend/core/config/api_config.dart';
import 'package:unila_helpdesk_frontend/core/models/user_models.dart';
import 'package:unila_helpdesk_frontend/core/network/api_endpoints.dart';
import 'package:unila_helpdesk_frontend/core/network/token_storage.dart';

class ApiResponse<T> {
  ApiResponse({this.data, this.error});

  final T? data;
  final ApiError? error;

  bool get isSuccess => error == null;
}

class ApiError {
  ApiError({required this.message, this.statusCode});

  final String message;
  final int? statusCode;
}

class ApiClient {
  ApiClient({required this.baseUrl, http.Client? client})
      : _client = client ?? http.Client();

  final String baseUrl;
  final http.Client _client;
  String? _authToken;
  Completer<bool>? _refreshCompleter;

  void setAuthToken(String? token) {
    _authToken = token;
  }

  Future<void> loadAuthToken() async {
    _authToken = await TokenStorage().readToken();
  }

  Uri buildUri(String path, [Map<String, String>? query]) {
    if (baseUrl.isEmpty) {
      throw StateError('API_BASE_URL belum di-set. Jalankan dengan --dart-define=API_BASE_URL=...');
    }
    return Uri.parse(baseUrl).replace(path: path, queryParameters: query);
  }

  Map<String, String> _headers() {
    final headers = <String, String>{'Content-Type': 'application/json'};
    headers['X-Client-Type'] = kIsWeb ? 'web' : 'mobile';
    if (_authToken != null && _authToken!.isNotEmpty) {
      headers['Authorization'] = 'Bearer $_authToken';
    }
    return headers;
  }

  Future<ApiResponse<Map<String, dynamic>>> get(
    String path, {
    Map<String, String>? query,
  }) async {
    return _sendJson(
      () => _client.get(buildUri(path, query), headers: _headers()),
    );
  }

  Future<ApiResponse<String>> getRaw(
    String path, {
    Map<String, String>? query,
  }) async {
    try {
      final response = await _client
          .get(buildUri(path, query), headers: _headers())
          .timeout(ApiConfig.timeout);
      if (response.statusCode >= 200 && response.statusCode < 300) {
        return ApiResponse(data: response.body);
      }
      return ApiResponse(
        error: ApiError(
          message: 'Request failed',
          statusCode: response.statusCode,
        ),
      );
    } catch (error) {
      return ApiResponse(error: ApiError(message: error.toString()));
    }
  }

  Future<ApiResponse<Map<String, dynamic>>> post(
    String path, {
    Map<String, dynamic>? body,
  }) async {
    return _sendJson(
      () => _client.post(
        buildUri(path),
        headers: _headers(),
        body: jsonEncode(body ?? {}),
      ),
    );
  }

  Future<ApiResponse<Map<String, dynamic>>> put(
    String path, {
    Map<String, dynamic>? body,
  }) async {
    return _sendJson(
      () => _client.put(
        buildUri(path),
        headers: _headers(),
        body: jsonEncode(body ?? {}),
      ),
    );
  }

  Future<ApiResponse<Map<String, dynamic>>> patch(
    String path, {
    Map<String, dynamic>? body,
  }) async {
    return _sendJson(
      () => _client.patch(
        buildUri(path),
        headers: _headers(),
        body: jsonEncode(body ?? {}),
      ),
    );
  }

  Future<ApiResponse<Map<String, dynamic>>> delete(String path) async {
    return _sendJson(
      () => _client.delete(buildUri(path), headers: _headers()),
    );
  }

  Future<ApiResponse<Map<String, dynamic>>> _sendJson(
    Future<http.Response> Function() request, {
    bool retryOnUnauthorized = true,
  }) async {
    try {
      final response = await request().timeout(ApiConfig.timeout);
      if (response.statusCode == 401 && retryOnUnauthorized) {
        final refreshed = await _refreshAccessToken();
        if (refreshed) {
          return _sendJson(request, retryOnUnauthorized: false);
        }
      }
      return _parseResponse(response);
    } catch (error) {
      return ApiResponse(error: ApiError(message: error.toString()));
    }
  }

  Future<bool> _refreshAccessToken() async {
    if (_refreshCompleter != null) {
      return _refreshCompleter!.future;
    }
    final completer = Completer<bool>();
    _refreshCompleter = completer;
    try {
      final refreshToken = await TokenStorage().readRefreshToken();
      if (refreshToken == null || refreshToken.isEmpty) {
        completer.complete(false);
        return completer.future;
      }
      final response = await _client
          .post(
            buildUri(ApiEndpoints.refresh),
            headers: _headers(),
            body: jsonEncode({'refresh_token': refreshToken}),
          )
          .timeout(ApiConfig.timeout);
      final parsed = _parseResponse(response);
      final data = parsed.data?['data'];
      if (!parsed.isSuccess || data is! Map<String, dynamic>) {
        await TokenStorage().clearToken();
        setAuthToken(null);
        completer.complete(false);
        return completer.future;
      }
      final newToken = data['token']?.toString() ?? '';
      final newRefreshToken = data['refreshToken']?.toString() ?? '';
      final userJson = data['user'];
      if (newToken.isNotEmpty) {
        setAuthToken(newToken);
        await TokenStorage().saveToken(newToken);
      }
      if (newRefreshToken.isNotEmpty) {
        await TokenStorage().saveRefreshToken(newRefreshToken);
      }
      if (userJson is Map<String, dynamic>) {
        await TokenStorage().saveUser(UserProfile.fromJson(userJson));
      }
      completer.complete(newToken.isNotEmpty);
      return completer.future;
    } catch (_) {
      completer.complete(false);
      return completer.future;
    } finally {
      _refreshCompleter = null;
    }
  }

  ApiResponse<Map<String, dynamic>> _parseResponse(http.Response response) {
    if (response.body.isEmpty) {
      if (response.statusCode >= 200 && response.statusCode < 300) {
        return ApiResponse(data: const {});
      }
      return ApiResponse(
        error: ApiError(message: 'Empty response', statusCode: response.statusCode),
      );
    }

    try {
      final decoded = jsonDecode(response.body);
      if (decoded is Map<String, dynamic>) {
        if (response.statusCode >= 200 && response.statusCode < 300) {
          return ApiResponse(data: decoded);
        }
        final message =
            decoded['error']?.toString() ?? 'Request failed';
        return ApiResponse(
          error: ApiError(message: message, statusCode: response.statusCode),
        );
      }
      return ApiResponse(
        error: ApiError(message: 'Invalid response format', statusCode: response.statusCode),
      );
    } catch (_) {
      return ApiResponse(
        error: ApiError(message: 'Failed to parse response', statusCode: response.statusCode),
      );
    }
  }
}

final ApiClient sharedApiClient = ApiClient(baseUrl: ApiConfig.baseUrl);
