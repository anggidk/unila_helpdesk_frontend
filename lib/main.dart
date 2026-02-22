import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:unila_helpdesk_frontend/app/app.dart';
import 'package:unila_helpdesk_frontend/core/notifications/fcm_service.dart';
import 'package:unila_helpdesk_frontend/core/network/api_client.dart';
import 'package:unila_helpdesk_frontend/core/network/token_storage.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await dotenv.load(fileName: '.env');
  } catch (_) {
    // Tetap jalan dengan fallback String.fromEnvironment/default.
  }
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
