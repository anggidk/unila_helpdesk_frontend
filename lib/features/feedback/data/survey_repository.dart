import 'package:unila_helpdesk_frontend/core/config/api_config.dart';
import 'package:unila_helpdesk_frontend/core/mock/mock_data.dart';
import 'package:unila_helpdesk_frontend/core/models/survey_models.dart';
import 'package:unila_helpdesk_frontend/core/network/api_client.dart';
import 'package:unila_helpdesk_frontend/core/network/api_endpoints.dart';

class SurveyRepository {
  SurveyRepository({ApiClient? client})
      : _client = client ?? MockApiClient(baseUrl: ApiConfig.baseUrl);

  final ApiClient _client;

  Future<List<SurveyTemplate>> fetchTemplates() async {
    // TODO: Replace with API call.
    return MockData.surveyTemplates;
  }

  Future<SurveyTemplate> fetchTemplateByCategory(String categoryId) async {
    // TODO: Replace with API call.
    return MockData.surveyForCategory(categoryId);
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
}
