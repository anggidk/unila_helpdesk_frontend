import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:unila_helpdesk_frontend/app/app_theme.dart';
import 'package:unila_helpdesk_frontend/core/models/survey_models.dart';
import 'package:unila_helpdesk_frontend/core/models/ticket_models.dart';

final surveyAnswersProvider = StateProvider.autoDispose<Map<String, dynamic>>(
  (ref) => <String, dynamic>{},
);

class SurveyPage extends ConsumerWidget {
  const SurveyPage({super.key, required this.ticket, required this.template});

  final Ticket ticket;
  final SurveyTemplate template;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final answers = ref.watch(surveyAnswersProvider);
    final questions = template.questions;
    final progress = questions.isEmpty
        ? 0.0
        : answers.length / questions.length;
    return Scaffold(
      appBar: AppBar(title: const Text('Survey Kepuasan')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Text(
            'Langkah ${answers.length} dari ${questions.length}',
            style: const TextStyle(color: AppTheme.textMuted),
          ),
          const SizedBox(height: 8),
          LinearProgressIndicator(
            value: progress,
            backgroundColor: AppTheme.outline,
            color: AppTheme.navy,
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
                const Text(
                  'Detail Tiket',
                  style: TextStyle(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 8),
                Text(
                  ticket.title,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 4),
                Text(
                  ticket.category,
                  style: const TextStyle(color: AppTheme.textMuted),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          ...questions.asMap().entries.map((entry) {
            final index = entry.key;
            final question = entry.value;
            return _SurveyQuestionCard(
              index: index + 1,
              question: question,
              value: answers[question.id],
              onChanged: (value) {
                ref.read(surveyAnswersProvider.notifier).update((state) {
                  final next = Map<String, dynamic>.from(state);
                  next[question.id] = value;
                  return next;
                });
              },
            );
          }),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => context.pop(),
                  child: const Text('Sebelumnya'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Survey tersimpan (mock).')),
                    );
                  },
                  child: const Text('Selanjutnya'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SurveyQuestionCard extends StatelessWidget {
  const _SurveyQuestionCard({
    required this.index,
    required this.question,
    required this.value,
    required this.onChanged,
  });

  final int index;
  final SurveyQuestion question;
  final dynamic value;
  final ValueChanged<dynamic> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.outline),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '$index. ${question.text}',
            style: const TextStyle(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 12),
          if (question.type == SurveyQuestionType.likert)
            RadioGroup<int>(
              groupValue: value as int?,
              onChanged: onChanged,
              child: Column(
                children: List.generate(5, (i) {
                  final score = i + 1;
                  return RadioListTile<int>(
                    value: score,
                    title: Text(
                      score == 1
                          ? 'Sangat Tidak Puas'
                          : score == 2
                          ? 'Tidak Puas'
                          : score == 3
                          ? 'Netral'
                          : score == 4
                          ? 'Puas'
                          : 'Sangat Puas',
                    ),
                  );
                }),
              ),
            ),
          if (question.type == SurveyQuestionType.yesNo)
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => onChanged('Ya'),
                    icon: const Icon(Icons.check_circle_outline),
                    label: const Text('Ya'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => onChanged('Tidak'),
                    icon: const Icon(Icons.cancel_outlined),
                    label: const Text('Tidak'),
                  ),
                ),
              ],
            ),
          if (question.type == SurveyQuestionType.multipleChoice)
            RadioGroup<String>(
              groupValue: value as String?,
              onChanged: onChanged,
              child: Column(
                children: question.options
                    .map(
                      (option) => RadioListTile<String>(
                        value: option,
                        title: Text(option),
                      ),
                    )
                    .toList(),
              ),
            ),
          if (question.type == SurveyQuestionType.text)
            TextField(
              maxLines: 3,
              decoration: const InputDecoration(hintText: 'Tulis jawaban Anda'),
              onChanged: (val) => onChanged(val),
            ),
        ],
      ),
    );
  }
}
