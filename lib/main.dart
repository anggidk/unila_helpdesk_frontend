import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:unila_helpdesk_frontend/app/app.dart';
import 'package:unila_helpdesk_frontend/core/notifications/fcm_service.dart';
import 'package:unila_helpdesk_frontend/core/network/api_client.dart';
import 'package:unila_helpdesk_frontend/core/network/token_storage.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await _loadRuntimeEnv();
  initializeSharedApiClient();
  final token = await TokenStorage().readToken();
  if (token != null && token.isNotEmpty) {
    sharedApiClient.setAuthToken(token);
  }
  runApp(
    const ProviderScope(
      child: HelpdeskApp(),
    ),
  );
  unawaited(FcmService.initialize());
}

Future<void> _loadRuntimeEnv() async {
  final runtimeValues = await _readEnvValues('assets/config/runtime.env');
  final mergedValues = <String, String>{...runtimeValues};
  var sourceFile = 'assets/config/runtime.env';

  // Local development may override generated runtime config with .env.
  if (kDebugMode) {
    final localValues = await _readEnvValues('.env');
    mergedValues.addAll(localValues);
    sourceFile = '.env';
  }

  await dotenv.load(
    fileName: sourceFile,
    isOptional: true,
    mergeWith: mergedValues,
  );
}

Future<Map<String, String>> _readEnvValues(String fileName) async {
  try {
    await dotenv.load(fileName: fileName, isOptional: true);
    return Map<String, String>.from(dotenv.env);
  } catch (_) {
    return const <String, String>{};
  }
}
