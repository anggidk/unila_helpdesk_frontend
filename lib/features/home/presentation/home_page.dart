import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:unila_helpdesk_frontend/app/app_router.dart';
import 'package:unila_helpdesk_frontend/app/app_theme.dart';
import 'package:unila_helpdesk_frontend/core/models/ticket_models.dart';
import 'package:unila_helpdesk_frontend/core/models/user_models.dart';
import 'package:unila_helpdesk_frontend/core/widgets/badges.dart';
import 'package:unila_helpdesk_frontend/features/home/application/home_provider.dart';
import 'package:unila_helpdesk_frontend/features/home/domain/home_models.dart';

class HomePage extends ConsumerWidget {
  const HomePage({super.key, required this.user});

  final UserProfile user;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final summaryAsync = ref.watch(homeSummaryProvider(user));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Home'),
        actions: [
          IconButton(
            onPressed: () {
              context.pushNamed(AppRouteNames.notifications);
            },
            icon: const Icon(Icons.notifications_none),
          ),
        ],
      ),
      body: summaryAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(
          child: Text(
            'Gagal memuat data home.',
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: AppTheme.danger),
          ),
        ),
        data: (summary) => _HomeContent(summary: summary),
      ),
    );
  }
}

class _HomeContent extends StatelessWidget {
  const _HomeContent({required this.summary});

  final HomeSummary summary;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Row(
          children: [
            CircleAvatar(
              radius: 24,
              backgroundColor: AppTheme.accentBlue.withValues(alpha: 0.1),
              child: const Icon(Icons.person, color: AppTheme.accentBlue),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Selamat Datang,',
                    style: TextStyle(color: AppTheme.textMuted),
                  ),
                  Text(
                    summary.user.name,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  Text(
                    summary.user.entity,
                    style: const TextStyle(color: AppTheme.textMuted),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),
        Row(
          children: [
            _StatCard(
              label: 'Aktif',
              value: '${summary.activeCount}',
              color: AppTheme.accentBlue,
            ),
            const SizedBox(width: 12),
            _StatCard(
              label: 'Selesai',
              value: '${summary.resolvedCount}',
              color: AppTheme.success,
            ),
            const SizedBox(width: 12),
            _StatCard(
              label: 'Menunggu',
              value: '${summary.waitingCount}',
              color: AppTheme.warning,
            ),
          ],
        ),
        const SizedBox(height: 20),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: () {
              context.pushNamed(AppRouteNames.ticketForm);
            },
            icon: const Icon(Icons.add),
            label: const Text('BUAT TIKET BARU'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.accentYellow,
              foregroundColor: AppTheme.navy,
            ),
          ),
        ),
        const SizedBox(height: 24),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Tiket Terbaru',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
            ),
            TextButton(
              onPressed: () =>
                  context.pushNamed(AppRouteNames.tickets, extra: summary.user),
              child: const Text('Lihat Semua'),
            ),
          ],
        ),
        const SizedBox(height: 8),
        ...summary.recentTickets.map(
          (ticket) => _TicketPreview(ticket: ticket),
        ),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.label,
    required this.value,
    required this.color,
  });

  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppTheme.outline),
        ),
        child: Column(
          children: [
            CircleAvatar(
              backgroundColor: color.withValues(alpha: 0.15),
              child: Icon(Icons.circle, color: color, size: 16),
            ),
            const SizedBox(height: 8),
            Text(label, style: const TextStyle(color: AppTheme.textMuted)),
            const SizedBox(height: 6),
            Text(
              value,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
            ),
          ],
        ),
      ),
    );
  }
}

class _TicketPreview extends StatelessWidget {
  const _TicketPreview({required this.ticket});

  final Ticket ticket;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.outline),
      ),
      child: InkWell(
        onTap: () {
          context.pushNamed(AppRouteNames.ticketDetail, extra: ticket);
        },
        child: Row(
          children: [
            CircleAvatar(
              backgroundColor: AppTheme.surface,
              child: Icon(Icons.wifi, color: AppTheme.accentBlue),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    ticket.title,
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    ticket.id,
                    style: const TextStyle(color: AppTheme.textMuted),
                  ),
                ],
              ),
            ),
            StatusBadge(status: ticket.status),
          ],
        ),
      ),
    );
  }
}
