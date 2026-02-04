import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:unila_helpdesk_frontend/app/app_providers.dart';
import 'package:unila_helpdesk_frontend/app/app_theme.dart';
import 'package:unila_helpdesk_frontend/core/models/ticket_models.dart';
import 'package:unila_helpdesk_frontend/core/utils/date_utils.dart';
import 'package:unila_helpdesk_frontend/features/tickets/data/ticket_repository.dart';

final adminTicketSearchProvider = StateProvider.autoDispose<String>((ref) => '');
final adminTicketStatusFilterProvider =
    StateProvider.autoDispose<TicketStatus?>((ref) => null);
final adminTicketCategoryFilterProvider =
    StateProvider.autoDispose<String?>((ref) => null);
final adminTicketDateFilterProvider =
    StateProvider.autoDispose<_DateFilter>((ref) => _DateFilter.all);
final adminTicketPageProvider = StateProvider.autoDispose<int>((ref) => 1);
final adminTicketsProvider =
    FutureProvider.autoDispose<TicketPage>((ref) async {
  final query = ref.watch(adminTicketSearchProvider);
  final status = ref.watch(adminTicketStatusFilterProvider);
  final categoryId = ref.watch(adminTicketCategoryFilterProvider);
  final dateFilter = ref.watch(adminTicketDateFilterProvider);
  final page = ref.watch(adminTicketPageProvider);
  final now = DateTime.now();
  DateTime? start;
  DateTime? end;
  switch (dateFilter) {
    case _DateFilter.today:
      start = DateTime(now.year, now.month, now.day);
      end = start.add(const Duration(days: 1));
      break;
    case _DateFilter.last7Days:
      start = now.subtract(const Duration(days: 7));
      end = now;
      break;
    case _DateFilter.last30Days:
      start = now.subtract(const Duration(days: 30));
      end = now;
      break;
    case _DateFilter.all:
      break;
  }
  return TicketRepository().fetchTicketsPaged(
    query: query,
    status: status?.name,
    categoryId: categoryId,
    start: start,
    end: end,
    page: page,
    limit: 15,
  );
});

class AdminTicketsPage extends ConsumerStatefulWidget {
  const AdminTicketsPage({super.key});

  @override
  ConsumerState<AdminTicketsPage> createState() => _AdminTicketsPageState();
}

class _AdminTicketsPageState extends ConsumerState<AdminTicketsPage> {
  late final TextEditingController _searchController;

