class ApiEndpoints {
  const ApiEndpoints._();

  static const String login = '/auth/login';
  static const String refresh = '/auth/refresh';

  static const String tickets = '/tickets';
  static const String ticketsPaged = '/tickets/paged';
  static const String guestTickets = '/tickets/guest';
  static String ticketById(String id) => '/tickets/$id';
  static const String ticketSearch = '/tickets/search';
  static const String categories = '/categories';
  static const String guestCategories = '/categories/guest';
  static String categoryTemplate(String id) => '/categories/$id/template';

  static const String surveys = '/surveys';
  static const String surveyTemplates = '/surveys/templates';
  static String surveyTemplateById(String id) => '/surveys/templates/$id';
  static String surveyByCategory(String categoryId) => '/surveys/categories/$categoryId';
  static const String surveyResponses = '/surveys/responses';

  static const String notifications = '/notifications';
  static const String fcmRegister = '/notifications/fcm';

  static const String reports = '/reports';
  static const String reportsSummary = '/reports/summary';
  static const String reportsSatisfactionSummary = '/reports/satisfaction-summary';
  static const String reportsSatisfaction = '/reports/satisfaction';
  static const String reportsTemplates = '/reports/templates';
  static const String cohort = '/reports/cohort';
  static const String usageCohort = '/reports/usage';
  static const String serviceUtilization = '/reports/service-utilization';
  static const String entityService = '/reports/entity-service';
}
