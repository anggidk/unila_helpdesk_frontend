import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:unila_helpdesk_frontend/app/app_providers.dart';
import 'package:unila_helpdesk_frontend/app/app_theme.dart';
import 'package:unila_helpdesk_frontend/core/models/survey_models.dart';
import 'package:unila_helpdesk_frontend/core/utils/date_utils.dart';
import 'package:unila_helpdesk_frontend/features/feedback/data/survey_repository.dart';

final adminSurveyHistorySearchProvider =
    StateProvider.autoDispose<String>((ref) => '');
final adminSurveyHistoryCategoryProvider =
    StateProvider.autoDispose<String?>((ref) => null);
final adminSurveyHistoryTemplateProvider =
    StateProvider.autoDispose<String?>((ref) => null);
final adminSurveyHistoryDateFilterProvider =
    StateProvider.autoDispose<_DateFilter>((ref) => _DateFilter.all);
final adminSurveyHistoryPageProvider =
    StateProvider.autoDispose<int>((ref) => 1);
final adminSurveyHistoryProvider =
    FutureProvider.autoDispose<SurveyResponsePage>((ref) async {
  final query = ref.watch(adminSurveyHistorySearchProvider);
  final categoryId = ref.watch(adminSurveyHistoryCategoryProvider);
  final templateId = ref.watch(adminSurveyHistoryTemplateProvider);
  final dateFilter = ref.watch(adminSurveyHistoryDateFilterProvider);
  final page = ref.watch(adminSurveyHistoryPageProvider);
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
  return SurveyRepository().fetchSurveyResponsesPaged(
    query: query,
    categoryId: categoryId,
    templateId: templateId,
    start: start,
    end: end,
    page: page,
    limit: 50,
  );
});

class AdminSurveyHistoryPage extends ConsumerStatefulWidget {
  const AdminSurveyHistoryPage({super.key});

  @override
  ConsumerState<AdminSurveyHistoryPage> createState() =>
      _AdminSurveyHistoryPageState();
}

