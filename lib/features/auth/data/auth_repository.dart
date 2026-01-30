import 'package:unila_helpdesk_frontend/core/config/api_config.dart';
import 'package:unila_helpdesk_frontend/core/mock/mock_data.dart';
import 'package:unila_helpdesk_frontend/core/models/user_models.dart';
import 'package:unila_helpdesk_frontend/core/network/api_client.dart';
import 'package:unila_helpdesk_frontend/core/network/api_endpoints.dart';

class AuthRepository {
  AuthRepository({ApiClient? client})
    : _client = client ?? MockApiClient(baseUrl: ApiConfig.baseUrl);

  final ApiClient _client;

  Future<UserProfile> signInWithMockSso({
    required String username,
    required String password,
    required String entity,
  }) async {
    // TODO: Replace with SSO integration.

    // Deteksi apakah admin berdasarkan username
    final isAdmin = username.toLowerCase() == 'admin';

    final fallbackName = username.isEmpty
        ? MockData.registeredUser.name
        : username;
    return UserProfile(
      id: isAdmin ? 'ADM-001' : 'USR-SSO-001',
      name: isAdmin ? 'Administrator' : fallbackName,
      email: username.isEmpty
          ? MockData.registeredUser.email
          : '$username@unila.ac.id',
      role: isAdmin ? UserRole.admin : UserRole.registered,
      entity: isAdmin ? 'Admin' : entity,
    );
  }

  Future<ApiResponse<Map<String, dynamic>>> exchangeToken({
    required String ssoCode,
  }) {
    return _client.post(ApiEndpoints.login, body: {'code': ssoCode});
  }
}
