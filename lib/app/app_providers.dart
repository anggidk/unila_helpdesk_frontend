import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:unila_helpdesk_frontend/core/mock/mock_data.dart';
import 'package:unila_helpdesk_frontend/core/models/analytics_models.dart';
import 'package:unila_helpdesk_frontend/core/models/notification_models.dart';
import 'package:unila_helpdesk_frontend/core/models/survey_models.dart';
import 'package:unila_helpdesk_frontend/core/models/ticket_models.dart';
import 'package:unila_helpdesk_frontend/core/models/user_models.dart';

final ticketsProvider = Provider<List<Ticket>>((ref) => MockData.tickets);
final notificationsProvider = Provider<List<AppNotification>>((ref) => MockData.notifications);
final serviceCategoriesProvider = Provider<List<ServiceCategory>>((ref) => MockData.serviceCategories);
final guestCategoriesProvider = Provider<List<ServiceCategory>>((ref) => MockData.guestCategories);
final surveyTemplatesProvider = Provider<List<SurveyTemplate>>((ref) => MockData.surveyTemplates);
final surveyTemplateByCategoryProvider =
    Provider.family<SurveyTemplate, String>((ref, categoryId) {
  return MockData.surveyForCategory(categoryId);
});
final adminUserProvider = Provider<UserProfile>((ref) => MockData.adminUser);
final cohortRowsProvider = Provider<List<CohortRow>>((ref) => MockData.cohortRows);
final serviceTrendsProvider = Provider<List<ServiceTrend>>((ref) => MockData.serviceTrends);
