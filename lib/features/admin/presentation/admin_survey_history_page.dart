import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:unila_helpdesk_frontend/app/app_providers.dart';
import 'package:unila_helpdesk_frontend/app/app_theme.dart';
import 'package:unila_helpdesk_frontend/core/models/survey_models.dart';
import 'package:unila_helpdesk_frontend/core/utils/date_filters.dart';
import 'package:unila_helpdesk_frontend/core/utils/date_utils.dart';
import 'package:unila_helpdesk_frontend/core/utils/score_utils.dart';
import 'package:unila_helpdesk_frontend/core/widgets/admin_filter_toolbar.dart';
import 'package:unila_helpdesk_frontend/core/widgets/filter_dropdown.dart';
import 'package:unila_helpdesk_frontend/core/widgets/pagination_controls.dart';
import 'package:unila_helpdesk_frontend/features/feedback/data/survey_repository.dart';

final adminSurveyHistorySearchProvider = StateProvider.autoDispose<String>(
  (ref) => '',
);
final adminSurveyHistoryCategoryProvider = StateProvider.autoDispose<String?>(
  (ref) => null,
);
final adminSurveyHistoryTemplateProvider = StateProvider.autoDispose<String?>(
  (ref) => null,
);
final adminSurveyHistoryDateFilterProvider =
    StateProvider.autoDispose<AdminDateFilter>((ref) => AdminDateFilter.all);
final adminSurveyHistoryPageProvider = StateProvider.autoDispose<int>(
  (ref) => 1,
);
const List<AdminDateFilter> _surveyDateFilters = [
  AdminDateFilter.all,
  AdminDateFilter.today,
  AdminDateFilter.last7Days,
  AdminDateFilter.last30Days,
  AdminDateFilter.last6Months,
  AdminDateFilter.last1Year,
];
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
      final range = adminDateRange(dateFilter, now);
      if (range != null) {
        start = range.start;
        end = range.end;
      }
      return SurveyRepository().fetchSurveyResponsesPaged(
        query: query,
        categoryId: categoryId,
        templateId: templateId,
        start: start,
        end: end,
        page: page,
        limit: 15,
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
    _searchController = TextEditingController(
      text: ref.read(adminSurveyHistorySearchProvider),
    );
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
    final selectedCategoryId = ref.watch(adminSurveyHistoryCategoryProvider);
    final templates = templatesAsync.value ?? [];
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
        ? 'Semua'
        : categories
              .where((item) => item.id == selectedCategoryId)
              .map((item) => item.name)
              .firstWhere((_) => true, orElse: () => selectedCategoryId);
    final templateLabel = selectedTemplateId == null
        ? 'Semua'
        : templates
              .where((item) => item.id == selectedTemplateId)
              .map((item) => item.title)
              .firstWhere((_) => true, orElse: () => selectedTemplateId);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AdminFilterToolbar(
            controller: _searchController,
            searchHintText:
                'Cari berdasarkan entitas, kategori, atau template...',
            searchValue: searchValue,
            onSearchChanged: (value) {
              ref.read(adminSurveyHistorySearchProvider.notifier).state = value;
              ref.read(adminSurveyHistoryPageProvider.notifier).state = 1;
            },
            onClearSearch: () {
              ref.read(adminSurveyHistorySearchProvider.notifier).state = '';
              ref.read(adminSurveyHistoryPageProvider.notifier).state = 1;
            },
            onReset: () {
              ref.read(adminSurveyHistorySearchProvider.notifier).state = '';
              ref.read(adminSurveyHistoryCategoryProvider.notifier).state =
                  null;
              ref.read(adminSurveyHistoryTemplateProvider.notifier).state =
                  null;
              ref.read(adminSurveyHistoryDateFilterProvider.notifier).state =
                  AdminDateFilter.all;
              ref.read(adminSurveyHistoryPageProvider.notifier).state = 1;
            },
            filters: [
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
                  ref.read(adminSurveyHistoryCategoryProvider.notifier).state =
                      value;
                  ref.read(adminSurveyHistoryPageProvider.notifier).state = 1;
                },
              ),
              FilterDropdown<String?>(
                label: 'Template',
                icon: Icons.layers_outlined,
                valueLabel: templateLabel,
                enabled: templates.isNotEmpty,
                options: {
                  null: 'Semua',
                  for (final template in templates) template.id: template.title,
                },
                onChanged: (value) {
                  ref.read(adminSurveyHistoryTemplateProvider.notifier).state =
                      value;
                  ref.read(adminSurveyHistoryPageProvider.notifier).state = 1;
                },
              ),
              FilterDropdown<AdminDateFilter>(
                label: 'Tanggal',
                icon: Icons.calendar_today_outlined,
                valueLabel: dateFilter.label,
                enabled: true,
                options: {
                  for (final filter in _surveyDateFilters) filter: filter.label,
                },
                onChanged: (value) {
                  ref
                          .read(adminSurveyHistoryDateFilterProvider.notifier)
                          .state =
                      value;
                  ref.read(adminSurveyHistoryPageProvider.notifier).state = 1;
                },
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
                'Gagal memuat survei: ${responsesAsync.error}',
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
                      'Tidak ada survei yang sesuai filter.',
                      style: TextStyle(color: AppTheme.textMuted),
                    ),
                  ),
                LayoutBuilder(
                  builder: (context, constraints) => SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: ConstrainedBox(
                      constraints: BoxConstraints(
                        minWidth: constraints.maxWidth,
                      ),
                      child: DataTable(
                        headingRowColor: WidgetStateProperty.all(
                          AppTheme.surface,
                        ),
                        columns: const [
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
                          final category = row.category.isEmpty
                              ? row.categoryId
                              : row.category;
                          final template = row.template.isEmpty
                              ? row.templateId
                              : row.template;
                          return DataRow(
                            cells: [
                              DataCell(Text(row.userEntity)),
                              DataCell(Text(category)),
                              DataCell(Text(template)),
                              DataCell(Text(formatScoreFive(row.score))),
                              DataCell(Text(formatDate(row.createdAt))),
                            ],
                          );
                        }).toList(),
                      ),
                    ),
                  ),
                ),
                if (responsePage != null)
                  PaginationControls(
                    page: responsePage.page,
                    totalPages: responsePage.totalPages,
                    totalItems: responsePage.total,
                    hasPrev: responsePage.hasPrev,
                    hasNext: responsePage.hasNext,
                    onPrev: () =>
                        ref
                                .read(adminSurveyHistoryPageProvider.notifier)
                                .state =
                            responsePage.page - 1,
                    onNext: () =>
                        ref
                                .read(adminSurveyHistoryPageProvider.notifier)
                                .state =
                            responsePage.page + 1,
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
