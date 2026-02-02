import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:unila_helpdesk_frontend/app/app_providers.dart';
import 'package:unila_helpdesk_frontend/app/app_theme.dart';
import 'package:unila_helpdesk_frontend/core/models/survey_models.dart';
import 'package:unila_helpdesk_frontend/core/models/ticket_models.dart';
import 'package:unila_helpdesk_frontend/features/feedback/data/survey_repository.dart';
import 'package:unila_helpdesk_frontend/features/admin/presentation/admin_modal_add_pertanyaan.dart';
import 'package:unila_helpdesk_frontend/features/admin/presentation/admin_modal_create_template.dart';

final adminSurveySelectedCategoryProvider =
    StateProvider.autoDispose<ServiceCategory?>((ref) => null);
final adminSurveySelectedTemplateIdProvider = StateProvider.autoDispose<String>((ref) {
  return '';
});

class _AdminSurveyQuestionsNotifier extends StateNotifier<Map<String, List<SurveyQuestion>>> {
  _AdminSurveyQuestionsNotifier() : super({});

  void addQuestion(String categoryId, SurveyQuestion question) {
    final current = state[categoryId] ?? <SurveyQuestion>[];
    state = {
      ...state,
      categoryId: [...current, question],
    };
  }

  List<SurveyQuestion> questionsFor(String categoryId, List<SurveyQuestion> base) {
    final extras = state[categoryId] ?? <SurveyQuestion>[];
    return [...base, ...extras];
  }
}

final adminSurveyQuestionsProvider =
    StateNotifierProvider.autoDispose<_AdminSurveyQuestionsNotifier, Map<String, List<SurveyQuestion>>>(
  (ref) => _AdminSurveyQuestionsNotifier(),
);

class _AdminSurveyTemplatesNotifier extends StateNotifier<List<SurveyTemplate>> {
  _AdminSurveyTemplatesNotifier() : super(const []);

  void addTemplate(SurveyTemplate template) {
    final existing = state.indexWhere((item) => item.id == template.id);
    if (existing == -1) {
      state = [...state, template];
    } else {
      final updated = [...state]..[existing] = template;
      state = updated;
    }
  }

  void updateTemplate(SurveyTemplate template) => addTemplate(template);
}

final adminSurveyTemplatesProvider =
    StateNotifierProvider.autoDispose<_AdminSurveyTemplatesNotifier, List<SurveyTemplate>>(
  (ref) => _AdminSurveyTemplatesNotifier(),
);

