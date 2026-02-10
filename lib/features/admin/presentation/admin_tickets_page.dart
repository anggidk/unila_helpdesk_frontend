import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:unila_helpdesk_frontend/app/app_providers.dart';
import 'package:unila_helpdesk_frontend/app/app_theme.dart';
import 'package:unila_helpdesk_frontend/core/models/ticket_models.dart';
import 'package:unila_helpdesk_frontend/core/utils/date_filters.dart';
import 'package:unila_helpdesk_frontend/core/utils/date_utils.dart';
import 'package:unila_helpdesk_frontend/core/widgets/admin_filter_toolbar.dart';
import 'package:unila_helpdesk_frontend/core/widgets/badges.dart';
import 'package:unila_helpdesk_frontend/core/widgets/filter_dropdown.dart';
import 'package:unila_helpdesk_frontend/core/widgets/pagination_controls.dart';
import 'package:unila_helpdesk_frontend/features/tickets/data/ticket_repository.dart';

final adminTicketSearchProvider = StateProvider.autoDispose<String>((ref) => '');
final adminTicketStatusFilterProvider =
    StateProvider.autoDispose<TicketStatus?>((ref) => null);
final adminTicketCategoryFilterProvider =
    StateProvider.autoDispose<String?>((ref) => null);
final adminTicketDateFilterProvider =
    StateProvider.autoDispose<AdminDateFilter>((ref) => AdminDateFilter.all);
final adminTicketPageProvider = StateProvider.autoDispose<int>((ref) => 1);
const List<AdminDateFilter> _ticketDateFilters = [
  AdminDateFilter.all,
  AdminDateFilter.today,
  AdminDateFilter.last7Days,
  AdminDateFilter.last30Days,
];
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
  final range = adminDateRange(dateFilter, now);
  if (range != null) {
    start = range.start;
    end = range.end;
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
          AdminFilterToolbar(
            controller: _searchController,
            searchHintText: 'Cari berdasarkan nomor tiket atau judul...',
            searchValue: searchValue,
            onSearchChanged: (value) {
              ref.read(adminTicketSearchProvider.notifier).state = value;
              ref.read(adminTicketPageProvider.notifier).state = 1;
            },
            onClearSearch: () {
              ref.read(adminTicketSearchProvider.notifier).state = '';
              ref.read(adminTicketPageProvider.notifier).state = 1;
            },
            onReset: () {
              ref.read(adminTicketSearchProvider.notifier).state = '';
              ref.read(adminTicketStatusFilterProvider.notifier).state = null;
              ref.read(adminTicketCategoryFilterProvider.notifier).state = null;
              ref.read(adminTicketDateFilterProvider.notifier).state =
                  AdminDateFilter.all;
              ref.read(adminTicketPageProvider.notifier).state = 1;
            },
            filters: [
              FilterDropdown<TicketStatus?>(
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
              FilterDropdown<String?>(
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
              FilterDropdown<AdminDateFilter>(
                label: 'Tanggal',
                icon: Icons.calendar_today_outlined,
                valueLabel: dateFilter.label,
                enabled: true,
                options: {
                  for (final filter in _ticketDateFilters) filter: filter.label,
                },
                onChanged: (value) {
                  ref.read(adminTicketDateFilterProvider.notifier).state = value;
                  ref.read(adminTicketPageProvider.notifier).state = 1;
                },
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
                              'Nomor Tiket',
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
                              DataCell(Text(ticket.displayNumber)),
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
                              DataCell(StatusBadge(status: ticket.status)),
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
                if (ticketPage != null)
                  PaginationControls(
                    page: ticketPage.page,
                    totalPages: ticketPage.totalPages,
                    totalItems: ticketPage.total,
                    hasPrev: ticketPage.hasPrev,
                    hasNext: ticketPage.hasNext,
                    onPrev: () => ref
                        .read(adminTicketPageProvider.notifier)
                        .state = ticketPage.page - 1,
                    onNext: () => ref
                        .read(adminTicketPageProvider.notifier)
                        .state = ticketPage.page + 1,
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
