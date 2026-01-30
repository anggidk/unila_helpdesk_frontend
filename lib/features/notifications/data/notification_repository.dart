import 'package:unila_helpdesk_frontend/core/config/api_config.dart';
import 'package:unila_helpdesk_frontend/core/mock/mock_data.dart';
import 'package:unila_helpdesk_frontend/core/models/notification_models.dart';
import 'package:unila_helpdesk_frontend/core/network/api_client.dart';
import 'package:unila_helpdesk_frontend/core/network/api_endpoints.dart';

class NotificationRepository {
  NotificationRepository({ApiClient? client})
      : _client = client ?? MockApiClient(baseUrl: ApiConfig.baseUrl);

  final ApiClient _client;

  Future<List<AppNotification>> fetchNotifications() async {
    // TODO: Replace with API call.
    return MockData.notifications;
  }

  Future<ApiResponse<Map<String, dynamic>>> registerFcmToken(String token) {
    return _client.post(ApiEndpoints.fcmRegister, body: {'token': token});
  }
}
