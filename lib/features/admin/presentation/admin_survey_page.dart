import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:unila_helpdesk_frontend/app/app_providers.dart';
import 'package:unila_helpdesk_frontend/app/app_theme.dart';
import 'package:unila_helpdesk_frontend/core/models/survey_models.dart';
import 'package:unila_helpdesk_frontend/core/models/ticket_models.dart';
import 'package:unila_helpdesk_frontend/core/utils/date_utils.dart';
import 'package:unila_helpdesk_frontend/features/feedback/data/survey_repository.dart';
import 'package:unila_helpdesk_frontend/features/admin/presentation/admin_modal_add_pertanyaan.dart';
import 'package:unila_helpdesk_frontend/features/admin/presentation/admin_modal_create_template.dart';
import 'package:unila_helpdesk_frontend/features/categories/data/category_repository.dart';

final adminSurveySelectedCategoryProvider =
    StateProvider.autoDispose<ServiceCategory?>((ref) => null);
final adminSurveySelectedTemplateIdProvider = StateProvider.autoDispose<String>((ref) {
  return '';
});
final adminSurveyLastCategoryIdProvider =
    StateProvider.autoDispose<String?>((ref) => null);

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

  void removeTemplate(String templateId) {
    state = state.where((item) => item.id != templateId).toList();
  }
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
    final categories = (categoriesAsync.value ?? [])
        .where((category) => !category.guestAllowed)
        .toList();
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
    if (selectedCategory != null) {
      final updatedCategory = categories
          .where((item) => item.id == selectedCategory.id)
          .toList();
      if (updatedCategory.isNotEmpty &&
          updatedCategory.first.surveyTemplateId != selectedCategory.surveyTemplateId) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          ref.read(adminSurveySelectedCategoryProvider.notifier).state =
              updatedCategory.first;
        });
      }
    }

    final lastCategoryId = ref.watch(adminSurveyLastCategoryIdProvider);
    if (activeCategory != null && activeCategory.id != lastCategoryId) {
      final preferredTemplateId = activeCategory.surveyTemplateId ?? '';
      final nextTemplateId = preferredTemplateId.isNotEmpty &&
              allTemplates.any((t) => t.id == preferredTemplateId)
          ? preferredTemplateId
          : (allTemplates.isNotEmpty ? allTemplates.first.id : '');
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ref.read(adminSurveyLastCategoryIdProvider.notifier).state = activeCategory.id;
        ref.read(adminSurveySelectedTemplateIdProvider.notifier).state =
            nextTemplateId;
      });
    }

    final selectedTemplateId = ref.watch(adminSurveySelectedTemplateIdProvider);
    SurveyTemplate? template;
    if (activeCategory != null &&
        selectedTemplateId.isNotEmpty &&
        !allTemplates.any((t) => t.id == selectedTemplateId)) {
      final preferredTemplateId = activeCategory.surveyTemplateId ?? '';
      final nextTemplateId = preferredTemplateId.isNotEmpty &&
              allTemplates.any((t) => t.id == preferredTemplateId)
          ? preferredTemplateId
          : (allTemplates.isNotEmpty ? allTemplates.first.id : '');
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ref.read(adminSurveySelectedTemplateIdProvider.notifier).state =
            nextTemplateId;
      });
    }
    if (allTemplates.isNotEmpty) {
      template = allTemplates.firstWhere(
        (t) => t.id == selectedTemplateId,
        orElse: () => allTemplates.first,
      );
    }
    final questions = activeCategory == null
        ? const <SurveyQuestion>[]
        : (template?.questions ?? const <SurveyQuestion>[]);
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
                              final validationError = _validateTemplate(template);
                              if (validationError != null) {
                                if (!context.mounted) return;
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text(validationError)),
                                );
                                return;
                              }
                              try {
                                final saved = await SurveyRepository().createTemplate(
                                  title: template.title,
                                  description: template.description,
                                  categoryId: template.categoryId,
                                  questions: template.questions,
                                );
                                await CategoryRepository().updateTemplate(
                                  categoryId: activeCategory.id,
                                  templateId: saved.id,
                                );
                                ref.read(adminSurveySelectedCategoryProvider.notifier).state =
                                    ServiceCategory(
                                      id: activeCategory.id,
                                      name: activeCategory.name,
                                      guestAllowed: activeCategory.guestAllowed,
                                      surveyTemplateId: saved.id,
                                    );
                                ref.read(adminSurveyTemplatesProvider.notifier).addTemplate(saved);
                                ref.read(adminSurveySelectedTemplateIdProvider.notifier).state = saved.id;
                                ref.invalidate(serviceCategoriesProvider);
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
                        final validationError = _validateTemplate(edited);
                        if (validationError != null) {
                          if (!context.mounted) return;
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text(validationError)),
                          );
                          return;
                        }
                        try {
                          final saved = await SurveyRepository().updateTemplate(
                            templateId: edited.id,
                            title: edited.title,
                            description: edited.description,
                            categoryId: edited.categoryId,
                            questions: edited.questions,
                          );
                          ref.read(adminSurveyTemplatesProvider.notifier).updateTemplate(saved);
                          ref.read(adminSurveySelectedTemplateIdProvider.notifier).state = saved.id;
                          ref.invalidate(surveyTemplatesProvider);
                        } catch (error) {
                          if (!context.mounted) return;
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text(error.toString())),
                          );
                        }
                      }
                    },
                    onChange: () => _showTemplateDialog(context, ref),
                    onDelete: () async {
                      final confirm = await showDialog<bool>(
                        context: context,
                        builder: (dialogContext) => AlertDialog(
                          title: const Text('Hapus Template'),
                          content: const Text('Template ini akan dihapus permanen. Lanjutkan?'),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(dialogContext, false),
                              child: const Text('Batal'),
                            ),
                            ElevatedButton(
                              onPressed: () => Navigator.pop(dialogContext, true),
                              child: const Text('Hapus'),
                            ),
                          ],
                        ),
                      );
                      if (confirm != true) return;
                      if (template == null) return;
                      try {
                        await SurveyRepository().deleteTemplate(template.id);
                        ref.read(adminSurveyTemplatesProvider.notifier).removeTemplate(template.id);
                        ref.read(adminSurveySelectedTemplateIdProvider.notifier).state = '';
                        ref.invalidate(surveyTemplatesProvider);
                      } catch (error) {
                        if (!context.mounted) return;
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text(error.toString())),
                        );
                      }
                    },
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
                              if (template == null) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('Template belum tersedia.')),
                                );
                                return;
                              }
                              final payload = await showAdminAddQuestionModal(
                                context: context,
                                categories: categories,
                                selectedCategory: activeCategory,
                              );
                              if (payload != null) {
                                final updatedQuestions = [
                                  ...template.questions,
                                  payload.question,
                                ];
                                try {
                                  final saved = await SurveyRepository().updateTemplate(
                                    templateId: template.id,
                                    title: template.title,
                                    description: template.description,
                                    categoryId: template.categoryId,
                                    questions: updatedQuestions,
                                  );
                                  ref.read(adminSurveyTemplatesProvider.notifier).updateTemplate(saved);
                                  ref.read(adminSurveySelectedTemplateIdProvider.notifier).state = saved.id;
                                  ref.invalidate(surveyTemplatesProvider);
                                } catch (error) {
                                  if (!context.mounted) return;
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(content: Text(error.toString())),
                                  );
                                }
                              }
                            },
                            icon: const Icon(Icons.add),
                            label: const Text('Tambah Pertanyaan'),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      ...questions.map(
                        (question) => _QuestionRow(
                          question: question,
                          onEdit: () async {
                            if (template == null || activeCategory == null) {
                              return;
                            }
                            final payload = await showAdminAddQuestionModal(
                              context: context,
                              categories: categories,
                              selectedCategory: activeCategory,
                              initialQuestion: question,
                              lockCategory: true,
                            );
                            if (payload == null) return;
                            final updatedQuestions = template.questions
                                .map(
                                  (item) => item.id == question.id
                                      ? payload.question
                                      : item,
                                )
                                .toList();
                            try {
                              final saved = await SurveyRepository().updateTemplate(
                                templateId: template.id,
                                title: template.title,
                                description: template.description,
                                categoryId: template.categoryId,
                                questions: updatedQuestions,
                              );
                              ref.read(adminSurveyTemplatesProvider.notifier).updateTemplate(saved);
                              ref.read(adminSurveySelectedTemplateIdProvider.notifier).state = saved.id;
                              ref.invalidate(surveyTemplatesProvider);
                            } catch (error) {
                              if (!context.mounted) return;
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text(error.toString())),
                              );
                            }
                          },
                          onDelete: () async {
                            if (template == null) return;
                            if (template.questions.length <= 1) {
                              if (!context.mounted) return;
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Template harus memiliki minimal 1 pertanyaan.')),
                              );
                              return;
                            }
                            final confirm = await showDialog<bool>(
                              context: context,
                              builder: (dialogContext) => AlertDialog(
                                title: const Text('Hapus Pertanyaan'),
                                content: const Text('Pertanyaan ini akan dihapus. Lanjutkan?'),
                                actions: [
                                  TextButton(
                                    onPressed: () => Navigator.pop(dialogContext, false),
                                    child: const Text('Batal'),
                                  ),
                                  ElevatedButton(
                                    onPressed: () => Navigator.pop(dialogContext, true),
                                    child: const Text('Hapus'),
                                  ),
                                ],
                              ),
                            );
                            if (confirm != true) return;
                            final updatedQuestions = template.questions
                                .where((item) => item.id != question.id)
                                .toList();
                            try {
                              final saved = await SurveyRepository().updateTemplate(
                                templateId: template.id,
                                title: template.title,
                                description: template.description,
                                categoryId: template.categoryId,
                                questions: updatedQuestions,
                              );
                              ref.read(adminSurveyTemplatesProvider.notifier).updateTemplate(saved);
                              ref.read(adminSurveySelectedTemplateIdProvider.notifier).state = saved.id;
                              ref.invalidate(surveyTemplatesProvider);
                            } catch (error) {
                              if (!context.mounted) return;
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text(error.toString())),
                              );
                            }
                          },
                        ),
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

  void _showTemplateDialog(BuildContext context, WidgetRef ref) {
    final initialCategory = ref.read(adminSurveySelectedCategoryProvider);
    final initialTemplateId = initialCategory?.surveyTemplateId ??
        ref.read(adminSurveySelectedTemplateIdProvider);
    showDialog<bool>(
      context: context,
      barrierDismissible: true,
      builder: (_) => Consumer(
        builder: (context, dialogRef, _) {
          final selectedTemplateId = dialogRef.watch(adminSurveySelectedTemplateIdProvider);
          final baseTemplatesAsync = dialogRef.watch(surveyTemplatesProvider);
          final baseTemplates = baseTemplatesAsync.value ?? [];
          final extraTemplates = dialogRef.watch(adminSurveyTemplatesProvider);
          final allTemplates = _mergeTemplates(baseTemplates, extraTemplates);
          final categoriesAsync = dialogRef.watch(serviceCategoriesProvider);
          final categories = (categoriesAsync.value ?? [])
              .where((category) => !category.guestAllowed)
              .toList();
          final selectedCategory = dialogRef.watch(adminSurveySelectedCategoryProvider) ??
              (categories.isNotEmpty ? categories.first : null);
          final templates = allTemplates;
          return Dialog(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 560, maxHeight: 560),
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
                  if (templates.isEmpty && !baseTemplatesAsync.isLoading)
                    const Padding(
                      padding: EdgeInsets.only(bottom: 12),
                      child: Text(
                        'Template untuk kategori ini belum tersedia.',
                        style: TextStyle(color: AppTheme.textMuted),
                      ),
                    ),
                  Expanded(
                    child: SingleChildScrollView(
                      child: RadioGroup<String>(
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
                                  trailing: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text('${template.questions.length} pertanyaan'),
                                      const SizedBox(width: 8),
                                      IconButton(
                                        tooltip: 'Edit',
                                        onPressed: () async {
                                          final targetCategory = selectedCategory ??
                                              (categories.isNotEmpty ? categories.first : null);
                                          if (targetCategory == null) {
                                            if (!context.mounted) return;
                                            ScaffoldMessenger.of(context).showSnackBar(
                                              const SnackBar(content: Text('Kategori belum tersedia.')),
                                            );
                                            return;
                                          }
                                          final edited = await showAdminCreateTemplateModal(
                                            context: context,
                                            selectedCategory: targetCategory,
                                            categories: categories,
                                            initialTemplate: template,
                                          );
                                          if (edited != null) {
                                            final validationError = _validateTemplate(edited);
                                            if (validationError != null) {
                                              if (!context.mounted) return;
                                              ScaffoldMessenger.of(context).showSnackBar(
                                                SnackBar(content: Text(validationError)),
                                              );
                                              return;
                                            }
                                            try {
                                              final saved = await SurveyRepository().updateTemplate(
                                                templateId: edited.id,
                                                title: edited.title,
                                                description: edited.description,
                                                categoryId: edited.categoryId,
                                                questions: edited.questions,
                                              );
                                              dialogRef.read(adminSurveyTemplatesProvider.notifier).updateTemplate(saved);
                                              dialogRef.read(adminSurveySelectedTemplateIdProvider.notifier).state =
                                                  saved.id;
                                              dialogRef.invalidate(surveyTemplatesProvider);
                                            } catch (error) {
                                              if (!context.mounted) return;
                                              ScaffoldMessenger.of(context).showSnackBar(
                                                SnackBar(content: Text(error.toString())),
                                              );
                                            }
                                          }
                                        },
                                        icon: const Icon(Icons.edit_outlined),
                                      ),
                                      IconButton(
                                        tooltip: 'Hapus',
                                        onPressed: () async {
                                          final usedBy = categories
                                              .where((item) => item.surveyTemplateId == template.id)
                                              .toList();
                                          if (usedBy.isNotEmpty) {
                                            if (!context.mounted) return;
                                            ScaffoldMessenger.of(context).showSnackBar(
                                              SnackBar(
                                                content: Text(
                                                  'Template dipakai ${usedBy.length} kategori. Ganti dulu sebelum hapus.',
                                                ),
                                              ),
                                            );
                                            return;
                                          }
                                          final confirm = await showDialog<bool>(
                                            context: context,
                                            builder: (dialogContext) => AlertDialog(
                                              title: const Text('Hapus Template'),
                                              content: const Text('Template ini akan dihapus permanen. Lanjutkan?'),
                                              actions: [
                                                TextButton(
                                                  onPressed: () => Navigator.pop(dialogContext, false),
                                                  child: const Text('Batal'),
                                                ),
                                                ElevatedButton(
                                                  onPressed: () => Navigator.pop(dialogContext, true),
                                                  child: const Text('Hapus'),
                                                ),
                                              ],
                                            ),
                                          );
                                          if (confirm != true) return;
                                          try {
                                            await SurveyRepository().deleteTemplate(template.id);
                                            dialogRef.read(adminSurveyTemplatesProvider.notifier).removeTemplate(template.id);
                                            if (selectedTemplateId == template.id) {
                                              dialogRef.read(adminSurveySelectedTemplateIdProvider.notifier).state = '';
                                            }
                                            dialogRef.invalidate(surveyTemplatesProvider);
                                          } catch (error) {
                                            if (!context.mounted) return;
                                            ScaffoldMessenger.of(context).showSnackBar(
                                              SnackBar(content: Text(error.toString())),
                                            );
                                          }
                                        },
                                        icon: const Icon(Icons.delete_outline),
                                      ),
                                    ],
                                  ),
                                ),
                              )
                              .toList(),
                        ),
                      ),
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
                        final validationError = _validateTemplate(template);
                        if (validationError != null) {
                          if (!context.mounted) return;
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text(validationError)),
                          );
                          return;
                        }
                        try {
                          final saved = await SurveyRepository().createTemplate(
                            title: template.title,
                            description: template.description,
                            categoryId: template.categoryId,
                            questions: template.questions,
                          );
                          await CategoryRepository().updateTemplate(
                            categoryId: selectedCategory.id,
                            templateId: saved.id,
                          );
                          dialogRef.read(adminSurveySelectedCategoryProvider.notifier).state =
                              ServiceCategory(
                                id: selectedCategory.id,
                                name: selectedCategory.name,
                                guestAllowed: selectedCategory.guestAllowed,
                                surveyTemplateId: saved.id,
                              );
                          dialogRef.read(adminSurveyTemplatesProvider.notifier).addTemplate(saved);
                          dialogRef.read(adminSurveySelectedTemplateIdProvider.notifier).state = saved.id;
                          dialogRef.invalidate(serviceCategoriesProvider);
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
                      TextButton(onPressed: () => context.pop(false), child: const Text('Batal')),
                      const SizedBox(width: 12),
                      ElevatedButton(
                        onPressed: () async {
                          final selectedId = dialogRef.read(adminSurveySelectedTemplateIdProvider);
                          if (selectedCategory == null || selectedId.isEmpty) {
                            context.pop(false);
                            return;
                          }
                          try {
                            await CategoryRepository().updateTemplate(
                              categoryId: selectedCategory.id,
                              templateId: selectedId,
                            );
                            dialogRef.read(adminSurveySelectedCategoryProvider.notifier).state =
                                ServiceCategory(
                                  id: selectedCategory.id,
                                  name: selectedCategory.name,
                                  guestAllowed: selectedCategory.guestAllowed,
                                  surveyTemplateId: selectedId,
                                );
                            dialogRef.invalidate(serviceCategoriesProvider);
                            dialogRef.read(adminSurveySelectedTemplateIdProvider.notifier).state = selectedId;
                          } catch (error) {
                            if (!context.mounted) return;
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text(error.toString())),
                            );
                            return;
                          }
                          context.pop(true);
                        },
                        child: const Text('Terapkan'),
                      ),
                    ],
                  ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    ).then((applied) {
      if (applied != true) {
        ref.read(adminSurveySelectedTemplateIdProvider.notifier).state =
            initialTemplateId ?? '';
      }
    });
  }

  String? _validateTemplate(SurveyTemplate template) {
    if (template.questions.isEmpty) {
      return 'Template survey wajib memiliki minimal 1 pertanyaan.';
    }
    for (final question in template.questions) {
      if (question.text.trim().isEmpty) {
        return 'Pertanyaan tidak boleh kosong.';
      }
      if (question.type == SurveyQuestionType.multipleChoice &&
          question.options.isEmpty) {
        return 'Pertanyaan pilihan ganda wajib memiliki opsi.';
      }
    }
    return null;
  }
}

