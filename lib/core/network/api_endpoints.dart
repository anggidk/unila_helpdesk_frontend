class ApiEndpoints {
  const ApiEndpoints._();

  static const String login = '/auth/login';
  static const String guestLogin = '/auth/guest';

  static const String tickets = '/tickets';
  static String ticketById(String id) => '/tickets/$id';
  static const String ticketSearch = '/tickets/search';
  static const String categories = '/categories';
  static const String guestCategories = '/categories/guest';

  static const String surveys = '/surveys';
  static const String surveyTemplates = '/surveys/templates';
  static String surveyByCategory(String categoryId) => '/surveys/categories/$categoryId';
  static const String surveyResponses = '/surveys/responses';

  static const String notifications = '/notifications';
  static const String fcmRegister = '/notifications/fcm';

  static const String reports = '/reports';
  static const String cohort = '/reports/cohort';
}
