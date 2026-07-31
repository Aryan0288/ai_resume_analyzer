class InterviewQuestion {
  final String id;
  final String category;
  final String text;
  final String difficulty; // 'Easy', 'Medium', 'Hard'
  final int estimatedMinutes;
  bool isCompleted;
  String savedAnswer;
  String aiEvaluation;

  InterviewQuestion({
    required this.id,
    required this.category,
    required this.text,
    required this.difficulty,
    required this.estimatedMinutes,
    this.isCompleted = false,
    this.savedAnswer = '',
    this.aiEvaluation = '',
  });

  InterviewQuestion copyWith({
    bool? isCompleted,
    String? savedAnswer,
    String? aiEvaluation,
  }) {
    return InterviewQuestion(
      id: id,
      category: category,
      text: text,
      difficulty: difficulty,
      estimatedMinutes: estimatedMinutes,
      isCompleted: isCompleted ?? this.isCompleted,
      savedAnswer: savedAnswer ?? this.savedAnswer,
      aiEvaluation: aiEvaluation ?? this.aiEvaluation,
    );
  }

  factory InterviewQuestion.fromJson(Map<String, dynamic> json) {
    return InterviewQuestion(
      id: (json['id'] ?? '') as String,
      category: (json['category'] ?? '') as String,
      text: (json['text'] ?? '') as String,
      difficulty: (json['difficulty'] ?? 'Medium') as String,
      estimatedMinutes: (json['estimatedMinutes'] ?? 5) as int,
      isCompleted: (json['isCompleted'] ?? false) as bool,
      savedAnswer: (json['savedAnswer'] ?? '') as String,
      aiEvaluation: (json['aiEvaluation'] ?? '') as String,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'category': category,
    'text': text,
    'difficulty': difficulty,
    'estimatedMinutes': estimatedMinutes,
    'isCompleted': isCompleted,
    'savedAnswer': savedAnswer,
    'aiEvaluation': aiEvaluation,
  };
}
