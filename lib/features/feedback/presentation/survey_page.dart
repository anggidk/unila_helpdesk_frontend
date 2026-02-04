import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:unila_helpdesk_frontend/app/app_theme.dart';
import 'package:unila_helpdesk_frontend/core/models/survey_models.dart';
import 'package:unila_helpdesk_frontend/core/models/ticket_models.dart';
import 'package:unila_helpdesk_frontend/features/feedback/data/survey_repository.dart';

final surveyAnswersProvider = StateProvider.autoDispose<Map<String, dynamic>>(
  (ref) => <String, dynamic>{},
);

final surveyErrorsProvider = StateProvider.autoDispose<Map<String, String>>(
  (ref) => <String, String>{},
);
final surveySubmittingProvider = StateProvider.autoDispose<bool>(
  (ref) => false,
);

class SurveyPage extends ConsumerWidget {
  const SurveyPage({super.key, required this.ticket, required this.template});

  final Ticket ticket;
  final SurveyTemplate template;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final answers = ref.watch(surveyAnswersProvider);
    final errors = ref.watch(surveyErrorsProvider);
    final isSubmitting = ref.watch(surveySubmittingProvider);
    final questions = template.questions;
    final progress = questions.isEmpty
        ? 0.0
        : answers.length / questions.length;
    return Scaffold(
      appBar: AppBar(title: const Text('Survei Kepuasan')),
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
              errorText: errors[question.id],
              onChanged: (value) {
                ref.read(surveyAnswersProvider.notifier).update((state) {
                  final next = Map<String, dynamic>.from(state);
                  next[question.id] = value;
                  return next;
                });
                ref.read(surveyErrorsProvider.notifier).update((state) {
                  final next = Map<String, String>.from(state);
                  next.remove(question.id);
                  return next;
                });
              },
            );
          }),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: isSubmitting
                  ? null
                  : () async {
                      final nextErrors = <String, String>{};
                      for (final question in questions) {
                        final value = answers[question.id];
                        final isEmptyText =
                            question.type == SurveyQuestionType.text &&
                            (value == null || value.toString().trim().isEmpty);
                        if (value == null || isEmptyText) {
                          nextErrors[question.id] = 'Jawaban wajib diisi.';
                        }
                      }

                      if (nextErrors.isNotEmpty) {
                        ref.read(surveyErrorsProvider.notifier).state =
                            nextErrors;
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Mohon lengkapi semua jawaban.'),
                          ),
                        );
                        return;
                      }

                      ref.read(surveySubmittingProvider.notifier).state = true;
                      try {
                        final response = await SurveyRepository().submitSurvey(
                          ticketId: ticket.id,
                          answers: answers,
                        );
                        if (!response.isSuccess) {
                          throw Exception(
                            response.error?.message ?? 'Gagal mengirim survei',
                          );
                        }
                        if (!context.mounted) return;
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Survei berhasil dikirim.'),
                          ),
                        );
                        Navigator.of(context).pop();
                      } catch (error) {
                        if (!context.mounted) return;
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text(error.toString())),
                        );
                      } finally {
                        ref.read(surveySubmittingProvider.notifier).state =
                            false;
                      }
                    },
              child: isSubmitting
                  ? const SizedBox(
                      height: 18,
                      width: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Text('KIRIM'),
            ),
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
    required this.errorText,
  });

  final int index;
  final SurveyQuestion question;
  final dynamic value;
  final ValueChanged<dynamic> onChanged;
  final String? errorText;

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
          RichText(
            text: TextSpan(
              style: const TextStyle(
                fontWeight: FontWeight.w700,
                color: AppTheme.textPrimary,
              ),
              children: [
                TextSpan(text: '$index. ${question.text}'),
                const TextSpan(
                  text: ' *',
                  style: TextStyle(color: AppTheme.danger),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          if (question.type == SurveyQuestionType.likert ||
              question.type == SurveyQuestionType.likertQuality ||
              question.type == SurveyQuestionType.likert7Puas ||
              question.type == SurveyQuestionType.likert7 ||
              question.type == SurveyQuestionType.likert6Puas ||
              question.type == SurveyQuestionType.likert6 ||
              question.type == SurveyQuestionType.likert4Puas ||
              question.type == SurveyQuestionType.likert4 ||
              question.type == SurveyQuestionType.likert3Puas ||
              question.type == SurveyQuestionType.likert3)
            RadioGroup<int>(
              groupValue: value as int?,
              onChanged: onChanged,
              child: Column(
                children: _likertOptions(question.type)
                    .map(
                      (option) => RadioListTile<int>(
                        value: option.score,
                        title: Text(option.label),
                      ),
                    )
                    .toList(),
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
          if (errorText != null)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(
                errorText!,
                style: const TextStyle(color: AppTheme.danger),
              ),
            ),
        ],
      ),
    );
  }
}

