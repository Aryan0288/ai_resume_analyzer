class AnalyzeResumeRequest {
  final String resumeText;
  final String targetRole;

  AnalyzeResumeRequest({
    required this.resumeText,
    required this.targetRole,
  });

  Map<String, dynamic> toJson() => {
    'resumeText': resumeText,
    'targetRole': targetRole,
  };
}
