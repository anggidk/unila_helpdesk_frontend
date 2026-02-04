import 'package:unila_helpdesk_frontend/core/models/ticket_models.dart';
import 'package:unila_helpdesk_frontend/core/network/api_client.dart';
import 'package:unila_helpdesk_frontend/core/network/api_endpoints.dart';

class CategoryRepository {
  CategoryRepository({ApiClient? client}) : _client = client ?? sharedApiClient;

  final ApiClient _client;

  Future<List<ServiceCategory>> fetchAll() async {
    final response = await _client.get(ApiEndpoints.categories);
    final items = response.data?['data'];
    if (response.isSuccess && items is List) {
      return items
          .whereType<Map<String, dynamic>>()
          .map(ServiceCategory.fromJson)
          .toList();
    }
    return [];
  }

  Future<List<ServiceCategory>> fetchGuest() async {
    final response = await _client.get(ApiEndpoints.guestCategories);
    final items = response.data?['data'];
    if (response.isSuccess && items is List) {
      return items
          .whereType<Map<String, dynamic>>()
          .map(ServiceCategory.fromJson)
          .toList();
    }
    return [];
  }

  Future<void> updateTemplate({
    required String categoryId,
    required String templateId,
  }) async {
    final response = await _client.put(
      ApiEndpoints.categoryTemplate(categoryId),
      body: {'templateId': templateId},
    );
    if (!response.isSuccess) {
      throw Exception(response.error?.message ?? 'Gagal menyimpan template kategori');
    }
  }
}
