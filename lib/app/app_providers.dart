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
final cohortPeriodProvider = StateProvider<String>((ref) => 'monthly');
final cohortAnalysisProvider = StateProvider<String>((ref) => 'retention');
final reportsPeriodProvider = StateProvider<String>((ref) => 'monthly');
final reportsCategoryIdProvider = StateProvider<String?>((ref) => null);
final reportsTemplateIdProvider = StateProvider<String?>((ref) => null);
final reportsChartPeriodProvider = StateProvider<String>((ref) => 'monthly');
final reportsTemplatesProvider =
    FutureProvider.autoDispose<List<SurveyTemplate>>((ref) async {
  final categoryId = ref.watch(reportsCategoryIdProvider);
  if (categoryId == null || categoryId.isEmpty) {
    return [];
  }
  return ReportRepository().fetchTemplatesByCategory(categoryId);
});
final cohortRowsProvider = FutureProvider.autoDispose<List<CohortRow>>((ref) async {
  final period = ref.watch(cohortPeriodProvider);
  return ReportRepository().fetchCohort(
    period: period,
    periods: _cohortPeriodsFor(period),
  );
});
final usageCohortProvider = FutureProvider.autoDispose<List<UsageCohortRow>>((ref) async {
  final period = ref.watch(cohortPeriodProvider);
  return ReportRepository().fetchUsageCohort(
    period: period,
    periods: _cohortPeriodsFor(period),
  );
});
final serviceUtilizationProvider =
    FutureProvider.autoDispose<List<ServiceUtilizationRow>>((ref) async {
  final period = ref.watch(cohortPeriodProvider);
  return ReportRepository().fetchServiceUtilization(
    period: period,
    periods: 1,
  );
});
final entityServiceProvider =
    FutureProvider.autoDispose<List<EntityServiceRow>>((ref) async {
  final period = ref.watch(cohortPeriodProvider);
  return ReportRepository().fetchEntityService(
    period: period,
    periods: 1,
  );
});
final reportsUsageProvider = FutureProvider.autoDispose<List<UsageCohortRow>>((ref) async {
  final period = ref.watch(reportsPeriodProvider);
  return ReportRepository().fetchUsageCohort(
    period: period,
    periods: _cohortPeriodsFor(period),
  );
});
final reportsServiceTrendsProvider =
    FutureProvider.autoDispose<List<ServiceTrend>>((ref) async {
  final period = ref.watch(reportsPeriodProvider);
  final range = _periodRangeFor(period);
  return ReportRepository().fetchServiceTrends(
    start: range.start,
    end: range.end,
  );
});
final reportsChartUsageProvider = FutureProvider.autoDispose<List<UsageCohortRow>>((ref) async {
  final period = ref.watch(reportsChartPeriodProvider);
  return ReportRepository().fetchUsageCohort(
    period: period,
    periods: _cohortPeriodsFor(period),
  );
});
final reportsChartServiceTrendsProvider =
    FutureProvider.autoDispose<List<ServiceTrend>>((ref) async {
  final period = ref.watch(reportsChartPeriodProvider);
  final range = _periodRangeFor(period);
  return ReportRepository().fetchServiceTrends(
    start: range.start,
    end: range.end,
  );
});
final dashboardSummaryProvider =
    FutureProvider.autoDispose<DashboardSummary?>((ref) async {
  return ReportRepository().fetchDashboardSummary();
});
final dashboardUsageProvider = FutureProvider.autoDispose<List<UsageCohortRow>>((ref) async {
  return ReportRepository().fetchUsageCohort(
    period: 'monthly',
    periods: 6,
  );
});
final dashboardSatisfactionProvider =
    FutureProvider.autoDispose<List<ServiceSatisfaction>>((ref) async {
  return ReportRepository().fetchServiceSatisfactionSummary(
    period: 'monthly',
    periods: 6,
  );
});
final surveySatisfactionProvider =
    FutureProvider.autoDispose<SurveySatisfactionReport?>((ref) async {
  final period = ref.watch(reportsPeriodProvider);
  final categoryId = ref.watch(reportsCategoryIdProvider);
  final templateId = ref.watch(reportsTemplateIdProvider);
  if (categoryId == null && templateId == null) {
    return null;
  }
  return ReportRepository().fetchSurveySatisfaction(
    categoryId: categoryId,
    templateId: templateId,
    period: period,
    periods: _cohortPeriodsFor(period),
  );
});

int _cohortPeriodsFor(String period) {
  switch (period) {
    case 'daily':
      return 7;
    case 'weekly':
      return 4;
    case 'yearly':
      return 5;
    default:
      return 6;
  }
}
_ReportRange _periodRangeFor(String period) {
  final now = DateTime.now().toUtc();
  switch (period) {
    case 'daily':
      return _ReportRange(
        start: now.subtract(const Duration(days: 7)),
        end: now,
      );
    case 'weekly':
      return _ReportRange(
        start: now.subtract(const Duration(days: 28)),
        end: now,
      );
    case 'yearly':
      return _ReportRange(
        start: DateTime(now.year - 5, now.month, now.day),
        end: now,
      );
    default:
      return _ReportRange(
        start: DateTime(now.year, now.month - 6, now.day),
        end: now,
      );
  }
}

class _ReportRange {
  const _ReportRange({required this.start, required this.end});

  final DateTime start;
  final DateTime end;
}
final serviceTrendsProvider = FutureProvider<List<ServiceTrend>>((ref) async {
  return ReportRepository().fetchServiceTrends();
});