class AdminSurveyPage extends ConsumerWidget {
  const AdminSurveyPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final categoriesAsync = ref.watch(serviceCategoriesProvider);
    final categories = categoriesAsync.value ?? [];
    final selectedCategory = ref.watch(adminSurveySelectedCategoryProvider);
    final baseTemplatesAsync = ref.watch(surveyTemplatesProvider);
    final baseTemplates = baseTemplatesAsync.value ?? [];
    final extraTemplates = ref.watch(adminSurveyTemplatesProvider);
    final allTemplates = _mergeTemplates(baseTemplates, extraTemplates);
    final activeCategory = selectedCategory ?? (categories.isNotEmpty ? categories.first : null);
    if (selectedCategory == null && activeCategory != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ref.read(adminSurveySelectedCategoryProvider.notifier).state = activeCategory;
      });
    }

    final categoryTemplates = activeCategory == null
        ? <SurveyTemplate>[]
        : allTemplates.where((t) => t.categoryId == activeCategory.id).toList();
    final selectedTemplateId = ref.watch(adminSurveySelectedTemplateIdProvider);
    SurveyTemplate? template;
    if (allTemplates.isNotEmpty) {
      template = categoryTemplates.firstWhere(
        (t) => t.id == selectedTemplateId,
        orElse: () => categoryTemplates.isNotEmpty ? categoryTemplates.first : allTemplates.first,
      );
      if (selectedTemplateId.isEmpty) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          ref.read(adminSurveySelectedTemplateIdProvider.notifier).state = template!.id;
        });
      }
    }
    final questions = ref
        .read(adminSurveyQuestionsProvider.notifier)
        .questionsFor(activeCategory?.id ?? '', template?.questions ?? const []);
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 220,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Kategori Layanan', style: TextStyle(fontWeight: FontWeight.w700)),
                const SizedBox(height: 12),
                if (categoriesAsync.isLoading)
                  const Padding(
                    padding: EdgeInsets.only(bottom: 12),
                    child: LinearProgressIndicator(),
                  ),
                if (categoriesAsync.hasError)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Text(
                      'Gagal memuat kategori: ${categoriesAsync.error}',
                      style: const TextStyle(color: AppTheme.textMuted),
                    ),
                  ),
                ...categories.map((category) {
                  final selected = category.id == selectedCategory?.id;
                  return Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    decoration: BoxDecoration(
                      color: selected ? AppTheme.accentBlue.withValues(alpha: 0.12) : Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: selected ? AppTheme.accentBlue : AppTheme.outline),
                    ),
                    child: ListTile(
                      onTap: () => ref.read(adminSurveySelectedCategoryProvider.notifier).state = category,
                      title: Text(category.name, style: const TextStyle(fontWeight: FontWeight.w600)),
                      trailing: const Icon(Icons.chevron_right, color: AppTheme.textMuted),
                    ),
                  );
                }),
              ],
            ),
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (baseTemplatesAsync.isLoading)
                  const Padding(
                    padding: EdgeInsets.only(bottom: 12),
                    child: LinearProgressIndicator(),
                  ),
                if (baseTemplatesAsync.hasError)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Text(
                      'Gagal memuat template survey: ${baseTemplatesAsync.error}',
                      style: const TextStyle(color: AppTheme.textMuted),
                    ),
                  ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: const [
                        Text('Pengaturan Survey', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
                        SizedBox(height: 4),
                        Text('Kelola kuesioner untuk berbagai layanan kampus.', style: TextStyle(color: AppTheme.textMuted)),
                      ],
                    ),
                    Row(
                      children: [
                        OutlinedButton.icon(
                          onPressed: () => _showTemplateDialog(context, ref),
                          icon: const Icon(Icons.layers_outlined),
                          label: const Text('Pilih Template'),
                        ),
                        const SizedBox(width: 12),
                        ElevatedButton.icon(
                          onPressed: () async {
                            if (activeCategory == null) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Kategori belum tersedia.')),
                              );
                              return;
                            }
                            final template = await showAdminCreateTemplateModal(
                              context: context,
                              selectedCategory: activeCategory,
                              categories: categories,
                            );
                            if (template != null) {
                              try {
                                final saved = await SurveyRepository().createTemplate(
                                  title: template.title,
                                  description: template.description,
                                  categoryId: template.categoryId,
                                  questions: template.questions,
                                );
                                ref.read(adminSurveyTemplatesProvider.notifier).addTemplate(saved);
                                ref.read(adminSurveySelectedTemplateIdProvider.notifier).state = saved.id;
                              } catch (error) {
                                if (!context.mounted) return;
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text(error.toString())),
                                );
                              }
                            }
                          },
                          icon: const Icon(Icons.add),
                          label: const Text('Buat Template'),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                if (template != null)
                  _TemplateCard(
                  template: template,
                  onEdit: () async {
                    if (activeCategory == null) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Kategori belum tersedia.')),
                      );
                      return;
                    }
                    final edited = await showAdminCreateTemplateModal(
                      context: context,
                      selectedCategory: activeCategory,
                      categories: categories,
                      initialTemplate: template,
                    );
                      if (edited != null) {
                        ref.read(adminSurveyTemplatesProvider.notifier).updateTemplate(edited);
                        ref.read(adminSurveySelectedTemplateIdProvider.notifier).state = edited.id;
                      }
                    },
                    onChange: () => _showTemplateDialog(context, ref),
                  )
                else
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppTheme.outline),
                    ),
                    child: const Text('Template survey belum tersedia.'),
                  ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppTheme.outline),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Daftar Pertanyaan', style: TextStyle(fontWeight: FontWeight.w700)),
                          ElevatedButton.icon(
                            onPressed: () async {
                              if (activeCategory == null) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('Kategori belum tersedia.')),
                                );
                                return;
                              }
                              final payload = await showAdminAddQuestionModal(
                                context: context,
                                categories: categories,
                                selectedCategory: activeCategory,
                              );
                              if (payload != null) {
                                ref
                                    .read(adminSurveyQuestionsProvider.notifier)
                                    .addQuestion(payload.categoryId, payload.question);
                              }
                            },
                            icon: const Icon(Icons.add),
                            label: const Text('Tambah Pertanyaan'),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      ...questions.map((question) => _QuestionRow(question: question)),
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

  void _showTemplateDialog(BuildContext context, WidgetRef ref) {
    showDialog<void>(
      context: context,
      builder: (_) => Consumer(
        builder: (context, dialogRef, _) {
          final selectedTemplateId = dialogRef.watch(adminSurveySelectedTemplateIdProvider);
          final baseTemplatesAsync = dialogRef.watch(surveyTemplatesProvider);
          final baseTemplates = baseTemplatesAsync.value ?? [];
          final extraTemplates = dialogRef.watch(adminSurveyTemplatesProvider);
          final templates = _mergeTemplates(baseTemplates, extraTemplates);
          final categoriesAsync = dialogRef.watch(serviceCategoriesProvider);
          final categories = categoriesAsync.value ?? [];
          final selectedCategory = dialogRef.watch(adminSurveySelectedCategoryProvider) ??
              (categories.isNotEmpty ? categories.first : null);
          return Dialog(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Pilih Template Survey', style: TextStyle(fontWeight: FontWeight.w700)),
                  const SizedBox(height: 8),
                  const Text('Pilih kerangka survey sesuai kebutuhan.', style: TextStyle(color: AppTheme.textMuted)),
                  const SizedBox(height: 16),
                  if (baseTemplatesAsync.isLoading || categoriesAsync.isLoading)
                    const Padding(
                      padding: EdgeInsets.only(bottom: 12),
                      child: LinearProgressIndicator(),
                    ),
                  if (baseTemplatesAsync.hasError || categoriesAsync.hasError)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Text(
                        'Gagal memuat data: ${baseTemplatesAsync.error ?? categoriesAsync.error}',
                        style: const TextStyle(color: AppTheme.textMuted),
                      ),
                    ),
                  RadioGroup<String>(
                    groupValue: selectedTemplateId,
                    onChanged: (value) {
                      if (value != null) {
                        dialogRef.read(adminSurveySelectedTemplateIdProvider.notifier).state = value;
                      }
                    },
                    child: Column(
                      children: templates
                          .map(
                            (template) => ListTile(
                              leading: Radio<String>(value: template.id),
                              title: Text(template.title, style: const TextStyle(fontWeight: FontWeight.w600)),
                              subtitle: Text(template.description),
                              trailing: Text('${template.questions.length} pertanyaan'),
                            ),
                          )
                          .toList(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  OutlinedButton.icon(
                    onPressed: () async {
                      if (selectedCategory == null) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Kategori belum tersedia.')),
                        );
                        return;
                      }
                      final template = await showAdminCreateTemplateModal(
                        context: context,
                        selectedCategory: selectedCategory,
                        categories: categories,
                      );
                      if (template != null) {
                        try {
                          final saved = await SurveyRepository().createTemplate(
                            title: template.title,
                            description: template.description,
                            categoryId: template.categoryId,
                            questions: template.questions,
                          );
                          dialogRef.read(adminSurveyTemplatesProvider.notifier).addTemplate(saved);
                          dialogRef.read(adminSurveySelectedTemplateIdProvider.notifier).state = saved.id;
                        } catch (error) {
                          if (!context.mounted) return;
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text(error.toString())),
                          );
                        }
                      }
                    },
                    icon: const Icon(Icons.add_circle_outline),
                    label: const Text('Buat Template Baru'),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(onPressed: () => context.pop(), child: const Text('Batal')),
                      const SizedBox(width: 12),
                      ElevatedButton(onPressed: () => context.pop(), child: const Text('Terapkan')),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class _TemplateCard extends StatelessWidget {
  const _TemplateCard({
    required this.template,
    required this.onEdit,
    required this.onChange,
  });

  final SurveyTemplate template;
  final VoidCallback onEdit;
  final VoidCallback onChange;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.outline),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Template: ${template.title}', style: const TextStyle(fontWeight: FontWeight.w700)),
              const SizedBox(height: 4),
              Text('${template.questions.length} pertanyaan - Updated 2 hari lalu',
                  style: const TextStyle(color: AppTheme.textMuted)),
            ],
          ),
          Row(
            children: [
              OutlinedButton(onPressed: onEdit, child: const Text('Edit')),
              const SizedBox(width: 8),
              OutlinedButton(onPressed: onChange, child: const Text('Ganti')),
            ],
          ),
        ],
      ),
    );
  }
}

List<SurveyTemplate> _mergeTemplates(
  List<SurveyTemplate> base,
  List<SurveyTemplate> extra,
) {
  final map = <String, SurveyTemplate>{};
  for (final template in base) {
    map[template.id] = template;
  }
  for (final template in extra) {
    map[template.id] = template;
  }
  return map.values.toList();
}

class _QuestionRow extends StatelessWidget {
  const _QuestionRow({required this.question});

  final SurveyQuestion question;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.outline),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: AppTheme.accentBlue.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(question.type.label, style: const TextStyle(fontSize: 12)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(question.text, style: const TextStyle(fontWeight: FontWeight.w600)),
                if (question.options.isNotEmpty)
                  Text(
                    question.options.join(', '),
                    style: const TextStyle(color: AppTheme.textMuted),
                  ),
              ],
            ),
          ),
          IconButton(onPressed: () {}, icon: const Icon(Icons.edit_outlined)),
          IconButton(onPressed: () {}, icon: const Icon(Icons.delete_outline)),
        ],
      ),
    );
  }
}
