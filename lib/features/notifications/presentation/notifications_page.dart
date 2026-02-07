import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:unila_helpdesk_frontend/app/app_providers.dart';
import 'package:unila_helpdesk_frontend/app/app_theme.dart';
import 'package:unila_helpdesk_frontend/core/navigation/ticket_navigation.dart';
import 'package:unila_helpdesk_frontend/core/notifications/fcm_service.dart';
import 'package:unila_helpdesk_frontend/core/utils/date_utils.dart';

final notificationsFcmEnabledProvider = FutureProvider.autoDispose<bool>(
  (ref) => FcmService.isPushEnabled(),
);
final notificationsFcmUpdatingProvider = StateProvider.autoDispose<bool>(
  (ref) => false,
);

class NotificationsPage extends ConsumerWidget {
  const NotificationsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notificationsAsync = ref.watch(notificationsProvider);
    final notifications = notificationsAsync.value ?? [];
    final fcmEnabledAsync = ref.watch(notificationsFcmEnabledProvider);
    final isUpdating = ref.watch(notificationsFcmUpdatingProvider);
    final fcmEnabled = fcmEnabledAsync.value ?? true;
    return Scaffold(
      appBar: AppBar(title: const Text('Notifikasi')),
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
              onChanged: (fcmEnabledAsync.isLoading || isUpdating)
                  ? null
                  : (value) async {
                      ref.read(notificationsFcmUpdatingProvider.notifier).state =
                          true;
                      try {
                        await FcmService.setPushEnabled(value);
                        ref.invalidate(notificationsFcmEnabledProvider);
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                value
                                    ? 'Notifikasi push diaktifkan.'
                                    : 'Notifikasi push dimatikan.',
                              ),
                            ),
                          );
                        }
                      } catch (_) {
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text(
                                'Gagal mengubah pengaturan notifikasi.',
                              ),
                            ),
                          );
                        }
                      } finally {
                        if (context.mounted) {
                          ref
                              .read(notificationsFcmUpdatingProvider.notifier)
                              .state = false;
                        }
                      }
                    },
              title: const Text('Notifikasi Push (FCM)'),
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
            (notification) {
              final canOpenTicket = notification.ticketId.isNotEmpty;
              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(
                  color: notification.isRead
                      ? Colors.white
                      : AppTheme.accentBlue.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppTheme.outline),
                ),
                child: InkWell(
                  borderRadius: BorderRadius.circular(16),
                  onTap: canOpenTicket
                      ? () async {
                          final opened = await openTicketDetailById(
                            notification.ticketId,
                          );
                          if (!opened && context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text(
                                  'Tiket tidak ditemukan atau akses ditolak.',
                                ),
                              ),
                            );
                          }
                        }
                      : null,
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                notification.title,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                notification.message,
                                style: const TextStyle(
                                  color: AppTheme.textMuted,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                formatDateTime(notification.timestamp),
                                style: const TextStyle(
                                  color: AppTheme.textMuted,
                                ),
                              ),
                            ],
                          ),
                        ),
                        if (canOpenTicket) ...[
                          const SizedBox(width: 12),
                          const Icon(
                            Icons.chevron_right,
                            color: AppTheme.textMuted,
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