class _AdminSurveyHistoryPageState
    extends ConsumerState<AdminSurveyHistoryPage> {
  late final TextEditingController _searchController;

  @override
  void initState() {
    super.initState();
    _searchController =
        TextEditingController(text: ref.read(adminSurveyHistorySearchProvider));
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final responsesAsync = ref.watch(adminSurveyHistoryProvider);
    final categoriesAsync = ref.watch(serviceCategoriesProvider);
    final templatesAsync = ref.watch(surveyTemplatesProvider);
    final categories = (categoriesAsync.value ?? [])
        .where((category) => !category.guestAllowed)
        .toList();
    final templates = templatesAsync.value ?? [];
    final selectedCategoryId = ref.watch(adminSurveyHistoryCategoryProvider);
    final selectedTemplateId = ref.watch(adminSurveyHistoryTemplateProvider);
    final dateFilter = ref.watch(adminSurveyHistoryDateFilterProvider);
    final pageIndex = ref.watch(adminSurveyHistoryPageProvider);
    final responsePage = responsesAsync.value;
    final rows = responsePage?.items ?? [];
    final totalPages = responsePage?.totalPages ?? 1;
    final searchValue = ref.watch(adminSurveyHistorySearchProvider);
    if (_searchController.text != searchValue) {
      _searchController.text = searchValue;
      _searchController.selection = TextSelection.collapsed(
        offset: _searchController.text.length,
      );
    }
    if (responsePage != null && pageIndex > totalPages && totalPages > 0) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ref.read(adminSurveyHistoryPageProvider.notifier).state = totalPages;
      });
    }

    final categoryLabel = selectedCategoryId == null
        ? 'All'
        : categories
            .where((item) => item.id == selectedCategoryId)
            .map((item) => item.name)
            .firstWhere((_) => true, orElse: () => selectedCategoryId);
    final templateLabel = selectedTemplateId == null
        ? 'All'
        : templates
            .where((item) => item.id == selectedTemplateId)
            .map((item) => item.title)
            .firstWhere((_) => true, orElse: () => selectedTemplateId);

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
                    ref.read(adminSurveyHistorySearchProvider.notifier).state =
                        value;
                    ref.read(adminSurveyHistoryPageProvider.notifier).state = 1;
                  },
                  decoration: const InputDecoration(
                    hintText: 'Search by ticket ID or user...',
                    prefixIcon: Icon(Icons.search),
                    suffixIcon: null,
                  ).copyWith(
                    suffixIcon: searchValue.isEmpty
                        ? null
                        : IconButton(
                            onPressed: () {
                              ref.read(adminSurveyHistorySearchProvider.notifier).state = '';
                              ref.read(adminSurveyHistoryPageProvider.notifier).state = 1;
                              _searchController.clear();
                            },
                            icon: const Icon(Icons.close),
                            tooltip: 'Hapus',
                          ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              _FilterDropdown<String?>(
                label: 'Kategori',
                icon: Icons.category_outlined,
                valueLabel: categoryLabel,
                enabled: categories.isNotEmpty,
                options: {
                  null: 'All',
                  for (final category in categories) category.id: category.name,
                },
                onChanged: (value) {
                  ref.read(adminSurveyHistoryCategoryProvider.notifier).state =
                      value;
                  ref.read(adminSurveyHistoryPageProvider.notifier).state = 1;
                },
              ),
              const SizedBox(width: 12),
              _FilterDropdown<String?>(
                label: 'Template',
                icon: Icons.layers_outlined,
                valueLabel: templateLabel,
                enabled: templates.isNotEmpty,
                options: {
                  null: 'All',
                  for (final template in templates)
                    template.id: template.title,
                },
                onChanged: (value) {
                  ref.read(adminSurveyHistoryTemplateProvider.notifier).state =
                      value;
                  ref.read(adminSurveyHistoryPageProvider.notifier).state = 1;
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
                  ref.read(adminSurveyHistoryDateFilterProvider.notifier).state =
                      value;
                  ref.read(adminSurveyHistoryPageProvider.notifier).state = 1;
                },
              ),
              const SizedBox(width: 12),
              OutlinedButton.icon(
                onPressed: () {
                  ref.read(adminSurveyHistorySearchProvider.notifier).state = '';
                  ref.read(adminSurveyHistoryCategoryProvider.notifier).state =
                      null;
                  ref.read(adminSurveyHistoryTemplateProvider.notifier).state =
                      null;
                  ref.read(adminSurveyHistoryDateFilterProvider.notifier).state =
                      _DateFilter.all;
                  ref.read(adminSurveyHistoryPageProvider.notifier).state = 1;
                  _searchController.clear();
                },
                icon: const Icon(Icons.refresh, size: 18),
                label: const Text('Reset'),
              ),
            ],
          ),
          const SizedBox(height: 20),
          if (responsesAsync.isLoading)
            const Center(child: CircularProgressIndicator()),
          if (responsesAsync.hasError)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Text(
                'Gagal memuat survey: ${responsesAsync.error}',
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
                if (!responsesAsync.isLoading &&
                    !responsesAsync.hasError &&
                    rows.isEmpty)
                  const Padding(
                    padding: EdgeInsets.only(bottom: 12),
                    child: Text(
                      'Tidak ada survey yang sesuai filter.',
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
                              'Ticket ID',
                              style: TextStyle(fontWeight: FontWeight.w600),
                            ),
                          ),
                          DataColumn(
                            label: Text(
                              'User',
                              style: TextStyle(fontWeight: FontWeight.w600),
                            ),
                          ),
                          DataColumn(
                            label: Text(
                              'Entitas',
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
                              'Template',
                              style: TextStyle(fontWeight: FontWeight.w600),
                            ),
                          ),
                          DataColumn(
                            label: Text(
                              'Skor',
                              style: TextStyle(fontWeight: FontWeight.w600),
                            ),
                          ),
                          DataColumn(
                            label: Text(
                              'Tanggal',
                              style: TextStyle(fontWeight: FontWeight.w600),
                            ),
                          ),
                        ],
                        rows: rows.map((row) {
                          final userName = row.userName.isEmpty ? '-' : row.userName;
                          final userEmail = row.userEmail.isEmpty ? '-' : row.userEmail;
                          final category = row.category.isEmpty ? row.categoryId : row.category;
                          final template = row.template.isEmpty ? row.templateId : row.template;
                          return DataRow(
                            cells: [
                              DataCell(Text(row.ticketId)),
                              DataCell(
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text(
                                      userName,
                                      style: const TextStyle(fontWeight: FontWeight.w600),
                                    ),
                                    Text(
                                      userEmail,
                                      style: const TextStyle(color: AppTheme.textMuted),
                                    ),
                                  ],
                                ),
                              ),
                              DataCell(Text(row.userEntity)),
                              DataCell(Text(category)),
                              DataCell(Text(template)),
                              DataCell(Text(row.score.toStringAsFixed(2))),
                              DataCell(Text(formatDate(row.createdAt))),
                            ],
                          );
                        }).toList(),
                      ),
                    ),
                  ),
                ),
                if (responsePage != null && responsePage.totalPages > 1)
                  Padding(
                    padding: const EdgeInsets.only(top: 12),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Halaman ${responsePage.page} dari ${responsePage.totalPages} • Total ${responsePage.total}',
                          style: const TextStyle(color: AppTheme.textMuted),
                        ),
                        Row(
                          children: [
                            OutlinedButton(
                              onPressed: responsePage.hasPrev
                                  ? () => ref
                                      .read(adminSurveyHistoryPageProvider.notifier)
                                      .state = responsePage.page - 1
                                  : null,
                              child: const Text('Sebelumnya'),
                            ),
                            const SizedBox(width: 8),
                            ElevatedButton(
                              onPressed: responsePage.hasNext
                                  ? () => ref
                                      .read(adminSurveyHistoryPageProvider.notifier)
                                      .state = responsePage.page + 1
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
        return 'All';
    }
  }
}
