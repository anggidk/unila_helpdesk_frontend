import 'package:flutter/material.dart';

class AdminFilterToolbar extends StatelessWidget {
  const AdminFilterToolbar({
    super.key,
    required this.controller,
    required this.searchHintText,
    required this.searchValue,
    required this.onSearchChanged,
    required this.onClearSearch,
    required this.onReset,
    this.filters = const [],
  });

  final TextEditingController controller;
  final String searchHintText;
  final String searchValue;
  final ValueChanged<String> onSearchChanged;
  final VoidCallback onClearSearch;
  final VoidCallback onReset;
  final List<Widget> filters;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: TextField(
            controller: controller,
            onChanged: onSearchChanged,
            decoration: InputDecoration(
              hintText: searchHintText,
              prefixIcon: const Icon(Icons.search),
            ).copyWith(
              suffixIcon: searchValue.isEmpty
                  ? null
                  : IconButton(
                      onPressed: () {
                        onClearSearch();
                        controller.clear();
                      },
                      icon: const Icon(Icons.close),
                      tooltip: 'Hapus',
                    ),
            ),
          ),
        ),
        for (final filter in filters) ...[
          const SizedBox(width: 12),
          filter,
        ],
        const SizedBox(width: 12),
        OutlinedButton.icon(
          onPressed: () {
            onReset();
            controller.clear();
          },
          icon: const Icon(Icons.refresh, size: 18),
          label: const Text('Atur Ulang'),
        ),
      ],
    );
  }
}
