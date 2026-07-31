class GenerateQuizRequest {
  final String resumeText;
  final List<String> skills;

  GenerateQuizRequest({
    required this.resumeText,
    required this.skills,
  });

  Map<String, dynamic> toJson() => {
    'resumeText': resumeText,
    'skills': skills,
  };
}
