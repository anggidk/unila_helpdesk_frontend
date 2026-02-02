import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:unila_helpdesk_frontend/app/app_router.dart';
import 'package:unila_helpdesk_frontend/app/app_providers.dart';
import 'package:unila_helpdesk_frontend/app/app_theme.dart';
import 'package:unila_helpdesk_frontend/core/models/ticket_models.dart';
import 'package:unila_helpdesk_frontend/core/models/user_models.dart';
import 'package:unila_helpdesk_frontend/core/network/api_client.dart';
import 'package:unila_helpdesk_frontend/core/network/token_storage.dart';

class ProfilePage extends ConsumerWidget {
  const ProfilePage({super.key, required this.user});

  final UserProfile user;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ticketsAsync = ref.watch(ticketsProvider);
    final tickets = ticketsAsync.value ?? [];
    final total = tickets.length;
    final pending = tickets
        .where((ticket) => ticket.status != TicketStatus.resolved)
        .length;
    final resolved = tickets
        .where((ticket) => ticket.status == TicketStatus.resolved)
        .length;
    return Scaffold(
      appBar: AppBar(title: const Text('My Profile')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Column(
            children: [
              Stack(
                children: [
                  const CircleAvatar(
                    radius: 46,
                    backgroundColor: AppTheme.surface,
                    child: Icon(Icons.person, size: 42, color: AppTheme.navy),
                  ),
                  Positioned(
                    bottom: 4,
                    right: 4,
                    child: Container(
                      width: 16,
                      height: 16,
                      decoration: BoxDecoration(
                        color: AppTheme.success,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.white, width: 2),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                user.name,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                ),
              ),
              Text(
                user.entity,
                style: const TextStyle(
                  color: AppTheme.accentBlue,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                user.email,
                style: const TextStyle(color: AppTheme.textMuted),
              ),
            ],
          ),
          const SizedBox(height: 20),
          if (ticketsAsync.isLoading)
            const Padding(
              padding: EdgeInsets.only(bottom: 12),
              child: Center(child: CircularProgressIndicator()),
            ),
          if (ticketsAsync.hasError)
            Text(
              'Gagal memuat tiket: ${ticketsAsync.error}',
              style: const TextStyle(color: AppTheme.textMuted),
              textAlign: TextAlign.center,
            ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _ProfileStat(label: 'Tickets', value: '$total'),
              _ProfileStat(label: 'Pending', value: '$pending'),
              _ProfileStat(label: 'Resolved', value: '$resolved'),
            ],
          ),
          const SizedBox(height: 20),
          const Text(
            'Application',
            style: TextStyle(color: AppTheme.textMuted),
          ),
          const SizedBox(height: 8),
          _MenuTile(
            icon: Icons.notifications_outlined,
            title: 'Notifications',
            subtitle: 'Status tiket dan survey',
            onTap: () {
              context.pushNamed(AppRouteNames.notifications);
            },
          ),
          const SizedBox(height: 20),
          OutlinedButton.icon(
            onPressed: () async {
              await TokenStorage().clearToken();
              sharedApiClient.setAuthToken(null);
              ref.read(adminUserProvider.notifier).state = null;
              ref.invalidate(ticketsProvider);
              ref.invalidate(notificationsProvider);
              if (!context.mounted) return;
              context.goNamed(AppRouteNames.login);
            },
            icon: const Icon(Icons.logout),
            label: const Text('Log Out'),
            style: OutlinedButton.styleFrom(foregroundColor: AppTheme.danger),
          ),
          const SizedBox(height: 8),
          const Text(
            'Unila Helpdesk v2.4.0',
            textAlign: TextAlign.center,
            style: TextStyle(color: AppTheme.textMuted),
          ),
        ],
      ),
    );
  }
}

class _ProfileStat extends StatelessWidget {
  const _ProfileStat({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 4),
        Text(label, style: const TextStyle(color: AppTheme.textMuted)),
      ],
    );
  }
}

class _MenuTile extends StatelessWidget {
  const _MenuTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.outline),
      ),
      child: ListTile(
        onTap: onTap,
        leading: CircleAvatar(
          backgroundColor: AppTheme.surface,
          child: Icon(icon, color: AppTheme.navy),
        ),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w700)),
        subtitle: Text(
          subtitle,
          style: const TextStyle(color: AppTheme.textMuted),
        ),
        trailing: const Icon(Icons.chevron_right, color: AppTheme.textMuted),
      ),
    );
  }
}
