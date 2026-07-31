class EvaluateAnswerRequest {
  final String questionText;
  final String userAnswer;

  EvaluateAnswerRequest({
    required this.questionText,
    required this.userAnswer,
  });

  Map<String, dynamic> toJson() => {
    'questionText': questionText,
    'userAnswer': userAnswer,
  };
}