class _TemplateCard extends StatelessWidget {
  const _TemplateCard({
    required this.template,
    required this.onEdit,
    required this.onChange,
    required this.onDelete,
  });

  final SurveyTemplate template;
  final VoidCallback onEdit;
  final VoidCallback onChange;
  final VoidCallback onDelete;

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
              Text('${template.questions.length} pertanyaan - Updated ${formatDate(template.updatedAt)}',
                  style: const TextStyle(color: AppTheme.textMuted)),
            ],
          ),
          Row(
            children: [
              OutlinedButton(onPressed: onEdit, child: const Text('Edit')),
              const SizedBox(width: 8),
              OutlinedButton(onPressed: onChange, child: const Text('Ganti')),
              const SizedBox(width: 8),
              OutlinedButton(
                onPressed: onDelete,
                style: OutlinedButton.styleFrom(foregroundColor: AppTheme.danger),
                child: const Text('Hapus'),
              ),
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
  const _QuestionRow({
    required this.question,
    required this.onEdit,
    required this.onDelete,
  });

  final SurveyQuestion question;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

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
          IconButton(onPressed: onEdit, icon: const Icon(Icons.edit_outlined)),
          IconButton(onPressed: onDelete, icon: const Icon(Icons.delete_outline)),
        ],
      ),
    );
  }
}
