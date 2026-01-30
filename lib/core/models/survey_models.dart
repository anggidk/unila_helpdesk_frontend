enum SurveyQuestionType { likert, yesNo, multipleChoice, text }

extension SurveyQuestionTypeX on SurveyQuestionType {
  String get label {
    switch (this) {
      case SurveyQuestionType.likert:
        return 'Skala Likert (1-5)';
      case SurveyQuestionType.yesNo:
        return 'Ya / Tidak';
      case SurveyQuestionType.multipleChoice:
        return 'Pilihan Ganda';
      case SurveyQuestionType.text:
        return 'Jawaban Bebas';
    }
  }
}

class SurveyQuestion {
  const SurveyQuestion({
    required this.id,
    required this.text,
    required this.type,
    this.options = const [],
  });

  final String id;
  final String text;
  final SurveyQuestionType type;
  final List<String> options;
}

class SurveyTemplate {
  const SurveyTemplate({
    required this.id,
    required this.title,
    required this.description,
    required this.categoryId,
    required this.questions,
  });

  final String id;
  final String title;
  final String description;
  final String categoryId;
  final List<SurveyQuestion> questions;
}
