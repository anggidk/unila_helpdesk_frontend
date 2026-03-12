import 'package:unila_helpdesk_frontend/core/models/user_models.dart';
import 'package:unila_helpdesk_frontend/core/network/api_client.dart';
import 'package:unila_helpdesk_frontend/core/network/api_endpoints.dart';

class AuthRepository {
  AuthRepository({ApiClient? client})
    : _client = client ?? sharedApiClient;

  final ApiClient _client;

  Future<AuthSession> signInWithPassword({
    required String username,
    required String password,
  }) async {
    final response = await login(username: username, password: password);
    return _parseSession(response, fallbackMessage: 'Login gagal');
  }

  Future<AuthSession> refreshSession({
    required String refreshToken,
  }) async {
    final response = await _client.post(
      ApiEndpoints.refresh,
      body: {'refresh_token': refreshToken},
    );
    return _parseSession(response, fallbackMessage: 'Refresh sesi gagal');
  }

  AuthSession _parseSession(
    ApiResponse<Map<String, dynamic>> response, {
    required String fallbackMessage,
  }) {
    final data = response.data?['data'];
    if (!response.isSuccess || data is! Map<String, dynamic>) {
      throw Exception(response.error?.message ?? fallbackMessage);
    }
    final token = data['token']?.toString() ?? '';
    final refreshToken = data['refreshToken']?.toString() ?? '';
    final userJson = data['user'] as Map<String, dynamic>? ?? {};
    if (token.isNotEmpty) {
      _client.setAuthToken(token);
    }
    return AuthSession(
      token: token,
      refreshToken: refreshToken,
      user: UserProfile.fromJson(userJson),
    );
  }

  Future<ApiResponse<Map<String, dynamic>>> login({
    required String username,
    required String password,
  }) {
    return _client.post(ApiEndpoints.login, body: {
      'username': username,
      'password': password,
    });
  }

  Future<ApiResponse<Map<String, dynamic>>> logout({
    required String refreshToken,
  }) {
    return _client.post(
      ApiEndpoints.logout,
      body: {'refresh_token': refreshToken},
    );
  }
}

class AuthSession {
  const AuthSession({
    required this.token,
    required this.refreshToken,
    required this.user,
  });

  final String token;
  final String refreshToken;
  final UserProfile user;
}
