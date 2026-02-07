enum SurveyQuestionType {
  likert,
  likertQuality,
  likert4Puas,
  likert4,
  likert3Puas,
  likert3,
  yesNo,
  multipleChoice,
  text,
}

extension SurveyQuestionTypeX on SurveyQuestionType {
  String get label {
    switch (this) {
      case SurveyQuestionType.likert:
        return 'Skala Likert (1-5) - Puas';
      case SurveyQuestionType.likertQuality:
        return 'Skala Likert (1-5) - Baik';
      case SurveyQuestionType.likert4Puas:
        return 'Skala Likert (1-4) - Puas';
      case SurveyQuestionType.likert4:
        return 'Skala Likert (1-4) - Baik';
      case SurveyQuestionType.likert3Puas:
        return 'Skala Likert (1-3) - Puas';
      case SurveyQuestionType.likert3:
        return 'Skala Likert (1-3) - Baik';
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
    required this.framework,
    required this.categoryId,
    required this.questions,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String title;
  final String description;
  final String framework;
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
      framework: json['framework']?.toString() ?? '',
      categoryId: json['categoryId']?.toString() ?? '',
      questions: questions,
      createdAt: DateTime.tryParse(json['createdAt']?.toString() ?? '') ??
          DateTime.now(),
      updatedAt: DateTime.tryParse(json['updatedAt']?.toString() ?? '') ??
          DateTime.now(),
    );
  }
}

class SurveyResponseItem {
  const SurveyResponseItem({
    required this.id,
    required this.ticketId,
    required this.userName,
    required this.userEmail,
    required this.userEntity,
    required this.categoryId,
    required this.category,
    required this.templateId,
    required this.template,
    required this.score,
    required this.createdAt,
  });

  final String id;
  final String ticketId;
  final String userName;
  final String userEmail;
  final String userEntity;
  final String categoryId;
  final String category;
  final String templateId;
  final String template;
  final double score;
  final DateTime createdAt;

  factory SurveyResponseItem.fromJson(Map<String, dynamic> json) {
    return SurveyResponseItem(
      id: json['id']?.toString() ?? '',
      ticketId: json['ticketId']?.toString() ?? '',
      userName: json['userName']?.toString() ?? '',
      userEmail: json['userEmail']?.toString() ?? '',
      userEntity: json['userEntity']?.toString() ?? '',
      categoryId: json['categoryId']?.toString() ?? '',
      category: json['category']?.toString() ?? '',
      templateId: json['templateId']?.toString() ?? '',
      template: json['template']?.toString() ?? '',
      score: (json['score'] as num?)?.toDouble() ?? 0,
      createdAt: DateTime.tryParse(json['createdAt']?.toString() ?? '') ??
          DateTime.now(),
    );
  }
}

class SurveyResponsePage {
  const SurveyResponsePage({
    required this.items,
    required this.page,
    required this.limit,
    required this.total,
    required this.totalPages,
  });

  final List<SurveyResponseItem> items;
  final int page;
  final int limit;
  final int total;
  final int totalPages;

  bool get hasNext => page < totalPages;
  bool get hasPrev => page > 1;

  factory SurveyResponsePage.fromJson(Map<String, dynamic> json) {
    final items = (json['items'] as List<dynamic>? ?? [])
        .whereType<Map<String, dynamic>>()
        .map(SurveyResponseItem.fromJson)
        .toList();
    return SurveyResponsePage(
      items: items,
      page: (json['page'] as num?)?.toInt() ?? 1,
      limit: (json['limit'] as num?)?.toInt() ?? items.length,
      total: (json['total'] as num?)?.toInt() ?? items.length,
      totalPages: (json['totalPages'] as num?)?.toInt() ?? 1,
    );
  }
}

SurveyQuestionType _questionTypeFromString(String value) {
  switch (value) {
    case 'yesNo':
      return SurveyQuestionType.yesNo;
    case 'likertQuality':
      return SurveyQuestionType.likertQuality;
    case 'likert4Puas':
      return SurveyQuestionType.likert4Puas;
    case 'likert4':
      return SurveyQuestionType.likert4;
    case 'likert3Puas':
      return SurveyQuestionType.likert3Puas;
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
