import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:unila_helpdesk_frontend/app/app_providers.dart';
import 'package:unila_helpdesk_frontend/app/app_theme.dart';
import 'package:unila_helpdesk_frontend/core/utils/date_utils.dart';

final notificationsFcmEnabledProvider = StateProvider.autoDispose<bool>((ref) => true);

class NotificationsPage extends ConsumerWidget {
  const NotificationsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notificationsAsync = ref.watch(notificationsProvider);
    final notifications = notificationsAsync.value ?? [];
    final fcmEnabled = ref.watch(notificationsFcmEnabledProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Notifications')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppTheme.outline),
            ),
            child: SwitchListTile(
              value: fcmEnabled,
              onChanged: (value) => ref.read(notificationsFcmEnabledProvider.notifier).state = value,
              title: const Text('Push Notification (FCM)'),
              subtitle: const Text('Notifikasi status tiket dan survey'),
            ),
          ),
          const SizedBox(height: 16),
          if (notificationsAsync.isLoading)
            const Center(child: CircularProgressIndicator()),
          if (notificationsAsync.hasError)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Text(
                'Gagal memuat notifikasi: ${notificationsAsync.error}',
                style: const TextStyle(color: AppTheme.textMuted),
              ),
            ),
          ...notifications.map(
            (notification) => Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: notification.isRead ? Colors.white : AppTheme.accentBlue.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppTheme.outline),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(notification.title, style: const TextStyle(fontWeight: FontWeight.w700)),
                  const SizedBox(height: 6),
                  Text(notification.message, style: const TextStyle(color: AppTheme.textMuted)),
                  const SizedBox(height: 8),
                  Text(formatDateTime(notification.timestamp), style: const TextStyle(color: AppTheme.textMuted)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

