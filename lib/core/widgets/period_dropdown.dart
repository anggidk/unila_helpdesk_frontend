import 'package:flutter/material.dart';
import 'package:unila_helpdesk_frontend/app/app_theme.dart';
import 'package:unila_helpdesk_frontend/core/utils/period_utils.dart';

class PeriodDropdown extends StatelessWidget {
  const PeriodDropdown({
    super.key,
    required this.value,
    required this.onChanged,
    this.enabled = true,
    this.prefix = 'Periode',
  });

  final String value;
  final ValueChanged<String> onChanged;
  final bool enabled;
  final String prefix;

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<String>(
      onSelected: enabled ? onChanged : null,
      itemBuilder: (context) => const [
        PopupMenuItem(value: 'daily', child: Text('Harian')),
        PopupMenuItem(value: 'weekly', child: Text('Mingguan')),
        PopupMenuItem(value: 'monthly', child: Text('Bulanan')),
        PopupMenuItem(value: 'yearly', child: Text('Tahunan')),
      ],
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          border: Border.all(
            color: enabled ? AppTheme.outline : AppTheme.outline.withValues(alpha: 0.4),
          ),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          children: [
            Icon(
              Icons.expand_more,
              size: 18,
              color: enabled ? AppTheme.textPrimary : AppTheme.textMuted,
            ),
            const SizedBox(width: 6),
            Text(
              '$prefix: ${periodLabel(value)}',
              style: TextStyle(
                color: enabled ? AppTheme.textPrimary : AppTheme.textMuted,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