class _LikertOption {
  const _LikertOption({required this.score, required this.label});

  final int score;
  final String label;
}

List<_LikertOption> _likertOptions(SurveyQuestionType type) {
  switch (type) {
    case SurveyQuestionType.likert7:
      return const [
        _LikertOption(score: 1, label: 'Sangat Buruk'),
        _LikertOption(score: 2, label: 'Buruk'),
        _LikertOption(score: 3, label: 'Agak Buruk'),
        _LikertOption(score: 4, label: 'Netral'),
        _LikertOption(score: 5, label: 'Agak Baik'),
        _LikertOption(score: 6, label: 'Baik'),
        _LikertOption(score: 7, label: 'Sangat Baik'),
      ];
    case SurveyQuestionType.likert7Puas:
      return const [
        _LikertOption(score: 1, label: 'Sangat Tidak Puas'),
        _LikertOption(score: 2, label: 'Tidak Puas'),
        _LikertOption(score: 3, label: 'Agak Tidak Puas'),
        _LikertOption(score: 4, label: 'Netral'),
        _LikertOption(score: 5, label: 'Agak Puas'),
        _LikertOption(score: 6, label: 'Puas'),
        _LikertOption(score: 7, label: 'Sangat Puas'),
      ];
    case SurveyQuestionType.likert6:
      return const [
        _LikertOption(score: 1, label: 'Sangat Buruk'),
        _LikertOption(score: 2, label: 'Buruk'),
        _LikertOption(score: 3, label: 'Agak Buruk'),
        _LikertOption(score: 4, label: 'Agak Baik'),
        _LikertOption(score: 5, label: 'Baik'),
        _LikertOption(score: 6, label: 'Sangat Baik'),
      ];
    case SurveyQuestionType.likert6Puas:
      return const [
        _LikertOption(score: 1, label: 'Sangat Tidak Puas'),
        _LikertOption(score: 2, label: 'Tidak Puas'),
        _LikertOption(score: 3, label: 'Agak Tidak Puas'),
        _LikertOption(score: 4, label: 'Agak Puas'),
        _LikertOption(score: 5, label: 'Puas'),
        _LikertOption(score: 6, label: 'Sangat Puas'),
      ];
    case SurveyQuestionType.likert4:
      return const [
        _LikertOption(score: 1, label: 'Sangat Buruk'),
        _LikertOption(score: 2, label: 'Buruk'),
        _LikertOption(score: 3, label: 'Baik'),
        _LikertOption(score: 4, label: 'Sangat Baik'),
      ];
    case SurveyQuestionType.likert4Puas:
      return const [
        _LikertOption(score: 1, label: 'Sangat Tidak Puas'),
        _LikertOption(score: 2, label: 'Tidak Puas'),
        _LikertOption(score: 3, label: 'Puas'),
        _LikertOption(score: 4, label: 'Sangat Puas'),
      ];
    case SurveyQuestionType.likert3:
      return const [
        _LikertOption(score: 1, label: 'Buruk'),
        _LikertOption(score: 2, label: 'Netral'),
        _LikertOption(score: 3, label: 'Baik'),
      ];
    case SurveyQuestionType.likert3Puas:
      return const [
        _LikertOption(score: 1, label: 'Sangat Tidak Puas'),
        _LikertOption(score: 2, label: 'Netral'),
        _LikertOption(score: 3, label: 'Sangat Puas'),
      ];
    case SurveyQuestionType.likertQuality:
      return const [
        _LikertOption(score: 1, label: 'Sangat Buruk'),
        _LikertOption(score: 2, label: 'Buruk'),
        _LikertOption(score: 3, label: 'Netral'),
        _LikertOption(score: 4, label: 'Baik'),
        _LikertOption(score: 5, label: 'Sangat Baik'),
      ];
    case SurveyQuestionType.likert:
    default:
      return const [
        _LikertOption(score: 1, label: 'Sangat Tidak Puas'),
        _LikertOption(score: 2, label: 'Tidak Puas'),
        _LikertOption(score: 3, label: 'Netral'),
        _LikertOption(score: 4, label: 'Puas'),
        _LikertOption(score: 5, label: 'Sangat Puas'),
      ];
  }
}
