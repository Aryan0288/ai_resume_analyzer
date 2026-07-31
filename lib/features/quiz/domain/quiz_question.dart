class QuizQuestion {
  final String id;
  final String text;
  final List<String> options;
  final int correctOptionIndex;
  final String coachExplanation;
  final String difficulty;
  final int estimatedSeconds;

  QuizQuestion({
    required this.id,
    required this.text,
    required this.options,
    required this.correctOptionIndex,
    required this.coachExplanation,
    required this.difficulty,
    required this.estimatedSeconds,
  });

  factory QuizQuestion.fromJson(Map<String, dynamic> json) {
    return QuizQuestion(
      id: (json['id'] ?? '') as String,
      text: (json['text'] ?? '') as String,
      options: List<String>.from(json['options'] ?? []),
      correctOptionIndex: (json['correctOptionIndex'] ?? 0) as int,
      coachExplanation: (json['coachExplanation'] ?? '') as String,
      difficulty: (json['difficulty'] ?? 'Medium') as String,
      estimatedSeconds: (json['estimatedSeconds'] ?? 60) as int,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'text': text,
    'options': options,
    'correctOptionIndex': correctOptionIndex,
    'coachExplanation': coachExplanation,
    'difficulty': difficulty,
    'estimatedSeconds': estimatedSeconds,
  };
}
