import 'package:flutter/material.dart';
import '../domain/quiz_question.dart';
import '../data/quiz_repository.dart';
import '../data/models/generate_quiz_request.dart';

class QuizProvider extends ChangeNotifier {
  bool _isTakingQuiz = false;
  bool get isTakingQuiz => _isTakingQuiz;

  bool _showResults = false;
  bool get showResults => _showResults;

  String? _selectedQuizPath;
  String? get selectedQuizPath => _selectedQuizPath;

  final int _overallReadinessScore = 78;
  int get overallReadinessScore => _overallReadinessScore;

  int _activeQuestionIndex = 0;
  int get activeQuestionIndex => _activeQuestionIndex;

  int? _selectedOptionIndex;
  int? get selectedOptionIndex => _selectedOptionIndex;

  bool _isAnswerSubmitted = false;
  bool get isAnswerSubmitted => _isAnswerSubmitted;

  double _confidenceRating = 3.0;
  double get confidenceRating => _confidenceRating;

  int _timerSeconds = 0;
  int get timerSeconds => _timerSeconds;

  int _quizScore = 0;
  int get quizScore => _quizScore;

  List<QuizQuestion> _questions = [];
  List<QuizQuestion> get questions => _questions;

  // Track user selected option for each question
  final Map<String, int> _userAnswers = {};
  Map<String, int> get userAnswers => _userAnswers;

  // Track confidence logs for review
  final Map<String, double> _confidenceHistory = {};
  Map<String, double> get confidenceHistory => _confidenceHistory;

  int get correctAnswersCount {
    int count = 0;
    for (final q in _questions) {
      if (_userAnswers[q.id] == q.correctOptionIndex) {
        count++;
      }
    }
    return count;
  }

  int get quizScorePercentage {
    if (_questions.isEmpty) return 0;
    return ((correctAnswersCount / _questions.length) * 100).round();
  }

  String _currentQuizId = '';

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  final QuizRepository _repository;

  QuizProvider(this._repository);

  /// Start a quiz — generates dynamic skill questions via Gemini AI.
  Future<void> startQuiz(String uid, String path, List<String> skills, [String resumeText = '']) async {
    _selectedQuizPath = path;
    _isLoading = true;
    _isTakingQuiz = false;
    notifyListeners();

    try {
      final response = await _repository.generateQuiz(
        uid,
        GenerateQuizRequest(resumeText: resumeText, skills: skills),
      );
      _questions = response.questions;
      _currentQuizId = DateTime.now().millisecondsSinceEpoch.toString();
    } catch (_) {}

    _isTakingQuiz = true;
    _showResults = false;
    _activeQuestionIndex = 0;
    _selectedOptionIndex = null;
    _isAnswerSubmitted = false;
    _confidenceRating = 3.0;
    _timerSeconds = 0;
    _quizScore = 0;
    _userAnswers.clear();
    _confidenceHistory.clear();
    _isLoading = false;
    notifyListeners();
  }

  void selectOption(int index) {
    if (_isAnswerSubmitted) return; // Lock options after submission
    _selectedOptionIndex = index;
    notifyListeners();
  }

  void updateConfidence(double rating) {
    _confidenceRating = rating;
    notifyListeners();
  }

  void tickTimer() {
    _timerSeconds++;
    notifyListeners();
  }

  /// Submit answer for current question to trigger AI explanation
  void submitCurrentAnswer() {
    if (_selectedOptionIndex == null || _questions.isEmpty) return;
    final currentQ = _questions[_activeQuestionIndex];
    _userAnswers[currentQ.id] = _selectedOptionIndex!;
    _confidenceHistory[currentQ.id] = _confidenceRating;
    _isAnswerSubmitted = true;
    notifyListeners();
  }

  /// Move to next question or display results if last question
  void nextQuestion({String uid = 'anonymous'}) {
    if (_activeQuestionIndex < _questions.length - 1) {
      _activeQuestionIndex++;
      _selectedOptionIndex = null;
      _isAnswerSubmitted = false;
      _confidenceRating = 3.0;
      _timerSeconds = 0;
      notifyListeners();
    } else {
      _quizScore = quizScorePercentage;
      _isTakingQuiz = false;
      _showResults = true;
      _logScoreToFirestore(uid);
      notifyListeners();
    }
  }

  /// Log score to Firestore after quiz ends.
  Future<void> _logScoreToFirestore(String uid) async {
    try {
      await _repository.logQuizScore(uid, _currentQuizId, _quizScore, _questions.length);
    } catch (_) {
      // Silently ignore scoring log failures
    }
  }

  void resetQuiz() {
    _isTakingQuiz = false;
    _showResults = false;
    _selectedQuizPath = null;
    _activeQuestionIndex = 0;
    _selectedOptionIndex = null;
    _isAnswerSubmitted = false;
    _confidenceRating = 3.0;
    _timerSeconds = 0;
    _quizScore = 0;
    notifyListeners();
  }

  /// Complete reset of quiz session state and questions list for new user/resume.
  void resetAll() {
    _isTakingQuiz = false;
    _showResults = false;
    _selectedQuizPath = null;
    _activeQuestionIndex = 0;
    _selectedOptionIndex = null;
    _isAnswerSubmitted = false;
    _confidenceRating = 3.0;
    _timerSeconds = 0;
    _quizScore = 0;
    _questions = [];
    _userAnswers.clear();
    _confidenceHistory.clear();
    _isLoading = false;
    notifyListeners();
  }
}
