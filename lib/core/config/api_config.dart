class ApiConfig {
  const ApiConfig._();

  static const String baseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'https://api.unila-helpdesk.local',
  );

  static const Duration timeout = Duration(seconds: 15);
}
