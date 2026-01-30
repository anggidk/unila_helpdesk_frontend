import 'package:flutter/material.dart';
import 'package:unila_helpdesk_frontend/app/app_theme.dart';
import 'package:unila_helpdesk_frontend/core/models/admin_payloads.dart';
import 'package:unila_helpdesk_frontend/core/models/survey_models.dart';
import 'package:unila_helpdesk_frontend/core/models/ticket_models.dart';

Future<AddQuestionPayload?> showAdminAddQuestionModal({
  required BuildContext context,
  required List<ServiceCategory> categories,
  required ServiceCategory selectedCategory,
}) {
  return showDialog<AddQuestionPayload>(
    context: context,
    barrierDismissible: false,
    builder: (context) => _AdminAddQuestionDialog(
      categories: categories,
      selectedCategory: selectedCategory,
    ),
  );
}

class _AdminAddQuestionDialog extends StatefulWidget {
  const _AdminAddQuestionDialog({
    required this.categories,
    required this.selectedCategory,
  });

  final List<ServiceCategory> categories;
  final ServiceCategory selectedCategory;

  @override
  State<_AdminAddQuestionDialog> createState() =>
      _AdminAddQuestionDialogState();
}

class _AdminAddQuestionDialogState extends State<_AdminAddQuestionDialog> {
  final _textController = TextEditingController();
  final _optionController = TextEditingController();
  SurveyQuestionType _type = SurveyQuestionType.likert;
  late ServiceCategory _category;
  bool _isRequired = true;
  final List<String> _options = [];

  @override
  void initState() {
    super.initState();
    _category = widget.selectedCategory;
  }

  @override
  void dispose() {
    _textController.dispose();
    _optionController.dispose();
    super.dispose();
  }

