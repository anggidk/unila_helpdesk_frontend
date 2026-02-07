import 'package:flutter/material.dart';
import 'package:unila_helpdesk_frontend/app/app_theme.dart';
import 'package:unila_helpdesk_frontend/core/models/ticket_models.dart';

class RequiredLabel extends StatelessWidget {
  const RequiredLabel({super.key, required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return RichText(
      text: TextSpan(
        style: textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
        children: [
          TextSpan(text: text),
          const TextSpan(
            text: ' *',
            style: TextStyle(color: AppTheme.danger),
          ),
        ],
      ),
    );
  }
}

class PriorityChip extends StatelessWidget {
  const PriorityChip({
    super.key,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: selected ? AppTheme.navy.withValues(alpha: 0.08) : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: selected ? AppTheme.navy : AppTheme.outline,
            width: 1.2,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 16,
              height: 16,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: selected ? AppTheme.navy : AppTheme.textMuted,
                  width: 1.6,
                ),
              ),
              child: selected
                  ? Center(
                      child: Container(
                        width: 8,
                        height: 8,
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          color: AppTheme.navy,
                        ),
                      ),
                    )
                  : null,
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                color: selected ? AppTheme.navy : AppTheme.textMuted,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

List<Widget> buildCategoryLoadIndicators({
  required bool isLoading,
  Object? error,
}) {
  final widgets = <Widget>[];
  if (isLoading) {
    widgets.add(
      const Padding(
        padding: EdgeInsets.only(bottom: 12),
        child: LinearProgressIndicator(),
      ),
    );
  }
  if (error != null) {
    widgets.add(
      Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: Text(
          'Gagal memuat kategori: $error',
          style: const TextStyle(color: AppTheme.textMuted),
        ),
      ),
    );
  }
  return widgets;
}

class PrioritySelector extends StatelessWidget {
  const PrioritySelector({
    super.key,
    required this.selected,
    required this.onChanged,
  });

  final TicketPriority selected;
  final ValueChanged<TicketPriority> onChanged;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: TicketPriority.values.map((priority) {
        final isSelected = selected == priority;
        return Expanded(
          child: Padding(
            padding: EdgeInsets.only(
              right: priority == TicketPriority.high ? 0 : 8,
            ),
            child: PriorityChip(
              label: priority.label,
              selected: isSelected,
              onTap: () => onChanged(priority),
            ),
          ),
        );
      }).toList(),
    );
  }
}
