class CompileReportRequest {
  final String resumeText;
  final String targetRole;

  CompileReportRequest({
    required this.resumeText,
    required this.targetRole,
  });

  Map<String, dynamic> toJson() => {
    'resumeText': resumeText,
    'targetRole': targetRole,
  };
}
