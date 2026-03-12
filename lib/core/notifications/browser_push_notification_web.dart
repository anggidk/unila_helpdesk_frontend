import 'dart:async';

import 'package:flutter/material.dart';
import 'package:unila_helpdesk_frontend/app/app_keys.dart';
import 'package:unila_helpdesk_frontend/app/app_theme.dart';

Timer? _dismissTimer;
int _bannerVersion = 0;

Future<void> showBrowserNotification({
  required String title,
  required String body,
  String? ticketId,
  void Function(String ticketId)? onTapTicket,
}) async {
  final value = ticketId?.trim() ?? '';
  final messenger = appScaffoldMessengerKey.currentState;
  if (messenger == null) return;

  _dismissTimer?.cancel();
  messenger.hideCurrentMaterialBanner();
  final version = ++_bannerVersion;

  messenger.showMaterialBanner(
    MaterialBanner(
      backgroundColor: Colors.white,
      surfaceTintColor: Colors.white,
      elevation: 0,
      padding: const EdgeInsets.fromLTRB(16, 12, 8, 12),
      leading: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: AppTheme.navy.withValues(alpha: 0.10),
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Icon(
          Icons.notifications_active_outlined,
          color: AppTheme.navy,
        ),
      ),
      content: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontWeight: FontWeight.w700,
              color: AppTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            body,
            style: const TextStyle(color: AppTheme.textMuted),
          ),
        ],
      ),
      actions: [
        if (value.isNotEmpty)
          TextButton(
            onPressed: () {
              messenger.hideCurrentMaterialBanner();
              onTapTicket?.call(value);
            },
            child: const Text('LIHAT'),
          ),
        IconButton(
          tooltip: 'Tutup',
          onPressed: () => messenger.hideCurrentMaterialBanner(),
          icon: const Icon(Icons.close),
        ),
      ],
    ),
  );

  _dismissTimer = Timer(const Duration(seconds: 6), () {
    if (_bannerVersion == version) {
      messenger.hideCurrentMaterialBanner();
    }
  });
}
