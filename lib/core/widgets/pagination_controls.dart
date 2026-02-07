import 'package:flutter/material.dart';
import 'package:unila_helpdesk_frontend/app/app_theme.dart';

class PaginationControls extends StatelessWidget {
  const PaginationControls({
    super.key,
    required this.page,
    required this.totalPages,
    required this.totalItems,
    required this.hasPrev,
    required this.hasNext,
    required this.onPrev,
    required this.onNext,
    this.padding = const EdgeInsets.only(top: 12),
  });

  final int page;
  final int totalPages;
  final int totalItems;
  final bool hasPrev;
  final bool hasNext;
  final VoidCallback? onPrev;
  final VoidCallback? onNext;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    if (totalPages <= 1) {
      return const SizedBox.shrink();
    }
    return Padding(
      padding: padding,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            'Halaman $page dari $totalPages • Total $totalItems',
            style: const TextStyle(color: AppTheme.textMuted),
          ),
          Row(
            children: [
              OutlinedButton(
                onPressed: hasPrev ? onPrev : null,
                child: const Text('Sebelumnya'),
              ),
              const SizedBox(width: 8),
              ElevatedButton(
                onPressed: hasNext ? onNext : null,
                child: const Text('Berikutnya'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
