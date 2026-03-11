import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter_dotenv/flutter_dotenv.dart';

class FirebaseWebConfig {
  const FirebaseWebConfig._();

  static FirebaseOptions get options => FirebaseOptions(
    apiKey: _required('FIREBASE_WEB_API_KEY'),
    appId: _required('FIREBASE_WEB_APP_ID'),
    messagingSenderId: _required('FIREBASE_WEB_MESSAGING_SENDER_ID'),
    projectId: _required('FIREBASE_WEB_PROJECT_ID'),
    authDomain: _required('FIREBASE_WEB_AUTH_DOMAIN'),
    storageBucket: _required('FIREBASE_WEB_STORAGE_BUCKET'),
    measurementId: _optional('FIREBASE_WEB_MEASUREMENT_ID'),
  );

  static String _required(String key) {
    final value = _optional(key);
    if (value != null && value.isNotEmpty) {
      return value;
    }
    throw StateError('$key belum di-set untuk Firebase Web.');
  }

  static String? _optional(String key) {
    final defineValue = _fromEnvironment(key);
    if (defineValue.isNotEmpty) {
      return defineValue.trim();
    }

    try {
      final value = (dotenv.env[key] ?? '').trim();
      if (value.isNotEmpty) {
        return value;
      }
    } catch (_) {
      // Dotenv belum termuat. Abaikan dan fallback ke null.
    }

    return null;
  }

  static String _fromEnvironment(String key) {
    switch (key) {
      case 'FIREBASE_WEB_API_KEY':
        return const String.fromEnvironment('FIREBASE_WEB_API_KEY');
      case 'FIREBASE_WEB_APP_ID':
        return const String.fromEnvironment('FIREBASE_WEB_APP_ID');
      case 'FIREBASE_WEB_MESSAGING_SENDER_ID':
        return const String.fromEnvironment('FIREBASE_WEB_MESSAGING_SENDER_ID');
      case 'FIREBASE_WEB_PROJECT_ID':
        return const String.fromEnvironment('FIREBASE_WEB_PROJECT_ID');
      case 'FIREBASE_WEB_AUTH_DOMAIN':
        return const String.fromEnvironment('FIREBASE_WEB_AUTH_DOMAIN');
      case 'FIREBASE_WEB_STORAGE_BUCKET':
        return const String.fromEnvironment('FIREBASE_WEB_STORAGE_BUCKET');
      case 'FIREBASE_WEB_MEASUREMENT_ID':
        return const String.fromEnvironment('FIREBASE_WEB_MEASUREMENT_ID');
      default:
        return '';
    }
  }
}
