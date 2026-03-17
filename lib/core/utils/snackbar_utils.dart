import 'package:flutter/material.dart';
import 'package:unila_helpdesk_frontend/app/app_theme.dart';

enum AppSnackTone { success, error, warning, info }

void showAppSnackBar(
  BuildContext context, {
  required String message,
  AppSnackTone tone = AppSnackTone.info,
  Duration duration = const Duration(seconds: 3),
}) {
  final messenger = ScaffoldMessenger.of(context);
  messenger.hideCurrentSnackBar();
  messenger.showSnackBar(
    SnackBar(
      content: Text(message),
      duration: duration,
      backgroundColor: switch (tone) {
        AppSnackTone.success => AppTheme.success,
        AppSnackTone.error => AppTheme.warning,
        AppSnackTone.warning => AppTheme.warning,
        AppSnackTone.info => AppTheme.navy,
      },
    ),
  );
}
