import 'package:unila_helpdesk_frontend/core/models/analytics_models.dart';
import 'package:unila_helpdesk_frontend/core/models/survey_models.dart';
import 'package:unila_helpdesk_frontend/core/models/ticket_models.dart';
import 'package:unila_helpdesk_frontend/core/network/api_client.dart';
import 'package:unila_helpdesk_frontend/core/network/api_endpoints.dart';
import 'package:unila_helpdesk_frontend/core/network/query_params.dart';

class ReportRepository {
  ReportRepository({ApiClient? client}) : _client = client ?? sharedApiClient;

  final ApiClient _client;

  Future<List<CohortRow>> fetchCohort({
    String period = 'monthly',
    int periods = 5,
  }) async {
    final response = await _client.get(
      ApiEndpoints.cohort,
      query: {
        'period': period,
        'periods': periods.toString(),
      },
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
    appendUtcDateRange(query, start: start, end: end);
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

  Future<List<ServiceCategory>> fetchSurveyCategories() async {
    final response = await _client.get(ApiEndpoints.reportsCategories);
    final items = response.data?['data'];
    if (response.isSuccess && items is List) {
      return items
          .whereType<Map<String, dynamic>>()
          .map(ServiceCategory.fromJson)
          .toList();
    }
    return [];
  }

  Future<DashboardSummary?> fetchDashboardSummary() async {
    final response = await _client.get(ApiEndpoints.reportsSummary);
    final data = response.data?['data'];
    if (response.isSuccess && data is Map<String, dynamic>) {
      return DashboardSummary.fromJson(data);
    }
    return null;
  }

  Future<List<ServiceSatisfaction>> fetchServiceSatisfactionSummary({
    String period = 'monthly',
    int periods = 6,
  }) async {
    final response = await _client.get(
      ApiEndpoints.reportsSatisfactionSummary,
      query: {
        'period': period,
        'periods': periods.toString(),
      },
    );
    final items = response.data?['data'];
    if (response.isSuccess && items is List) {
      return items
          .whereType<Map<String, dynamic>>()
          .map(ServiceSatisfaction.fromJson)
          .toList();
    }
    return [];
  }

  Future<SurveySatisfactionReport?> fetchSurveySatisfaction({
    String? categoryId,
    String? templateId,
    required String period,
    required int periods,
  }) async {
    final query = <String, String>{
      'period': period,
      'periods': periods.toString(),
    };
    if (categoryId != null && categoryId.isNotEmpty) {
      query['categoryId'] = categoryId;
    }
    if (templateId != null && templateId.isNotEmpty) {
      query['templateId'] = templateId;
    }
    final response = await _client.get(ApiEndpoints.reportsSatisfaction, query: query);
    final data = response.data?['data'];
    if (response.isSuccess && data is Map<String, dynamic>) {
      return SurveySatisfactionReport.fromJson(data);
    }
    return null;
  }

  Future<String> exportSurveySatisfactionCsv({
    required String categoryId,
    String? templateId,
    required String period,
    required int periods,
  }) async {
    final query = <String, String>{
      'period': period,
      'periods': periods.toString(),
      'categoryId': categoryId,
    };
    if (templateId != null && templateId.isNotEmpty) {
      query['templateId'] = templateId;
    }
    final response = await _client.getRaw(
      ApiEndpoints.reportsSatisfactionExport,
      query: query,
    );
    if (response.isSuccess && response.data != null) {
      return response.data!;
    }
    throw Exception(response.error?.message ?? 'Gagal export CSV');
  }

  Future<List<SurveyTemplate>> fetchTemplatesByCategory(String categoryId) async {
    final response = await _client.get(
      ApiEndpoints.reportsTemplates,
      query: {'categoryId': categoryId},
    );
    final items = response.data?['data'];
    if (response.isSuccess && items is List) {
      return items
          .whereType<Map<String, dynamic>>()
          .map(SurveyTemplate.fromJson)
          .toList();
    }
    return [];
  }

  Future<List<UsageCohortRow>> fetchUsageCohort({
    required String period,
    required int periods,
  }) async {
    final response = await _client.get(
      ApiEndpoints.usageCohort,
      query: {
        'period': period,
        'periods': periods.toString(),
      },
    );
    final items = response.data?['data'];
    if (response.isSuccess && items is List) {
      return items
          .whereType<Map<String, dynamic>>()
          .map(UsageCohortRow.fromJson)
          .toList();
    }
    return [];
  }

  Future<List<EntityServiceRow>> fetchEntityService({
    required String period,
    required int periods,
  }) async {
    final response = await _client.get(
      ApiEndpoints.entityService,
      query: {
        'period': period,
        'periods': periods.toString(),
      },
    );
    final items = response.data?['data'];
    if (response.isSuccess && items is List) {
      return items
          .whereType<Map<String, dynamic>>()
          .map(EntityServiceRow.fromJson)
          .toList();
    }
    return [];
  }
}
