import 'package:flutter/material.dart';
import '../domain/interview_question.dart';
import '../data/interview_repository.dart';
import '../data/models/generate_questions_request.dart';
import '../data/models/evaluate_answer_request.dart';

class InterviewProvider extends ChangeNotifier {
  bool _isPracticing = false;
  bool get isPracticing => _isPracticing;

  String? _selectedCategory;
  String? get selectedCategory => _selectedCategory;

  int _completedCount = 0;
  int get completedCount => _completedCount;

  final double _averageScore = 0.0;
  double get averageScore => _averageScore;

  int _activeQuestionIndex = 0;
  int get activeQuestionIndex => _activeQuestionIndex;

  bool _isRecording = false;
  bool get isRecording => _isRecording;

  bool _showAICoach = false;
  bool get showAICoach => _showAICoach;

  double _confidenceRating = 3.0;
  double get confidenceRating => _confidenceRating;

  double _difficultyRating = 3.0;
  double get difficultyRating => _difficultyRating;

  // Track timer seconds
  int _timerSeconds = 0;
  int get timerSeconds => _timerSeconds;

  List<InterviewQuestion> _questions = [];
  List<InterviewQuestion> get questions => _questions;

  List<InterviewQuestion> get activeCategoryQuestions {
    if (_selectedCategory == null) return [];
    return _questions.where((q) => q.category == _selectedCategory).toList();
  }

  InterviewQuestion? get currentQuestion {
    final list = activeCategoryQuestions;
    if (list.isEmpty || _activeQuestionIndex >= list.length) return null;
    return list[_activeQuestionIndex];
  }

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  String _aiEvaluationText = '';
  String get aiEvaluationText => _aiEvaluationText;

  final InterviewRepository _repository;

  InterviewProvider(this._repository);

  void selectCategory(String category) {
    _selectedCategory = category;
    _isPracticing = true;
    _activeQuestionIndex = 0;
    _showAICoach = false;
    _timerSeconds = 0;
    notifyListeners();
  }

  void exitPractice() {
    _isPracticing = false;
    _selectedCategory = null;
    _showAICoach = false;
    notifyListeners();
  }

  void setQuestionIndex(int index) {
    if (index >= 0 && index < _questions.length) {
      final question = _questions[index];
      final activeIndex = activeCategoryQuestions.indexOf(question);
      if (activeIndex != -1) {
        _activeQuestionIndex = activeIndex;
        _showAICoach = false;
        _timerSeconds = 0;
        notifyListeners();
      }
    }
  }

  void nextQuestion() {
    final maxIndex = activeCategoryQuestions.length - 1;
    if (_activeQuestionIndex < maxIndex) {
      _activeQuestionIndex++;
      _showAICoach = false;
      _timerSeconds = 0;
      notifyListeners();
    }
  }

  void previousQuestion() {
    if (_activeQuestionIndex > 0) {
      _activeQuestionIndex--;
      _showAICoach = false;
      _timerSeconds = 0;
      notifyListeners();
    }
  }

  void toggleRecording() {
    _isRecording = !_isRecording;
    notifyListeners();
  }

  void toggleAICoach() {
    _showAICoach = !_showAICoach;
    notifyListeners();
  }

  void updateConfidence(double value) {
    _confidenceRating = value;
    notifyListeners();
  }

  void updateDifficulty(double value) {
    _difficultyRating = value;
    notifyListeners();
  }

  void tickTimer() {
    _timerSeconds++;
    notifyListeners();
  }

  /// Submit answer — calls evaluateAnswer Cloud Function, falls back to mock feedback.
  Future<void> saveAnswer(String uid, String answerText) async {
    final list = activeCategoryQuestions;
    if (list.isEmpty || _activeQuestionIndex >= list.length) return;

    final question = list[_activeQuestionIndex];
    final fullListIndex = _questions.indexWhere((q) => q.id == question.id);
    if (fullListIndex == -1) return;

    _isLoading = true;
    notifyListeners();

    String evaluation = '';
    try {
      final response = await _repository.evaluateAnswer(
        uid,
        question.id,
        EvaluateAnswerRequest(questionText: question.text, userAnswer: answerText),
      );
      evaluation = response.feedback;
      _aiEvaluationText = evaluation;
    } catch (_) {
      evaluation = 'AI Coach Evaluated: Your answer provides solid points. Consider clarifying execution metrics to improve rating.';
      _aiEvaluationText = evaluation;
    }

    _questions[fullListIndex] = _questions[fullListIndex].copyWith(
      isCompleted: true,
      savedAnswer: answerText,
      aiEvaluation: evaluation,
    );
    _completedCount = _questions.where((q) => q.isCompleted).length;
    _showAICoach = true;
    _isLoading = false;
    notifyListeners();
  }

  /// Load questions or generate fresh dynamic Gemini interview questions based on resume text.
  Future<void> loadOrGenerateQuestions(String uid, String resumeText, [String? category]) async {
    if (resumeText.trim().isEmpty) return;
    _isLoading = true;
    notifyListeners();
    try {
      final reqCategory = category ?? _selectedCategory ?? 'General';
      final response = await _repository.generateQuestions(
        uid,
        GenerateQuestionsRequest(resumeText: resumeText, category: reqCategory),
      );
      if (response.questions.isNotEmpty) {
        _questions = response.questions;
        _completedCount = _questions.where((q) => q.isCompleted).length;
      }
    } catch (_) {}
    _isLoading = false;
    notifyListeners();
  }

  /// Complete reset of interview session state and questions list for new user/resume.
  void resetAll() {
    _isPracticing = false;
    _selectedCategory = null;
    _completedCount = 0;
    _activeQuestionIndex = 0;
    _isRecording = false;
    _showAICoach = false;
    _confidenceRating = 3.0;
    _difficultyRating = 3.0;
    _timerSeconds = 0;
    _questions = [];
    _isLoading = false;
    _aiEvaluationText = '';
    notifyListeners();
  }
}
