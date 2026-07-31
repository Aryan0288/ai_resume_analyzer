import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import '../domain/critique_item.dart';
import 'models/analyze_resume_request.dart';
import 'models/analyze_resume_response.dart';
import '../../../core/services/gemini_service.dart';

class ResumeRepository {
  final FirebaseFirestore? _firestore;
  final FirebaseFunctions? _functions;

  ResumeRepository([this._firestore, this._functions]);

  Future<void> saveResumeText(String uid, String resumeId, String text, String targetRole) async {
    if (_firestore == null) return;
    try {
      await _firestore.collection('users').doc(uid).collection('resumes').doc(resumeId).set({
        'resumeText': text,
        'targetRole': targetRole,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } catch (_) {
      // Silently ignore Firestore write failures in offline / unconfigured Firebase mode
    }
  }

  Future<AnalyzeResumeResponse> analyzeResume(String uid, String resumeId, AnalyzeResumeRequest request) async {
    // 1. Direct client-side Gemini call when API key is configured
    if (GeminiService.isApiKeyConfigured) {
      final directResponse = await GeminiService.analyzeResume(request.resumeText, request.targetRole);
      if (directResponse != null) {
        return directResponse;
      }
    }

    // 2. Try Firebase Cloud Function if configured
    if (_functions != null) {
      try {
        final HttpsCallable callable = _functions.httpsCallable('analyzeResume');
        final HttpsCallableResult result = await callable.call(request.toJson());
        return AnalyzeResumeResponse.fromJson(Map<String, dynamic>.from(result.data as Map));
      } catch (_) {}
    }

    // 3. Fallback mock data
    return AnalyzeResumeResponse(
      healthScore: 72,
      critiques: [
        CritiqueItem(
          id: 'crit_1',
          type: 'weakness',
          title: 'Missing Quantifiable Metrics in Experience',
          description: 'Your bullet points describe tasks without metric outcomes.',
          beforeText: 'Collaborated with team to deploy mobile app.',
          afterText: 'Coordinated deployments on AWS ECS, improving release cycles by 14%.',
        ),
        CritiqueItem(
          id: 'crit_2',
          type: 'suggestion',
          title: 'Unstructured Skill Categorization',
          description: 'The skills section lists all tools in a single line.',
          beforeText: 'Dart, Flutter, Provider, HTML, CSS, JavaScript, Git, Firebase',
          afterText: '• Mobile: Flutter, Dart\n• State Management: Provider\n• Web: HTML, CSS, JS',
        ),
      ],
    );
  }

  Future<AnalyzeResumeResponse?> getSavedAnalysis(String uid, String resumeId) async {
    if (_firestore == null) return null;
    final DocumentSnapshot doc = await _firestore
        .collection('users')
        .doc(uid)
        .collection('resumes')
        .doc(resumeId)
        .get();
        
    if (!doc.exists || doc.data() == null) return null;
    final data = Map<String, dynamic>.from(doc.data() as Map);
    if (!data.containsKey('healthScore')) return null;
    return AnalyzeResumeResponse.fromJson(data);
  }
}
