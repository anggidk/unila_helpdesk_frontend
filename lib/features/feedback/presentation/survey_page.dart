import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:unila_helpdesk_frontend/app/app_theme.dart';
import 'package:unila_helpdesk_frontend/core/models/survey_models.dart';
import 'package:unila_helpdesk_frontend/core/models/ticket_models.dart';
import 'package:unila_helpdesk_frontend/core/network/api_client.dart';
import 'package:unila_helpdesk_frontend/core/utils/snackbar_utils.dart';
import 'package:unila_helpdesk_frontend/core/widgets/user_top_app_bar.dart';
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
    final requiredQuestions = questions
        .where(_isRequiredSurveyQuestion)
        .toList();
    final answeredRequiredCount = requiredQuestions
        .where((question) => _hasSurveyAnswer(answers[question.id], question))
        .length;
    final progress = requiredQuestions.isEmpty
        ? 0.0
        : answeredRequiredCount / requiredQuestions.length;
    return Scaffold(
      appBar: UserTopAppBar(titleText: 'Survei Kepuasan'),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Text(
            'Langkah $answeredRequiredCount dari ${requiredQuestions.length}',
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
                      for (final question in requiredQuestions) {
                        final value = answers[question.id];
                        if (!_hasSurveyAnswer(value, question)) {
                          nextErrors[question.id] = 'Jawaban wajib diisi.';
                        }
                      }

                      if (nextErrors.isNotEmpty) {
                        ref.read(surveyErrorsProvider.notifier).state =
                            nextErrors;
                        showAppSnackBar(
                          context,
                          message: 'Mohon lengkapi semua jawaban wajib.',
                          tone: AppSnackTone.warning,
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
                          if (!context.mounted) return;
                          showAppSnackBar(
                            context,
                            message: _surveySubmitErrorMessage(response.error),
                            tone: AppSnackTone.error,
                          );
                          return;
                        }
                        if (!context.mounted) return;
                        showAppSnackBar(
                          context,
                          message: 'Survei berhasil dikirim.',
                          tone: AppSnackTone.success,
                        );
                        Navigator.of(context).pop(true);
                      } catch (error) {
                        if (!context.mounted) return;
                        showAppSnackBar(
                          context,
                          message: _normalizeUnexpectedError(error),
                          tone: AppSnackTone.error,
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
                if (_isRequiredSurveyQuestion(question))
                  const TextSpan(
                    text: ' *',
                    style: TextStyle(color: AppTheme.danger),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          if (question.type.isLikertFamily)
            RadioGroup<int>(
              groupValue: value as int?,
              onChanged: onChanged,
              child: Column(
                children: _likertOptions(question)
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
              decoration: const InputDecoration(
                hintText: 'Tulis jawaban Anda (opsional)',
              ),
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

bool _isRequiredSurveyQuestion(SurveyQuestion question) {
  return question.type != SurveyQuestionType.text;
}

bool _hasSurveyAnswer(dynamic value, SurveyQuestion question) {
  if (value == null) {
    return false;
  }

  if (question.type == SurveyQuestionType.text) {
    return value.toString().trim().isNotEmpty;
  }
  return true;
}

String _surveySubmitErrorMessage(ApiError? error) {
  final status = error?.statusCode;
  final message = _cleanErrorText(error?.message ?? '');
  final lower = message.toLowerCase();

  if (_isNetworkError(lower)) {
    return 'Tidak dapat terhubung ke server. Periksa koneksi internet lalu coba lagi.';
  }
  if (status == 401 || status == 403 || lower.contains('unauthorized')) {
    return 'Sesi login berakhir. Silakan login ulang.';
  }
  if (lower.contains('belum done') ||
      lower.contains('ticket belum done') ||
      lower.contains('status done')) {
    return 'Tiket belum selesai. Survei hanya bisa diisi jika status tiket DONE.';
  }
  if (lower.contains('template') && lower.contains('belum')) {
    return 'Template survei belum tersedia untuk tiket ini.';
  }
  if (lower.contains('already') ||
      (lower.contains('sudah') && lower.contains('survei'))) {
    return 'Survei untuk tiket ini sudah pernah dikirim.';
  }
  if (status == 404 || lower.contains('not found')) {
    return 'Data tiket/survei tidak ditemukan. Muat ulang lalu coba lagi.';
  }
  if (status == 422 ||
      lower.contains('validation') ||
      lower.contains('jawaban') ||
      lower.contains('wajib')) {
    return 'Jawaban survei belum valid. Periksa kembali isian Anda.';
  }
  if (status != null && status >= 500) {
    return 'Server sedang bermasalah. Coba beberapa saat lagi.';
  }
  if (status == null && message.isNotEmpty) {
    return message;
  }
  return 'Survei gagal dikirim. Periksa jawaban lalu coba lagi.';
}

String _normalizeUnexpectedError(Object error) {
  final cleaned = _cleanErrorText(error.toString());
  final lower = cleaned.toLowerCase();
  if (_isNetworkError(lower)) {
    return 'Tidak dapat terhubung ke server. Periksa koneksi internet lalu coba lagi.';
  }
  return 'Survei gagal dikirim. Silakan coba lagi.';
}

String _cleanErrorText(String value) {
  var text = value.trim();
  if (text.startsWith('Exception:')) {
    text = text.replaceFirst('Exception:', '').trim();
  }
  if (text.startsWith('ClientException:')) {
    text = text.replaceFirst('ClientException:', '').trim();
  }
  return text;
}

bool _isNetworkError(String message) {
  return message.contains('failed host lookup') ||
      message.contains('socketexception') ||
      message.contains('connection reset') ||
      message.contains('timed out') ||
      message.contains('failed to fetch') ||
      message.contains('network');
}

class _LikertOption {
  const _LikertOption({required this.score, required this.label});

  final int score;
  final String label;
}

List<_LikertOption> _likertOptions(SurveyQuestion question) {
  if (question.options.isNotEmpty) {
    return question.options
        .asMap()
        .entries
        .map((entry) => _LikertOption(score: entry.key + 1, label: entry.value))
        .toList();
  }

  switch (question.type) {
    case SurveyQuestionType.likert3:
      return const [
        _LikertOption(score: 1, label: 'Rendah'),
        _LikertOption(score: 2, label: 'Sedang'),
        _LikertOption(score: 3, label: 'Tinggi'),
      ];
    case SurveyQuestionType.likert4:
      return const [
        _LikertOption(score: 1, label: 'Sangat Rendah'),
        _LikertOption(score: 2, label: 'Rendah'),
        _LikertOption(score: 3, label: 'Tinggi'),
        _LikertOption(score: 4, label: 'Sangat Tinggi'),
      ];
    case SurveyQuestionType.likert5:
    default:
      return const [
        _LikertOption(score: 1, label: 'Sangat Rendah'),
        _LikertOption(score: 2, label: 'Rendah'),
        _LikertOption(score: 3, label: 'Sedang'),
        _LikertOption(score: 4, label: 'Tinggi'),
        _LikertOption(score: 5, label: 'Sangat Tinggi'),
      ];
  }
}
