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
  await FcmService.initialize();
  runApp(
    const ProviderScope(
      child: HelpdeskApp(),
    ),
  );
}

Future<void> _loadRuntimeEnv() async {
  for (final fileName in ['assets/config/runtime.env', '.env']) {
    try {
      await dotenv.load(fileName: fileName);
      return;
    } catch (_) {
      // Coba fallback berikutnya.
    }
  }
}
