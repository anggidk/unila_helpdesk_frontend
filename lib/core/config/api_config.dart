class ApiConfig {
  const ApiConfig._();

  // Environment detection
  static const String environment = String.fromEnvironment(
    'ENVIRONMENT',
    defaultValue: 'development',
  );

  // Base URL berdasarkan environment
  static String get baseUrl {
    // Jika ada override dari --dart-define, gunakan itu
    const override = String.fromEnvironment('API_BASE_URL');
    if (override.isNotEmpty) return override;
    
    // Jika tidak, gunakan default berdasarkan environment
    switch (environment) {
      case 'production':
        return 'https://api.unila-helpdesk.com';
      case 'staging':
        return 'https://staging-api.unila-helpdesk.com';
      case 'development':
      default:
        return 'http://localhost:8080';
    }
  }

  static const Duration timeout = Duration(seconds: 15);
}
