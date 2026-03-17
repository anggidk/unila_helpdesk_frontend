import 'package:flutter_dotenv/flutter_dotenv.dart';

class ApiConfig {
  const ApiConfig._();

  static String _dotenvValue(String key) {
    try {
      return (dotenv.env[key] ?? '').trim();
    } catch (_) {
      return '';
    }
  }

  // Environment detection
  static String get environment {
    const defineEnvironment = String.fromEnvironment('ENVIRONMENT');
    if (defineEnvironment.isNotEmpty) return defineEnvironment.toLowerCase();

    final dotenvEnvironment = _dotenvValue('ENVIRONMENT');
    if (dotenvEnvironment.isNotEmpty) return dotenvEnvironment.toLowerCase();

    throw StateError(
      'ENVIRONMENT belum di-set. Isi di .env atau jalankan dengan --dart-define=ENVIRONMENT=development|staging|production.',
    );
  }

  // Base URL didefinisikan berdasarkan ENVIRONMENT.
  static String get baseUrl {
    const defineBaseUrl = String.fromEnvironment('API_BASE_URL');
    if (defineBaseUrl.trim().isNotEmpty) {
      return defineBaseUrl.trim();
    }
    const defineBaseUrlLegacy = String.fromEnvironment('BASE_URL');
    if (defineBaseUrlLegacy.trim().isNotEmpty) {
      return defineBaseUrlLegacy.trim();
    }

    final apiBaseUrl = _dotenvValue('API_BASE_URL');
    final dotenvBaseUrl = apiBaseUrl.isNotEmpty
        ? apiBaseUrl
        : _dotenvValue('BASE_URL');
    if (dotenvBaseUrl.isNotEmpty) {
      return dotenvBaseUrl;
    }

    switch (environment) {
      case 'development':
        return 'http://localhost:8080';
      case 'staging':
        return 'https://api.withanggi.web.id';
      case 'production':
        return 'https://api.unila-helpdesk.com';
      default:
        throw StateError(
          "ENVIRONMENT '$environment' tidak valid. Gunakan development, staging, atau production.",
        );
    }
  }

  static const Duration timeout = Duration(seconds: 15);
}