  @override
  void initState() {
    super.initState();
    _searchController =
        TextEditingController(text: ref.read(adminTicketSearchProvider));
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ticketsAsync = ref.watch(adminTicketsProvider);
    final categoriesAsync = ref.watch(serviceCategoriesProvider);
    final categories = (categoriesAsync.value ?? [])
        .where((category) => !category.guestAllowed)
        .toList();
    final selectedStatus = ref.watch(adminTicketStatusFilterProvider);
    final selectedCategoryId = ref.watch(adminTicketCategoryFilterProvider);
    final dateFilter = ref.watch(adminTicketDateFilterProvider);
    final pageIndex = ref.watch(adminTicketPageProvider);
    final ticketPage = ticketsAsync.value;
    final tickets = ticketPage?.items ?? [];
    final totalPages = ticketPage?.totalPages ?? 1;
    final searchValue = ref.watch(adminTicketSearchProvider);
    if (_searchController.text != searchValue) {
      _searchController.text = searchValue;
      _searchController.selection = TextSelection.collapsed(
        offset: _searchController.text.length,
      );
    }
    if (ticketPage != null && pageIndex > totalPages && totalPages > 0) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ref.read(adminTicketPageProvider.notifier).state = totalPages;
      });
    }
    final categoryLabel = selectedCategoryId == null
        ? 'Semua'
        : categories
            .where((item) => item.id == selectedCategoryId)
            .map((item) => item.name)
            .firstWhere((_) => true, orElse: () => selectedCategoryId);
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _searchController,
                  onChanged: (value) {
                    ref.read(adminTicketSearchProvider.notifier).state = value;
                    ref.read(adminTicketPageProvider.notifier).state = 1;
                  },
                  decoration: const InputDecoration(
                    hintText: 'Cari berdasarkan ID tiket atau judul...',
                    prefixIcon: Icon(Icons.search),
                    suffixIcon: null,
                  ).copyWith(
                    suffixIcon: searchValue.isEmpty
                        ? null
                        : IconButton(
                            onPressed: () {
                              ref.read(adminTicketSearchProvider.notifier).state = '';
                              ref.read(adminTicketPageProvider.notifier).state = 1;
                              _searchController.clear();
                            },
                            icon: const Icon(Icons.close),
                            tooltip: 'Hapus',
                          ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              _FilterDropdown<TicketStatus?>(
                label: 'Status',
                icon: Icons.filter_list,
                valueLabel: selectedStatus?.label ?? 'Semua',
                enabled: true,
                options: {
                  null: 'Semua',
                  for (final status in TicketStatus.values) status: status.label,
                },
                onChanged: (value) {
                  ref.read(adminTicketStatusFilterProvider.notifier).state = value;
                  ref.read(adminTicketPageProvider.notifier).state = 1;
                },
              ),
              const SizedBox(width: 12),
              _FilterDropdown<String?>(
                label: 'Kategori',
                icon: Icons.category_outlined,
                valueLabel: categoryLabel,
                enabled: categories.isNotEmpty,
                options: {
                  null: 'Semua',
                  for (final category in categories) category.id: category.name,
                },
                onChanged: (value) {
                  ref.read(adminTicketCategoryFilterProvider.notifier).state = value;
                  ref.read(adminTicketPageProvider.notifier).state = 1;
                },
              ),
              const SizedBox(width: 12),
              _FilterDropdown<_DateFilter>(
                label: 'Tanggal',
                icon: Icons.calendar_today_outlined,
                valueLabel: dateFilter.label,
                enabled: true,
                options: {
                  for (final filter in _DateFilter.values) filter: filter.label,
                },
                onChanged: (value) {
                  ref.read(adminTicketDateFilterProvider.notifier).state = value;
                  ref.read(adminTicketPageProvider.notifier).state = 1;
                },
              ),
              const SizedBox(width: 12),
              OutlinedButton.icon(
                onPressed: () {
                  ref.read(adminTicketSearchProvider.notifier).state = '';
                  ref.read(adminTicketStatusFilterProvider.notifier).state = null;
                  ref.read(adminTicketCategoryFilterProvider.notifier).state = null;
                  ref.read(adminTicketDateFilterProvider.notifier).state =
                      _DateFilter.all;
                  ref.read(adminTicketPageProvider.notifier).state = 1;
                  _searchController.clear();
                },
                icon: const Icon(Icons.refresh, size: 18),
                label: const Text('Atur Ulang'),
              ),
            ],
          ),
          const SizedBox(height: 20),
          if (ticketsAsync.isLoading)
            const Center(child: CircularProgressIndicator()),
          if (ticketsAsync.hasError)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Text(
                'Gagal memuat tiket: ${ticketsAsync.error}',
                style: const TextStyle(color: AppTheme.textMuted),
              ),
            ),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppTheme.outline),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (!ticketsAsync.isLoading &&
                    !ticketsAsync.hasError &&
                    tickets.isEmpty)
                  const Padding(
                    padding: EdgeInsets.only(bottom: 12),
                    child: Text(
                      'Tidak ada tiket yang sesuai filter.',
                      style: TextStyle(color: AppTheme.textMuted),
                    ),
                  ),
                LayoutBuilder(
                  builder: (context, constraints) => SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: ConstrainedBox(
                      constraints: BoxConstraints(minWidth: constraints.maxWidth),
                      child: DataTable(
                        headingRowColor: WidgetStateProperty.all(AppTheme.surface),
                        columns: const [
                          DataColumn(
                            label: Text(
                              'ID Tiket',
                              style: TextStyle(fontWeight: FontWeight.w600),
                            ),
                          ),
                          DataColumn(
                            label: Text(
                              'Judul',
                              style: TextStyle(fontWeight: FontWeight.w600),
                            ),
                          ),
                          DataColumn(
                            label: Text(
                              'Kategori',
                              style: TextStyle(fontWeight: FontWeight.w600),
                            ),
                          ),
                          DataColumn(
                            label: Text(
                              'Tanggal',
                              style: TextStyle(fontWeight: FontWeight.w600),
                            ),
                          ),
                          DataColumn(
                            label: Text(
                              'Status',
                              style: TextStyle(fontWeight: FontWeight.w600),
                            ),
                          ),
                          DataColumn(
                            label: Text(
                              'Aksi',
                              style: TextStyle(fontWeight: FontWeight.w600),
                            ),
                          ),
                        ],
                        rows: tickets.map((ticket) {
                          return DataRow(
                            cells: [
                              DataCell(Text(ticket.id)),
                              DataCell(
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text(
                                      ticket.title,
                                      style: const TextStyle(fontWeight: FontWeight.w600),
                                    ),
                                    Text(
                                      'Dilaporkan oleh: ${ticket.reporter}',
                                      style: const TextStyle(color: AppTheme.textMuted),
                                    ),
                                  ],
                                ),
                              ),
                              DataCell(Text(ticket.category)),
                              DataCell(Text(formatDate(ticket.createdAt))),
                              DataCell(_StatusChip(label: ticket.status.label)),
                              DataCell(
                                IconButton(
                                  onPressed: () {},
                                  icon: const Icon(Icons.more_horiz),
                                ),
                              ),
                            ],
                          );
                        }).toList(),
                      ),
                    ),
                  ),
                ),
                if (ticketPage != null && ticketPage.totalPages > 1)
                  Padding(
                    padding: const EdgeInsets.only(top: 12),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Halaman ${ticketPage.page} dari ${ticketPage.totalPages} • Total ${ticketPage.total}',
                          style: const TextStyle(color: AppTheme.textMuted),
                        ),
                        Row(
                          children: [
                            OutlinedButton(
                              onPressed: ticketPage.hasPrev
                                  ? () => ref
                                      .read(adminTicketPageProvider.notifier)
                                      .state = ticketPage.page - 1
                                  : null,
                              child: const Text('Sebelumnya'),
                            ),
                            const SizedBox(width: 8),
                            ElevatedButton(
                              onPressed: ticketPage.hasNext
                                  ? () => ref
                                      .read(adminTicketPageProvider.notifier)
                                      .state = ticketPage.page + 1
                                  : null,
                              child: const Text('Berikutnya'),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _FilterDropdown<T> extends StatelessWidget {
  const _FilterDropdown({
    required this.label,
    required this.icon,
    required this.valueLabel,
    required this.enabled,
    required this.options,
    required this.onChanged,
  });

  final String label;
  final IconData icon;
  final String valueLabel;
  final bool enabled;
  final Map<T, String> options;
  final ValueChanged<T> onChanged;

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<T>(
      onSelected: enabled ? onChanged : null,
      itemBuilder: (context) => options.entries
          .map(
            (entry) => PopupMenuItem<T>(
              value: entry.key,
              child: Text(entry.value),
            ),
          )
          .toList(),
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
              icon,
              size: 18,
              color: enabled ? AppTheme.textPrimary : AppTheme.textMuted,
            ),
            const SizedBox(width: 6),
            Text(
              '$label: $valueLabel',
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

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    Color color = AppTheme.accentBlue;
    if (label.toLowerCase().contains('selesai')) {
      color = AppTheme.success;
    } else if (label.toLowerCase().contains('menunggu')) {
      color = AppTheme.warning;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Text(
        label,
        style: TextStyle(color: color, fontWeight: FontWeight.w700),
      ),
    );
  }
}

enum _DateFilter { all, today, last7Days, last30Days }

extension _DateFilterX on _DateFilter {
  String get label {
    switch (this) {
      case _DateFilter.today:
        return 'Hari ini';
      case _DateFilter.last7Days:
        return '7 hari';
      case _DateFilter.last30Days:
        return '30 hari';
      case _DateFilter.all:
        return 'Semua';
    }
  }
}
