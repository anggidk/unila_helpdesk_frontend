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
    final data = response.data?['data'];
    if (!response.isSuccess || data is! Map<String, dynamic>) {
      throw Exception(response.error?.message ?? 'Login gagal');
    }
    final token = data['token']?.toString() ?? '';
    final userJson = data['user'] as Map<String, dynamic>? ?? {};
    final expiresAt = DateTime.tryParse(data['expiresAt']?.toString() ?? '') ??
        DateTime.now();
    if (token.isNotEmpty) {
      _client.setAuthToken(token);
    }
    return AuthSession(
      token: token,
      expiresAt: expiresAt,
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
}

class AuthSession {
  const AuthSession({
    required this.token,
    required this.expiresAt,
    required this.user,
  });

  final String token;
  final DateTime expiresAt;
  final UserProfile user;
}
