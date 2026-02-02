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

  factory SurveyQuestion.fromJson(Map<String, dynamic> json) {
    final options = (json['options'] as List<dynamic>? ?? [])
        .map((value) => value.toString())
        .toList();
    return SurveyQuestion(
      id: json['id']?.toString() ?? '',
      text: json['text']?.toString() ?? '',
      type: _questionTypeFromString(json['type']?.toString() ?? ''),
      options: options,
    );
  }
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

  factory SurveyTemplate.fromJson(Map<String, dynamic> json) {
    final questions = (json['questions'] as List<dynamic>? ?? [])
        .whereType<Map<String, dynamic>>()
        .map(SurveyQuestion.fromJson)
        .toList();
    return SurveyTemplate(
      id: json['id']?.toString() ?? '',
      title: json['title']?.toString() ?? '',
      description: json['description']?.toString() ?? '',
      categoryId: json['categoryId']?.toString() ?? '',
      questions: questions,
    );
  }
}

SurveyQuestionType _questionTypeFromString(String value) {
  switch (value) {
    case 'yesNo':
      return SurveyQuestionType.yesNo;
    case 'multipleChoice':
      return SurveyQuestionType.multipleChoice;
    case 'text':
      return SurveyQuestionType.text;
    default:
      return SurveyQuestionType.likert;
  }
}
