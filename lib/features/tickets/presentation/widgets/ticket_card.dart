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
        ticket.status == TicketStatus.waiting &&
        (onEdit != null || onDelete != null);
    final categoryColor = colorForTicketCategory(ticket.categoryId);
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
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
        borderRadius: BorderRadius.circular(14),
        child: Column(
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                CircleAvatar(
                  radius: 20,
                  backgroundColor: categoryColor.withValues(alpha: 0.12),
                  child: Icon(
                    iconForTicketCategory(ticket.categoryId),
                    color: categoryColor,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        ticket.title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${ticket.displayNumber} • ${ticket.category}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: AppTheme.textMuted,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    StatusBadge(status: ticket.status),
                    const SizedBox(width: 4),
                    const Icon(
                      Icons.chevron_right,
                      color: AppTheme.textMuted,
                      size: 20,
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 12),
            const Divider(height: 1, color: AppTheme.outline),
            const SizedBox(height: 10),
            Row(
              children: [
                PriorityBadge(priority: ticket.priority),
                const SizedBox(width: 8),
                Text(
                  formatDate(ticket.createdAt),
                  style: const TextStyle(
                    color: AppTheme.textMuted,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                if (canManage) const Spacer(),
                if (canManage && onEdit != null)
                  IconButton(
                    onPressed: onEdit,
                    tooltip: 'Edit',
                    visualDensity: VisualDensity.compact,
                    icon: const Icon(
                      Icons.edit_outlined,
                      size: 18,
                      color: AppTheme.accentBlue,
                    ),
                  ),
                if (canManage && onDelete != null)
                  IconButton(
                    onPressed: onDelete,
                    tooltip: 'Hapus',
                    visualDensity: VisualDensity.compact,
                    icon: const Icon(
                      Icons.delete_outline,
                      size: 18,
                      color: AppTheme.danger,
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

