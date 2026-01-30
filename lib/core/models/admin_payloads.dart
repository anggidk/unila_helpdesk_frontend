import 'package:unila_helpdesk_frontend/core/models/survey_models.dart';

class AddQuestionPayload {
  const AddQuestionPayload({
    required this.question,
    required this.categoryId,
    required this.isRequired,
  });

  final SurveyQuestion question;
  final String categoryId;
  final bool isRequired;
}
