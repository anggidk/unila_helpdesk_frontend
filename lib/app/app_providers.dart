import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:unila_helpdesk_frontend/core/models/analytics_models.dart';
import 'package:unila_helpdesk_frontend/core/models/notification_models.dart';
import 'package:unila_helpdesk_frontend/core/models/survey_models.dart';
import 'package:unila_helpdesk_frontend/core/models/ticket_models.dart';
import 'package:unila_helpdesk_frontend/core/models/user_models.dart';
import 'package:unila_helpdesk_frontend/features/categories/data/category_repository.dart';
import 'package:unila_helpdesk_frontend/features/admin/data/report_repository.dart';
import 'package:unila_helpdesk_frontend/features/feedback/data/survey_repository.dart';
import 'package:unila_helpdesk_frontend/features/notifications/data/notification_repository.dart';
import 'package:unila_helpdesk_frontend/features/tickets/data/ticket_repository.dart';

final ticketsProvider = FutureProvider<List<Ticket>>((ref) async {
  return TicketRepository().fetchTickets();
});
final notificationsProvider = FutureProvider<List<AppNotification>>((ref) async {
  return NotificationRepository().fetchNotifications();
});
final serviceCategoriesProvider = FutureProvider<List<ServiceCategory>>((ref) async {
  return CategoryRepository().fetchAll();
});
final guestCategoriesProvider = FutureProvider<List<ServiceCategory>>((ref) async {
  return CategoryRepository().fetchGuest();
});
final surveyTemplatesProvider = FutureProvider<List<SurveyTemplate>>((ref) async {
  return SurveyRepository().fetchTemplates();
});
final surveyTemplateByCategoryProvider =
    FutureProvider.family<SurveyTemplate, String>((ref, categoryId) async {
  return SurveyRepository().fetchTemplateByCategory(categoryId);
});
final adminUserProvider = StateProvider<UserProfile?>((ref) => null);
final cohortRowsProvider = FutureProvider<List<CohortRow>>((ref) async {
  return ReportRepository().fetchCohort();
});
final serviceTrendsProvider = FutureProvider<List<ServiceTrend>>((ref) async {
  return ReportRepository().fetchServiceTrends();
});
