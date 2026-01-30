import 'package:flutter/material.dart';
import 'package:unila_helpdesk_frontend/app/app_theme.dart';
import 'package:unila_helpdesk_frontend/core/models/survey_models.dart';
import 'package:unila_helpdesk_frontend/core/models/ticket_models.dart';
import 'package:unila_helpdesk_frontend/features/admin/presentation/admin_modal_add_pertanyaan.dart';

Future<SurveyTemplate?> showAdminCreateTemplateModal({
  required BuildContext context,
  required ServiceCategory selectedCategory,
  required List<ServiceCategory> categories,
  SurveyTemplate? initialTemplate,
}) {
  return showDialog<SurveyTemplate>(
    context: context,
    barrierDismissible: false,
    builder: (_) => _AdminCreateTemplateDialog(
      selectedCategory: selectedCategory,
      categories: categories,
      initialTemplate: initialTemplate,
    ),
  );
}

class _AdminCreateTemplateDialog extends StatefulWidget {
  const _AdminCreateTemplateDialog({
    required this.selectedCategory,
    required this.categories,
    this.initialTemplate,
  });

  final ServiceCategory selectedCategory;
  final List<ServiceCategory> categories;
  final SurveyTemplate? initialTemplate;

  @override
  State<_AdminCreateTemplateDialog> createState() => _AdminCreateTemplateDialogState();
}

class _AdminCreateTemplateDialogState extends State<_AdminCreateTemplateDialog> {
  static const List<String> _frameworkOptions = [
    'Custom',
    'ISO 9001',
    'UEQ',
    'COBIT',
    'ITIL',
  ];

  final _nameController = TextEditingController();
  final _descController = TextEditingController();
  late final List<SurveyQuestion> _questions;
  String _framework = 'Custom';

  @override
  void initState() {
    super.initState();
    if (widget.initialTemplate != null) {
      _nameController.text = widget.initialTemplate!.title;
      _descController.text = _stripFramework(widget.initialTemplate!.description);
      _framework = _detectFramework(widget.initialTemplate!.description);
      _questions = [...widget.initialTemplate!.questions];
    } else {
      _questions = [];
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      insetPadding: const EdgeInsets.all(24),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 620),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.initialTemplate == null
                              ? 'Buat Template Survey Baru'
                              : 'Edit Template Survey',
                          style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 18),
                        ),
                        SizedBox(height: 4),
                        Text(
                          'Configure your new survey template details below.',
                          style: TextStyle(color: AppTheme.textMuted),
                        ),
                      ],
                    ),
                  ),
                  IconButton(onPressed: () => Navigator.pop(context), icon: const Icon(Icons.close)),
                ],
              ),
              const SizedBox(height: 16),
              const Text('Nama Template', style: TextStyle(fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              TextField(
                controller: _nameController,
                onChanged: (_) => setState(() {}),
                decoration: const InputDecoration(
                  hintText: 'e.g., Survey Kepuasan Layanan Internet',
                ),
              ),
              const SizedBox(height: 16),
              const Text('Deskripsi', style: TextStyle(fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              TextField(
                controller: _descController,
                maxLines: 3,
                decoration: const InputDecoration(
                  hintText: 'Describe the purpose of this survey...',
                ),
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: _framework,
                items: _frameworkOptions
                    .map((value) => DropdownMenuItem(
                          value: value,
                          child: Text(value),
                        ))
                    .toList(),
                onChanged: (value) => setState(() => _framework = value ?? 'Custom'),
                decoration: const InputDecoration(labelText: 'Framework'),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  const Text('Pertanyaan', style: TextStyle(fontWeight: FontWeight.w700)),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppTheme.accentBlue.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Text('${_questions.length} Questions', style: const TextStyle(fontSize: 12)),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              ..._questions.map((question) => _QuestionTile(
                    question: question,
                    onDelete: () => setState(() => _questions.remove(question)),
                  )),
              GestureDetector(
                onTap: () async {
                  final payload = await showAdminAddQuestionModal(
                    context: context,
                    categories: widget.categories,
                    selectedCategory: widget.selectedCategory,
                  );
                  if (payload != null) {
                    setState(() => _questions.add(payload.question));
                  }
                },
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: AppTheme.outline, style: BorderStyle.solid),
                    color: Colors.transparent,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: const [
                      CircleAvatar(
                        radius: 12,
                        backgroundColor: AppTheme.outline,
                        child: Icon(Icons.add, size: 16, color: AppTheme.textPrimary),
                      ),
                      SizedBox(width: 8),
                      Text('Tambah Pertanyaan', style: TextStyle(fontWeight: FontWeight.w600)),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(onPressed: () => Navigator.pop(context), child: const Text('Batal')),
                    const SizedBox(width: 12),
                    ElevatedButton.icon(
                      onPressed: _nameController.text.trim().isEmpty
                          ? null
                          : () {
                            final template = SurveyTemplate(
                              id: widget.initialTemplate?.id ??
                                  DateTime.now().millisecondsSinceEpoch.toString(),
                              title: _nameController.text.trim(),
                              description: _buildDescription(_descController.text.trim(), _framework),
                              categoryId: widget.initialTemplate?.categoryId ?? widget.selectedCategory.id,
                              questions: List.unmodifiable(_questions),
                            );
                            Navigator.pop(context, template);
                          },
                      icon: const Icon(Icons.save_outlined),
                      label: Text(widget.initialTemplate == null ? 'Simpan Template' : 'Simpan Perubahan'),
                    ),
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _QuestionTile extends StatelessWidget {
  const _QuestionTile({required this.question, required this.onDelete});

  final SurveyQuestion question;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.outline),
      ),
      child: Row(
        children: [
          const Icon(Icons.drag_indicator, color: AppTheme.textMuted),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(question.text, style: const TextStyle(fontWeight: FontWeight.w600)),
                const SizedBox(height: 2),
                Text(question.type.label, style: const TextStyle(color: AppTheme.textMuted, fontSize: 12)),
              ],
            ),
          ),
          IconButton(onPressed: () {}, icon: const Icon(Icons.edit_outlined)),
          IconButton(onPressed: onDelete, icon: const Icon(Icons.delete_outline)),
        ],
      ),
    );
  }
}

String _detectFramework(String? description) {
  if (description == null) return 'Custom';
  final lower = description.toLowerCase();
  if (lower.contains('iso')) return 'ISO 9001';
  if (lower.contains('ueq')) return 'UEQ';
  if (lower.contains('cobit')) return 'COBIT';
  if (lower.contains('itil')) return 'ITIL';
  return 'Custom';
}

String _stripFramework(String description) {
  final regex = RegExp(r'\n?Framework:\s?.*$', caseSensitive: false);
  return description.replaceAll(regex, '').trim();
}

String _buildDescription(String description, String framework) {
  final cleaned = _stripFramework(description);
  if (framework == 'Custom') {
    return cleaned.isEmpty ? 'Template survey baru' : cleaned;
  }
  final suffix = 'Framework: $framework';
  if (cleaned.isEmpty) {
    return suffix;
  }
  return '$cleaned\n$suffix';
}
