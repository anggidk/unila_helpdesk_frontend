import 'dart:convert';
import 'dart:io';

void main() {
  final values = _loadEnvFile(File('.env'));
  final config = <String, String>{
    'apiKey': _required('FIREBASE_WEB_API_KEY', values),
    'appId': _required('FIREBASE_WEB_APP_ID', values),
    'messagingSenderId': _required('FIREBASE_WEB_MESSAGING_SENDER_ID', values),
    'projectId': _required('FIREBASE_WEB_PROJECT_ID', values),
    'authDomain': _required('FIREBASE_WEB_AUTH_DOMAIN', values),
    'storageBucket': _required('FIREBASE_WEB_STORAGE_BUCKET', values),
  };

  final measurementId = _optional('FIREBASE_WEB_MEASUREMENT_ID', values);
  if (measurementId != null && measurementId.isNotEmpty) {
    config['measurementId'] = measurementId;
  }

  final output = File('web/firebase-web-config.js');
  output.writeAsStringSync(
    'self.FIREBASE_WEB_CONFIG = ${jsonEncode(config)};\n',
  );

  final runtimeEnv = File('assets/config/runtime.env');
  runtimeEnv.parent.createSync(recursive: true);
  runtimeEnv.writeAsStringSync(_buildRuntimeEnv(values));

  stdout.writeln('Generated ${output.path}');
  stdout.writeln('Generated ${runtimeEnv.path}');
}

String _buildRuntimeEnv(Map<String, String> values) {
  const keys = <String>[
    'ENVIRONMENT',
    'FIREBASE_WEB_API_KEY',
    'FIREBASE_WEB_APP_ID',
    'FIREBASE_WEB_MESSAGING_SENDER_ID',
    'FIREBASE_WEB_PROJECT_ID',
    'FIREBASE_WEB_AUTH_DOMAIN',
    'FIREBASE_WEB_STORAGE_BUCKET',
    'FIREBASE_WEB_MEASUREMENT_ID',
    'FIREBASE_WEB_VAPID_KEY',
  ];

  final buffer = StringBuffer();
  for (final key in keys) {
    final value = _optional(key, values);
    if (value == null || value.isEmpty) {
      continue;
    }
    buffer.writeln('$key=$value');
  }
  return buffer.toString();
}

String _required(String key, Map<String, String> values) {
  final value = _optional(key, values);
  if (value != null && value.isNotEmpty) {
    return value;
  }
  throw StateError('$key belum di-set.');
}

String? _optional(String key, Map<String, String> values) {
  final envValue = Platform.environment[key]?.trim();
  if (envValue != null && envValue.isNotEmpty) {
    return envValue;
  }
  final fileValue = values[key]?.trim();
  if (fileValue != null && fileValue.isNotEmpty) {
    return fileValue;
  }
  return null;
}

Map<String, String> _loadEnvFile(File file) {
  if (!file.existsSync()) {
    return <String, String>{};
  }

  final result = <String, String>{};
  for (final rawLine in file.readAsLinesSync()) {
    final line = rawLine.trim();
    if (line.isEmpty || line.startsWith('#')) {
      continue;
    }

    final separatorIndex = line.indexOf('=');
    if (separatorIndex <= 0) {
      continue;
    }

    final key = line.substring(0, separatorIndex).trim();
    var value = line.substring(separatorIndex + 1).trim();

    if ((value.startsWith('"') && value.endsWith('"')) ||
        (value.startsWith("'") && value.endsWith("'"))) {
      value = value.substring(1, value.length - 1);
    }

    result[key] = value;
  }
  return result;
}
