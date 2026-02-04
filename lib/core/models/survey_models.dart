enum SurveyQuestionType { likert, likert7, likert6, likert4, likert3, yesNo, multipleChoice, text }

extension SurveyQuestionTypeX on SurveyQuestionType {
  String get label {
    switch (this) {
      case SurveyQuestionType.likert:
        return 'Skala Likert (1-5)';
      case SurveyQuestionType.likert7:
        return 'Skala Likert (1-7)';
      case SurveyQuestionType.likert6:
        return 'Skala Likert (1-6)';
      case SurveyQuestionType.likert4:
        return 'Skala Likert (1-4)';
      case SurveyQuestionType.likert3:
        return 'Skala Likert (1-3)';
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
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String title;
  final String description;
  final String categoryId;
  final List<SurveyQuestion> questions;
  final DateTime createdAt;
  final DateTime updatedAt;

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
      createdAt: DateTime.tryParse(json['createdAt']?.toString() ?? '') ??
          DateTime.now(),
      updatedAt: DateTime.tryParse(json['updatedAt']?.toString() ?? '') ??
          DateTime.now(),
    );
  }
}

SurveyQuestionType _questionTypeFromString(String value) {
  switch (value) {
    case 'yesNo':
      return SurveyQuestionType.yesNo;
    case 'likert7':
      return SurveyQuestionType.likert7;
    case 'likert6':
      return SurveyQuestionType.likert6;
    case 'likert4':
      return SurveyQuestionType.likert4;
    case 'likert3':
      return SurveyQuestionType.likert3;
    case 'multipleChoice':
      return SurveyQuestionType.multipleChoice;
    case 'text':
      return SurveyQuestionType.text;
    default:
      return SurveyQuestionType.likert;
  }
}
