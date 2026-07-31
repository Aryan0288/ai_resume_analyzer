import '../../domain/interview_question.dart';

class GenerateQuestionsResponse {
  final List<InterviewQuestion> questions;

  GenerateQuestionsResponse({required this.questions});

  factory GenerateQuestionsResponse.fromJson(Map<String, dynamic> json) {
    final list = (json['questions'] as List? ?? [])
        .map((item) => InterviewQuestion.fromJson(Map<String, dynamic>.from(item as Map)))
        .toList();
    return GenerateQuestionsResponse(questions: list);
  }

  Map<String, dynamic> toJson() => {
    'questions': questions.map((q) => q.toJson()).toList(),
  };
}
