import 'package:unila_helpdesk_frontend/core/models/survey_models.dart';

class AddQuestionPayload {
  const AddQuestionPayload({
    required this.question,
  });

  final SurveyQuestion question;
}
