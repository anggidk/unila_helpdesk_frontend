import 'package:unila_helpdesk_frontend/core/models/notification_models.dart';
import 'package:unila_helpdesk_frontend/core/network/api_client.dart';
import 'package:unila_helpdesk_frontend/core/network/api_endpoints.dart';

class NotificationRepository {
  NotificationRepository({ApiClient? client})
      : _client = client ?? sharedApiClient;

  final ApiClient _client;

  Future<List<AppNotification>> fetchNotifications() async {
    final response = await _client.get(ApiEndpoints.notifications);
    final items = response.data?['data'];
    if (response.isSuccess && items is List) {
      return items
          .whereType<Map<String, dynamic>>()
          .map(AppNotification.fromJson)
          .toList();
    }
    return [];
  }

  Future<ApiResponse<Map<String, dynamic>>> registerFcmToken(String token) {
    return _client.post(ApiEndpoints.fcmRegister, body: {'token': token});
  }
}
