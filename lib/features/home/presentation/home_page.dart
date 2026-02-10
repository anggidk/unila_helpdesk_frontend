import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:unila_helpdesk_frontend/app/app_router.dart';
import 'package:unila_helpdesk_frontend/app/app_theme.dart';
import 'package:unila_helpdesk_frontend/core/models/user_models.dart';
import 'package:unila_helpdesk_frontend/core/widgets/user_top_app_bar.dart';
import 'package:unila_helpdesk_frontend/features/home/application/home_provider.dart';
import 'package:unila_helpdesk_frontend/features/home/domain/home_models.dart';
import 'package:unila_helpdesk_frontend/features/tickets/presentation/widgets/ticket_card.dart';
import 'package:unila_helpdesk_frontend/features/user/presentation/style_15_bottom_nav_bar.widget.dart';

class HomePage extends ConsumerWidget {
  const HomePage({super.key, required this.user});

  final UserProfile user;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final summaryAsync = ref.watch(homeSummaryProvider(user));

    return Scaffold(
      appBar: UserTopAppBar(
        titleText: 'Beranda',
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
      padding: EdgeInsets.fromLTRB(
        20,
        20,
        20,
        20 + Style15BottomNavBar.heightFor(context),
      ),
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
              label: 'Menunggu',
              value: '${summary.waitingCount}',
              color: AppTheme.danger,
              icon: Icons.hourglass_bottom_rounded,
            ),
            const SizedBox(width: 12),
            _StatCard(
              label: 'Diproses',
              value: '${summary.activeCount}',
              color: AppTheme.warning,
              icon: Icons.confirmation_number_outlined,
            ),
            const SizedBox(width: 12),
            _StatCard(
              label: 'Selesai',
              value: '${summary.resolvedCount}',
              color: AppTheme.success,
              icon: Icons.check_rounded,
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
              foregroundColor: AppTheme.unilaBlack,
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
              onPressed: () => context.pushNamed(AppRouteNames.tickets),
              child: const Text('Lihat Semua'),
            ),
          ],
        ),
        const SizedBox(height: 8),
        ...summary.recentTickets.map(
          (ticket) => TicketCard(
            ticket: ticket,
            onTap: () {
              context.pushNamed(AppRouteNames.ticketDetail, extra: ticket);
            },
          ),
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
    required this.icon,
  });

  final String label;
  final String value;
  final Color color;
  final IconData icon;

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
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(height: 8),
            Text(label, style: const TextStyle(color: AppTheme.textMuted)),
            const SizedBox(height: 6),
            Text(
              value,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
