import 'package:unila_helpdesk_frontend/core/models/analytics_models.dart';
import 'package:unila_helpdesk_frontend/core/network/api_client.dart';
import 'package:unila_helpdesk_frontend/core/network/api_endpoints.dart';

class ReportRepository {
  ReportRepository({ApiClient? client}) : _client = client ?? sharedApiClient;

  final ApiClient _client;

  Future<List<CohortRow>> fetchCohort({int months = 5}) async {
    final response = await _client.get(
      ApiEndpoints.cohort,
      query: {'months': months.toString()},
    );
    final items = response.data?['data'];
    if (response.isSuccess && items is List) {
      return items
          .whereType<Map<String, dynamic>>()
          .map(CohortRow.fromJson)
          .toList();
    }
    return [];
  }

  Future<List<ServiceTrend>> fetchServiceTrends({
    DateTime? start,
    DateTime? end,
  }) async {
    final query = <String, String>{};
    if (start != null) {
      query['start'] = start.toUtc().toIso8601String();
    }
    if (end != null) {
      query['end'] = end.toUtc().toIso8601String();
    }
    final response = await _client.get(ApiEndpoints.reports, query: query);
    final items = response.data?['data'];
    if (response.isSuccess && items is List) {
      return items
          .whereType<Map<String, dynamic>>()
          .map(ServiceTrend.fromJson)
          .toList();
    }
    return [];
  }
}
