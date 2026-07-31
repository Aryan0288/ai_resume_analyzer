class GenerateQuestionsRequest {
  final String resumeText;
  final String category;

  GenerateQuestionsRequest({
    required this.resumeText,
    required this.category,
  });

  Map<String, dynamic> toJson() => {
    'resumeText': resumeText,
    'category': category,
  };
}
