import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:unila_helpdesk_frontend/app/app_router.dart';
import 'package:unila_helpdesk_frontend/app/app_providers.dart';
import 'package:unila_helpdesk_frontend/app/app_theme.dart';
import 'package:unila_helpdesk_frontend/core/models/survey_models.dart';
import 'package:unila_helpdesk_frontend/core/models/ticket_models.dart';
import 'package:unila_helpdesk_frontend/core/utils/date_utils.dart';
import 'package:unila_helpdesk_frontend/features/user/presentation/style_15_bottom_nav_bar.widget.dart';

class FeedbackPage extends ConsumerWidget {
  const FeedbackPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ticketsAsync = ref.watch(ticketsProvider);
    final resolvedTickets = (ticketsAsync.value ?? [])
        .where((ticket) => ticket.status == TicketStatus.resolved)
        .toList();
    final pending =
        resolvedTickets.where((ticket) => ticket.surveyRequired).toList();
    final filled =
        resolvedTickets.where((ticket) => !ticket.surveyRequired).toList();

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
      padding: EdgeInsets.fromLTRB(
        20,
        20,
        20,
        20 + Style15BottomNavBar.heightFor(context),
      ),
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
                      SurveyTemplate template;
                      try {
                        template = await ref
                            .refresh(surveyTemplateByCategoryProvider(categoryId).future);
                      } catch (error) {
                        if (!context.mounted) return;
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text(error.toString())),
                        );
                        return;
                      }
                      if (template.questions.isEmpty) {
                        if (!context.mounted) return;
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Template survey belum memiliki pertanyaan.'),
                          ),
                        );
                        return;
                      }
                      if (!context.mounted) return;
                      await context.pushNamed(
                        AppRouteNames.survey,
                        extra: SurveyPayload(ticket: ticket, template: template),
                      );
                      ref.invalidate(ticketsProvider);
                    },
                    icon: const Icon(Icons.rate_review_outlined),
                    label: const Text('ISI FEEDBACK'),
                    style: ElevatedButton.styleFrom(backgroundColor: AppTheme.accentYellow, foregroundColor: AppTheme.navy),
                  ),
                ),
              if (!showAction)
                _RatingRow(score: ticket.surveyScore),
            ],
          ),
        );
      },
    );
  }
}

class _RatingRow extends StatelessWidget {
  const _RatingRow({required this.score});

  final double score;

  @override
  Widget build(BuildContext context) {
    if (score <= 0) {
      return const Text('Rating belum tersedia.');
    }
    final clamped = score.clamp(0, 5);
    final fullStars = clamped.floor();
    final hasHalf = (clamped - fullStars) >= 0.5;
    final emptyStars = 5 - fullStars - (hasHalf ? 1 : 0);
    final stars = <Widget>[];
    for (var i = 0; i < fullStars; i++) {
      stars.add(const Icon(Icons.star, color: AppTheme.accentYellow));
    }
    if (hasHalf) {
      stars.add(const Icon(Icons.star_half, color: AppTheme.accentYellow));
    }
    for (var i = 0; i < emptyStars; i++) {
      stars.add(const Icon(Icons.star_border, color: AppTheme.textMuted));
    }
    return Row(
      children: [
        Text('Rating Anda: ${clamped.toStringAsFixed(1)}'),
        const SizedBox(width: 8),
        ...stars,
      ],
    );
  }
}

