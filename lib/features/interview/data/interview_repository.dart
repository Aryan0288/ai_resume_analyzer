import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import '../domain/interview_question.dart';
import 'models/generate_questions_request.dart';
import 'models/generate_questions_response.dart';
import 'models/evaluate_answer_request.dart';
import 'models/evaluate_answer_response.dart';
import '../../../core/services/gemini_service.dart';

class InterviewRepository {
  final FirebaseFirestore? _firestore;
  final FirebaseFunctions? _functions;

  InterviewRepository([this._firestore, this._functions]);

  Future<GenerateQuestionsResponse> generateQuestions(
    String uid,
    GenerateQuestionsRequest request,
  ) async {
    // 1. Direct client-side Gemini call when API key is configured
    if (GeminiService.isApiKeyConfigured) {
      final directResponse = await GeminiService.generateQuestions(request.resumeText, request.category);
      if (directResponse != null) return directResponse;
    }

    // 2. Try Firebase Cloud Function if available
    if (_functions != null) {
      try {
        final HttpsCallable callable = _functions.httpsCallable('generateQuestions');
        final HttpsCallableResult result = await callable.call(request.toJson());
        return GenerateQuestionsResponse.fromJson(Map<String, dynamic>.from(result.data as Map));
      } catch (_) {}
    }

    // 3. Mock fallback
    return GenerateQuestionsResponse(
      questions: [
        InterviewQuestion(
          id: 'q_1',
          category: request.category,
          difficulty: 'Medium',
          text: 'How do you structure complex cross-platform state management?',
          estimatedMinutes: 5,
        ),
      ],
    );
  }

  Future<EvaluateAnswerResponse> evaluateAnswer(
    String uid,
    String questionId,
    EvaluateAnswerRequest request,
  ) async {
    // 1. Direct client-side Gemini call when API key is configured
    if (GeminiService.isApiKeyConfigured) {
      final directResponse = await GeminiService.evaluateAnswer(request.questionText, request.userAnswer);
      if (directResponse != null) return directResponse;
    }

    // 2. Try Firebase Cloud Function if available
    if (_functions != null) {
      try {
        final HttpsCallable callable = _functions.httpsCallable('evaluateAnswer');
        final HttpsCallableResult result = await callable.call(request.toJson());
        return EvaluateAnswerResponse.fromJson(Map<String, dynamic>.from(result.data as Map));
      } catch (_) {}
    }

    // 3. Mock fallback
    return EvaluateAnswerResponse(
      feedback: 'Good response! Consider using the STAR method for stronger quantifiable metrics.',
      overallScore: 8,
      sampleAnswer: 'In my previous project, I structured architecture using Provider...',
      subMetrics: {
        'Technical Accuracy': 9,
        'STAR Format': 8,
        'Clarity': 8,
      },
    );
  }

  Future<List<InterviewQuestion>> getSavedQuestions(String uid) async {
    if (_firestore == null) return [];
    try {
      final QuerySnapshot query = await _firestore
          .collection('users')
          .doc(uid)
          .collection('interviews')
          .get();
          
      return query.docs
          .map((doc) => InterviewQuestion.fromJson(Map<String, dynamic>.from(doc.data() as Map)))
          .toList();
    } catch (_) {
      return [];
    }
  }
}
