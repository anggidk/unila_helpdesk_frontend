import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:unila_helpdesk_frontend/app/app_router.dart';
import 'package:unila_helpdesk_frontend/app/app_theme.dart';
import 'package:unila_helpdesk_frontend/core/models/ticket_models.dart';
import 'package:unila_helpdesk_frontend/core/utils/date_utils.dart';
import 'package:unila_helpdesk_frontend/core/widgets/badges.dart';
import 'package:unila_helpdesk_frontend/features/tickets/data/ticket_repository.dart';

class TicketDetailPage extends ConsumerStatefulWidget {
  const TicketDetailPage({super.key, required this.ticket});

  final Ticket ticket;

  @override
  ConsumerState<TicketDetailPage> createState() => _TicketDetailPageState();
}

class _TicketDetailPageState extends ConsumerState<TicketDetailPage> {
  bool _isDeleting = false;

  void _handleMenu(String value) {
    if (value == 'edit') {
      context.pushNamed(AppRouteNames.ticketForm, extra: widget.ticket);
    } else if (value == 'delete') {
      showDialog<void>(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text('Hapus Tiket'),
          content: const Text('Apakah Anda yakin ingin menghapus tiket ini?'),
          actions: [
            TextButton(
              onPressed: () => context.pop(),
              child: const Text('Batal'),
            ),
            ElevatedButton(
              onPressed: _isDeleting
                  ? null
                  : () async {
                      setState(() => _isDeleting = true);
                      final response =
                          await TicketRepository().deleteTicket(widget.ticket.id);
                      if (!mounted) return;
                      if (!response.isSuccess) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              response.error?.message ?? 'Gagal menghapus tiket.',
                            ),
                          ),
                        );
                        setState(() => _isDeleting = false);
                        return;
                      }
                      context.pop();
                      context.pop();
                    },
              child: _isDeleting
                  ? const SizedBox(
                      height: 16,
                      width: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Text('Hapus'),
            ),
          ],
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final ticket = widget.ticket;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Ticket Detail'),
        actions: [
          PopupMenuButton<String>(
            onSelected: _handleMenu,
            itemBuilder: (context) => const [
              PopupMenuItem(value: 'edit', child: Text('Edit Tiket')),
              PopupMenuItem(value: 'delete', child: Text('Hapus Tiket')),
            ],
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppTheme.outline),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      ticket.id,
                      style: const TextStyle(color: AppTheme.textMuted),
                    ),
                    StatusBadge(status: ticket.status),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  ticket.title,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    const Icon(
                      Icons.category_outlined,
                      size: 18,
                      color: AppTheme.textMuted,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      ticket.category,
                      style: const TextStyle(color: AppTheme.textMuted),
                    ),
                    const SizedBox(width: 16),
                    const Icon(
                      Icons.calendar_today_outlined,
                      size: 18,
                      color: AppTheme.textMuted,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      formatDate(ticket.createdAt),
                      style: const TextStyle(color: AppTheme.textMuted),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                PriorityBadge(priority: ticket.priority),
                const SizedBox(height: 12),
                Text(ticket.description),
              ],
            ),
          ),
          const SizedBox(height: 20),
          const Text(
            'Status History',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppTheme.outline),
            ),
            child: Column(
              children: ticket.history
                  .map(
                    (update) => ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: const CircleAvatar(
                        backgroundColor: AppTheme.surface,
                        child: Icon(Icons.person_outline, color: AppTheme.navy),
                      ),
                      title: Text(
                        update.title,
                        style: const TextStyle(fontWeight: FontWeight.w700),
                      ),
                      subtitle: Text(
                        '${update.description}\n${formatDateTime(update.timestamp)}',
                      ),
                    ),
                  )
                  .toList(),
            ),
          ),
          const SizedBox(height: 20),
          const Text(
            'Komentar',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 12),
          ...ticket.comments
              .where((comment) => comment.isStaff)
              .map((comment) => _CommentBubble(comment: comment)),
        ],
      ),
    );
  }
}

class _CommentBubble extends StatelessWidget {
  const _CommentBubble({required this.comment});

  final TicketComment comment;

  @override
  Widget build(BuildContext context) {
    final background = comment.isStaff ? AppTheme.surface : AppTheme.navy;
    final textColor = comment.isStaff ? AppTheme.textPrimary : Colors.white;
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: comment.isStaff
            ? MainAxisAlignment.start
            : MainAxisAlignment.end,
        children: [
          if (comment.isStaff)
            const CircleAvatar(
              backgroundColor: AppTheme.surface,
              child: Icon(Icons.person, color: AppTheme.navy),
            ),
          if (comment.isStaff) const SizedBox(width: 10),
          Flexible(
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: background,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    comment.author,
                    style: TextStyle(
                      color: textColor,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(comment.message, style: TextStyle(color: textColor)),
                  const SizedBox(height: 6),
                  Text(
                    formatTime(comment.timestamp),
                    style: TextStyle(
                      color: textColor.withValues(alpha: 0.7),
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (!comment.isStaff) const SizedBox(width: 10),
          if (!comment.isStaff)
            const CircleAvatar(
              backgroundColor: AppTheme.surface,
              child: Icon(Icons.person_outline, color: AppTheme.navy),
            ),
        ],
      ),
    );
  }
}
