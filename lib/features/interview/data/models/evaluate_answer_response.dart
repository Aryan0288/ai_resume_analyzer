class EvaluateAnswerResponse {
  final int overallScore;
  final String feedback;
  final String sampleAnswer;
  final Map<String, int> subMetrics; // Bento Grid scoring points

  EvaluateAnswerResponse({
    required this.overallScore,
    required this.feedback,
    required this.sampleAnswer,
    required this.subMetrics,
  });

  factory EvaluateAnswerResponse.fromJson(Map<String, dynamic> json) {
    return EvaluateAnswerResponse(
      overallScore: (json['overallScore'] ?? 0) as int,
      feedback: (json['feedback'] ?? '') as String,
      sampleAnswer: (json['sampleAnswer'] ?? '') as String,
      subMetrics: Map<String, int>.from(json['subMetrics'] ?? {}),
    );
  }

  Map<String, dynamic> toJson() => {
    'overallScore': overallScore,
    'feedback': feedback,
    'sampleAnswer': sampleAnswer,
    'subMetrics': subMetrics,
  };
}
