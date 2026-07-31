import '../../domain/quiz_question.dart';

class GenerateQuizResponse {
  final List<QuizQuestion> questions;

  GenerateQuizResponse({required this.questions});

  factory GenerateQuizResponse.fromJson(Map<String, dynamic> json) {
    final list = (json['questions'] as List? ?? [])
        .map((item) => QuizQuestion.fromJson(Map<String, dynamic>.from(item as Map)))
        .toList();
    return GenerateQuizResponse(questions: list);
  }

  Map<String, dynamic> toJson() => {
    'questions': questions.map((q) => q.toJson()).toList(),
  };
}
