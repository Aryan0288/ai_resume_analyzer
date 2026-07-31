import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import '../domain/quiz_question.dart';
import 'models/generate_quiz_request.dart';
import 'models/generate_quiz_response.dart';
import '../../../core/services/gemini_service.dart';

class QuizRepository {
  final FirebaseFirestore? _firestore;
  final FirebaseFunctions? _functions;

  QuizRepository([this._firestore, this._functions]);

  Future<GenerateQuizResponse> generateQuiz(
    String uid,
    GenerateQuizRequest request,
  ) async {
    // 1. Direct client-side Gemini call when API key is configured
    if (GeminiService.isApiKeyConfigured) {
      final directResponse = await GeminiService.generateQuiz(request.skills);
      if (directResponse != null) return directResponse;
    }

    // 2. Try Firebase Cloud Function if available
    if (_functions != null) {
      try {
        final HttpsCallable callable = _functions.httpsCallable('generateQuiz');
        final HttpsCallableResult result = await callable.call(request.toJson());
        return GenerateQuizResponse.fromJson(Map<String, dynamic>.from(result.data as Map));
      } catch (_) {}
    }

    // 3. Mock fallback
    return GenerateQuizResponse(
      questions: [
        QuizQuestion(
          id: 'qz_1',
          text: 'What is the primary benefit of ProxyProvider in Provider package?',
          options: [
            'Allows building target state based on changes in another Provider.',
            'Compiles Flutter code directly to WebAssembly.',
            'Restricts HTTP requests to local device storage.',
            'Provides native GPU acceleration for text widgets.',
          ],
          correctOptionIndex: 0,
          difficulty: 'Medium',
          estimatedSeconds: 30,
          coachExplanation: 'ProxyProvider builds and updates state based on dependent Provider objects.',
        ),
      ],
    );
  }

  Future<void> logQuizScore(
    String uid,
    String quizId,
    int score,
    int totalQuestions,
  ) async {
    if (_firestore == null) return;
    try {
      await _firestore
          .collection('users')
          .doc(uid)
          .collection('quizzes')
          .doc(quizId)
          .set({
        'score': score,
        'totalQuestions': totalQuestions,
        'completedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } catch (_) {}
  }

  Future<List<Map<String, dynamic>>> getQuizHistory(String uid) async {
    if (_firestore == null) return [];
    try {
      final QuerySnapshot query = await _firestore
          .collection('users')
          .doc(uid)
          .collection('quizzes')
          .orderBy('generatedAt', descending: true)
          .get();
          
      return query.docs.map((doc) => Map<String, dynamic>.from(doc.data() as Map)).toList();
    } catch (_) {
      return [];
    }
  }
}
