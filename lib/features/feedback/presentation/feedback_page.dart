import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:unila_helpdesk_frontend/app/app_router.dart';
import 'package:unila_helpdesk_frontend/app/app_providers.dart';
import 'package:unila_helpdesk_frontend/app/app_theme.dart';
import 'package:unila_helpdesk_frontend/core/models/ticket_models.dart';
import 'package:unila_helpdesk_frontend/core/models/user_models.dart';
import 'package:unila_helpdesk_frontend/core/utils/date_utils.dart';

class FeedbackPage extends ConsumerWidget {
  const FeedbackPage({super.key, required this.user});

  final UserProfile user;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ticketsAsync = ref.watch(ticketsProvider);
    final resolvedTickets = (ticketsAsync.value ?? [])
        .where((ticket) => ticket.status == TicketStatus.resolved)
        .toList();
    final pending = resolvedTickets.take(1).toList();
    final filled = resolvedTickets.skip(1).toList();

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Feedback'),
          bottom: const TabBar(
            tabs: [
              Tab(text: 'Menunggu Feedback'),
              Tab(text: 'Sudah Diisi'),
            ],
          ),
        ),
        body: ticketsAsync.when(
          data: (_) => TabBarView(
            children: [
              _FeedbackList(
                tickets: pending,
                emptyText: 'Belum ada feedback yang menunggu.',
                showAction: true,
              ),
              _FeedbackList(
                tickets: filled,
                emptyText: 'Belum ada feedback yang diisi.',
                showAction: false,
              ),
            ],
          ),
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, _) => Center(
            child: Text('Gagal memuat tiket: $error'),
          ),
        ),
      ),
    );
  }
}

class _FeedbackList extends ConsumerWidget {
  const _FeedbackList({
    required this.tickets,
    required this.emptyText,
    required this.showAction,
  });

  final List<Ticket> tickets;
  final String emptyText;
  final bool showAction;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (tickets.isEmpty) {
      return Center(child: Text(emptyText));
    }
    return ListView.builder(
      padding: const EdgeInsets.all(20),
      itemCount: tickets.length,
      itemBuilder: (context, index) {
        final ticket = tickets[index];
        return Container(
          margin: const EdgeInsets.only(bottom: 16),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppTheme.outline),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const CircleAvatar(
                    backgroundColor: AppTheme.surface,
                    child: Icon(Icons.support_agent, color: AppTheme.navy),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Unila Helpdesk', style: TextStyle(color: AppTheme.textMuted)),
                        Text(
                          '${ticket.id} - ${ticket.title}',
                          style: const TextStyle(fontWeight: FontWeight.w700),
                        ),
                        const SizedBox(height: 4),
                        Text(formatDate(ticket.createdAt), style: const TextStyle(color: AppTheme.textMuted)),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppTheme.success.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(24),
                    ),
                    child: const Text('Selesai', style: TextStyle(color: AppTheme.success)),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              if (showAction)
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () async {
                      final categoryId = ticket.categoryId;
                      if (categoryId.isEmpty) {
                        if (!context.mounted) return;
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Kategori survey tidak ditemukan.')),
                        );
                        return;
                      }
                      final template =
                          await ref.read(surveyTemplateByCategoryProvider(categoryId).future);
                      if (!context.mounted) return;
                      context.pushNamed(
                        AppRouteNames.survey,
                        extra: SurveyPayload(ticket: ticket, template: template),
                      );
                    },
                    icon: const Icon(Icons.rate_review_outlined),
                    label: const Text('ISI FEEDBACK'),
                    style: ElevatedButton.styleFrom(backgroundColor: AppTheme.accentYellow, foregroundColor: AppTheme.navy),
                  ),
                ),
              if (!showAction)
                Row(
                  children: const [
                    Text('Rating Anda:'),
                    SizedBox(width: 8),
                    Icon(Icons.star, color: AppTheme.accentYellow),
                    Icon(Icons.star, color: AppTheme.accentYellow),
                    Icon(Icons.star, color: AppTheme.accentYellow),
                    Icon(Icons.star, color: AppTheme.accentYellow),
                    Icon(Icons.star_border, color: AppTheme.textMuted),
                  ],
                ),
            ],
          ),
        );
      },
    );
  }
}