  void _addOption() {
    final value = _optionController.text.trim();
    if (value.isEmpty) return;
    if (_options.contains(value)) return;
    setState(() {
      _options.add(value);
      _optionController.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      insetPadding: const EdgeInsets.all(24),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 560),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Tambah Pertanyaan',
                          style: TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 18,
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          'Konfigurasi pertanyaan untuk survei kepuasan pelanggan.',
                          style: TextStyle(color: AppTheme.textMuted),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              const Text(
                'Teks Pertanyaan',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _textController,
                maxLines: 3,
                onChanged: (_) => setState(() {}),
                decoration: const InputDecoration(
                  hintText: 'Misal: Seberapa puas Anda dengan layanan kami?',
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: DropdownButtonFormField<SurveyQuestionType>(
                      value: _type,
                      items: SurveyQuestionType.values
                          .map(
                            (value) => DropdownMenuItem(
                              value: value,
                              child: Text(value.label),
                            ),
                          )
                          .toList(),
                      onChanged: (value) => setState(() {
                        _type = value ?? SurveyQuestionType.likert;
                        if (_type != SurveyQuestionType.multipleChoice) {
                          _options.clear();
                          _optionController.clear();
                        }
                      }),
                      decoration: const InputDecoration(
                        labelText: 'Tipe Jawaban',
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: DropdownButtonFormField<ServiceCategory>(
                      value: _category,
                      items: widget.categories
                          .map(
                            (value) => DropdownMenuItem(
                              value: value,
                              child: Text(value.name),
                            ),
                          )
                          .toList(),
                      onChanged: (value) => setState(
                        () => _category = value ?? widget.selectedCategory,
                      ),
                      decoration: const InputDecoration(labelText: 'Kategori'),
                    ),
                  ),
                ],
              ),
              if (_type == SurveyQuestionType.multipleChoice) ...[
                const SizedBox(height: 16),
                const Text(
                  'Pilihan Jawaban',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _optionController,
                        decoration: const InputDecoration(
                          hintText: 'Tambah opsi (contoh: Sangat Baik)',
                        ),
                        onSubmitted: (_) => _addOption(),
                      ),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton(
                      onPressed: _addOption,
                      child: const Text('Tambah'),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                if (_options.isEmpty)
                  const Text(
                    'Belum ada opsi.',
                    style: TextStyle(color: AppTheme.textMuted),
                  )
                else
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: _options
                        .map(
                          (option) => Chip(
                            label: Text(option),
                            onDeleted: () => setState(() => _options.remove(option)),
                          ),
                        )
                        .toList(),
                  ),
              ],
              const SizedBox(height: 16),
              _PreviewSection(
                title: _textController.text.isEmpty
                    ? 'Seberapa puas Anda dengan layanan kami?'
                    : _textController.text,
                type: _type,
                options: _options,
              ),
              const SizedBox(height: 12),
              CheckboxListTile(
                value: _isRequired,
                onChanged: (value) =>
                    setState(() => _isRequired = value ?? false),
                contentPadding: EdgeInsets.zero,
                title: const Text(
                  'Wajib diisi',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
                controlAffinity: ListTileControlAffinity.leading,
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Batal'),
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton(
                    onPressed: _textController.text.trim().isEmpty
                        ? null
                        : () {
                            final payload = AddQuestionPayload(
                              categoryId: _category.id,
                              isRequired: _isRequired,
                              question: SurveyQuestion(
                                id: DateTime.now().millisecondsSinceEpoch
                                    .toString(),
                                text: _textController.text.trim(),
                                type: _type,
                                options: _type == SurveyQuestionType.multipleChoice
                                    ? (_options.isEmpty
                                        ? const ['Opsi 1', 'Opsi 2', 'Opsi 3']
                                        : List.unmodifiable(_options))
                                    : const [],
                              ),
                            );
                            Navigator.pop(context, payload);
                          },
                    child: const Text('Simpan'),
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

class _PreviewSection extends StatelessWidget {
  const _PreviewSection({
    required this.title,
    required this.type,
    required this.options,
  });

  final String title;
  final SurveyQuestionType type;
  final List<String>? options;

  @override
  Widget build(BuildContext context) {
    return Container(
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
          Row(
            children: [
              const Text(
                'PREVIEW TAMPILAN',
                style: TextStyle(fontSize: 12, color: AppTheme.textMuted),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: AppTheme.accentBlue.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(type.label, style: const TextStyle(fontSize: 11)),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
          const SizedBox(height: 12),
          if (type == SurveyQuestionType.likert) _LikertPreview(),
          if (type == SurveyQuestionType.yesNo) _YesNoPreview(),
          if (type == SurveyQuestionType.multipleChoice)
            _MultipleChoicePreview(options: options),
          if (type == SurveyQuestionType.text)
            TextField(
              enabled: false,
              decoration: const InputDecoration(
                hintText: 'Jawaban pengguna...',
              ),
            ),
        ],
      ),
    );
  }
}

class _LikertPreview extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: List.generate(
            5,
            (index) => Column(
              children: [
                Container(
                  height: 24,
                  width: 24,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: AppTheme.outline),
                    color: index == 2 ? AppTheme.navy : Colors.white,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  '${index + 1}',
                  style: const TextStyle(color: AppTheme.textMuted),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 8),
        const Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'SANGAT BURUK',
              style: TextStyle(fontSize: 11, color: AppTheme.textMuted),
            ),
            Text(
              'SANGAT BAIK',
              style: TextStyle(fontSize: 11, color: AppTheme.textMuted),
            ),
          ],
        ),
      ],
    );
  }
}

class _YesNoPreview extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(child: _PreviewChoice(label: 'Ya', selected: true)),
        const SizedBox(width: 12),
        const Expanded(child: _PreviewChoice(label: 'Tidak')),
      ],
    );
  }
}

class _MultipleChoicePreview extends StatelessWidget {
  const _MultipleChoicePreview({required this.options});

  final List<String>? options;

  @override
  Widget build(BuildContext context) {
    final list = options ?? const <String>[];
    final items = list.isEmpty ? const ['Opsi 1', 'Opsi 2', 'Opsi 3'] : list;
    return Column(
      children: [
        for (var i = 0; i < items.length; i++) ...[
          _PreviewChoice(label: items[i], selected: i == 0),
          if (i != items.length - 1) const SizedBox(height: 8),
        ],
      ],
    );
  }
}

class _PreviewChoice extends StatelessWidget {
  const _PreviewChoice({required this.label, this.selected = false});

  final String label;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 14),
      decoration: BoxDecoration(
        color: selected
            ? AppTheme.accentBlue.withValues(alpha: 0.12)
            : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: selected ? AppTheme.accentBlue : AppTheme.outline,
        ),
      ),
      child: Row(
        children: [
          Container(
            height: 18,
            width: 18,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: AppTheme.outline),
              color: selected ? AppTheme.accentBlue : Colors.white,
            ),
          ),
          const SizedBox(width: 10),
          Text(label, style: const TextStyle(fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}
