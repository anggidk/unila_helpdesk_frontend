import 'package:flutter/material.dart';
import 'package:unila_helpdesk_frontend/app/app_theme.dart';
import 'package:unila_helpdesk_frontend/core/models/ticket_models.dart';
import 'package:unila_helpdesk_frontend/core/utils/date_utils.dart';
import 'package:unila_helpdesk_frontend/core/utils/ticket_ui.dart';
import 'package:unila_helpdesk_frontend/core/widgets/badges.dart';

class TicketCard extends StatelessWidget {
  const TicketCard({
    super.key,
    required this.ticket,
    this.onTap,
    this.onEdit,
    this.onDelete,
  });

  final Ticket ticket;
  final VoidCallback? onTap;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;

  @override
  Widget build(BuildContext context) {
    final canManage =
        ticket.status != TicketStatus.resolved &&
        (onEdit != null || onDelete != null);
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppTheme.outline),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 14,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: InkWell(
        onTap: onTap,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CircleAvatar(
              backgroundColor: AppTheme.surface,
              child: Icon(iconForTicketCategory(ticket.category), color: AppTheme.accentBlue),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Text(
                          ticket.title,
                          style: const TextStyle(fontWeight: FontWeight.w700),
                        ),
                      ),
                      const SizedBox(width: 8),
                      StatusBadge(status: ticket.status),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    ticket.displayNumber,
                    style: const TextStyle(color: AppTheme.textMuted),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Icon(Icons.category_outlined, size: 16, color: AppTheme.textMuted),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          ticket.category,
                          style: const TextStyle(color: AppTheme.textMuted),
                        ),
                      ),
                      const Icon(Icons.calendar_today_outlined, size: 16, color: AppTheme.textMuted),
                      const SizedBox(width: 6),
                      Text(formatDate(ticket.createdAt), style: const TextStyle(color: AppTheme.textMuted)),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      PriorityBadge(priority: ticket.priority),
                      if (ticket.assignee != null) ...[
                        const SizedBox(width: 8),
                        _AssigneeChip(name: ticket.assignee!),
                      ],
                    ],
                  ),
                  if (canManage) ...[
                    const SizedBox(height: 10),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        if (onEdit != null)
                          TextButton.icon(
                            onPressed: onEdit,
                            icon: const Icon(Icons.edit_outlined, size: 16),
                            label: const Text('Edit'),
                            style: TextButton.styleFrom(
                              visualDensity: VisualDensity.compact,
                            ),
                          ),
                        if (onDelete != null)
                          TextButton.icon(
                            onPressed: onDelete,
                            icon: const Icon(Icons.delete_outline, size: 16),
                            label: const Text('Hapus'),
                            style: TextButton.styleFrom(
                              visualDensity: VisualDensity.compact,
                              foregroundColor: AppTheme.danger,
                            ),
                          ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: AppTheme.textMuted),
          ],
        ),
      ),
    );
  }
}

class _AssigneeChip extends StatelessWidget {
  const _AssigneeChip({required this.name});

  final String name;

  String get _initials {
    final parts = name.trim().split(' ');
    if (parts.length == 1) {
      return parts.first.substring(0, 1).toUpperCase();
    }
    return (parts.first.substring(0, 1) + parts.last.substring(0, 1)).toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.outline),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 10,
            backgroundColor: AppTheme.accentBlue.withValues(alpha: 0.15),
            child: Text(
              _initials,
              style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: AppTheme.accentBlue),
            ),
          ),
          const SizedBox(width: 6),
          Text(
            name,
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}

