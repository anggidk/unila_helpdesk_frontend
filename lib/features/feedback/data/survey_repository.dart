import 'package:unila_helpdesk_frontend/core/models/survey_models.dart';
import 'package:unila_helpdesk_frontend/core/network/api_client.dart';
import 'package:unila_helpdesk_frontend/core/network/api_endpoints.dart';

class SurveyRepository {
  SurveyRepository({ApiClient? client})
      : _client = client ?? sharedApiClient;

  final ApiClient _client;

  Future<List<SurveyTemplate>> fetchTemplates() async {
    final response = await _client.get(ApiEndpoints.surveys);
    final items = response.data?['data'];
    if (response.isSuccess && items is List) {
      return items
          .whereType<Map<String, dynamic>>()
          .map(SurveyTemplate.fromJson)
          .toList();
    }
    return [];
  }

  Future<SurveyTemplate> fetchTemplateByCategory(String categoryId) async {
    final response = await _client.get(
      ApiEndpoints.surveyByCategory(categoryId),
    );
    final data = response.data?['data'];
    if (response.isSuccess && data is Map<String, dynamic>) {
      return SurveyTemplate.fromJson(data);
    }
    throw Exception(response.error?.message ?? 'Template tidak ditemukan');
  }

  Future<ApiResponse<Map<String, dynamic>>> submitSurvey({
    required String ticketId,
    required Map<String, dynamic> answers,
  }) {
    return _client.post(ApiEndpoints.surveyResponses, body: {
      'ticket_id': ticketId,
      'answers': answers,
    });
  }

  Future<SurveyTemplate> createTemplate({
    required String title,
    required String description,
    required String categoryId,
    required List<SurveyQuestion> questions,
  }) async {
    final response = await _client.post(ApiEndpoints.surveyTemplates, body: {
      'title': title,
      'description': description,
      'categoryId': categoryId,
      'questions': questions
          .map(
            (question) => {
              'text': question.text,
              'type': question.type.name,
              'options': question.options,
            },
          )
          .toList(),
    });
    final data = response.data?['data'];
    if (response.isSuccess && data is Map<String, dynamic>) {
      return SurveyTemplate.fromJson(data);
    }
    throw Exception(response.error?.message ?? 'Gagal menyimpan template');
  }

  Future<SurveyTemplate> updateTemplate({
    required String templateId,
    required String title,
    required String description,
    required String categoryId,
    required List<SurveyQuestion> questions,
  }) async {
    final response = await _client.put(ApiEndpoints.surveyTemplateById(templateId), body: {
      'title': title,
      'description': description,
      'categoryId': categoryId,
      'questions': questions
          .map(
            (question) => {
              'text': question.text,
              'type': question.type.name,
              'options': question.options,
            },
          )
          .toList(),
    });
    final data = response.data?['data'];
    if (response.isSuccess && data is Map<String, dynamic>) {
      return SurveyTemplate.fromJson(data);
    }
    throw Exception(response.error?.message ?? 'Gagal memperbarui template');
  }

  Future<void> deleteTemplate(String templateId) async {
    final response = await _client.delete(ApiEndpoints.surveyTemplateById(templateId));
    if (!response.isSuccess) {
      throw Exception(response.error?.message ?? 'Gagal menghapus template');
    }
  }
}
