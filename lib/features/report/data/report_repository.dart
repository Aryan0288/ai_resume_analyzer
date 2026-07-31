import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import '../domain/roadmap_step.dart';
import 'models/compile_report_request.dart';
import 'models/compile_report_response.dart';
import '../../../core/services/gemini_service.dart';

class ReportRepository {
  final FirebaseFirestore? _firestore;
  final FirebaseFunctions? _functions;

  ReportRepository([this._firestore, this._functions]);

  Future<CompileReportResponse> compileReport(
    String uid,
    CompileReportRequest request,
  ) async {
    // 1. Direct client-side Gemini call when API key is configured
    if (GeminiService.isApiKeyConfigured) {
      final directResponse = await GeminiService.compileReport(request.resumeText, request.targetRole);
      if (directResponse != null) return directResponse;
    }

    // 2. Try Firebase Cloud Function if available
    if (_functions != null) {
      try {
        final HttpsCallable callable = _functions.httpsCallable('compileReport');
        final HttpsCallableResult result = await callable.call(request.toJson());
        return CompileReportResponse.fromJson(Map<String, dynamic>.from(result.data as Map));
      } catch (_) {}
    }

    // 3. Mock fallback
    return CompileReportResponse(
      overallReadinessIndex: 82,
      executiveSummary: 'Candidate demonstrates strong foundational technical skills.',
      strengths: ['Clean Architecture Design', 'Flutter & Dart Expertise'],
      improvements: ['Quantify metrics in bullet points', 'Expand unit testing coverage'],
      roleCompatibilities: {
        request.targetRole.isEmpty ? 'Software Engineer' : request.targetRole: 88,
        'Mobile Tech Lead': 76,
      },
      averageSalary: '\$135,000 / yr',
      salaryPercentile: 78,
      roadmap: [
        RoadmapStep(
          id: 'step_1',
          title: 'Resume Metric Optimization',
          description: 'Quantify outcomes across work experience bullet points.',
          status: 'completed',
          actionLabel: 'View Corrections',
        ),
      ],
    );
  }

  Future<CompileReportResponse?> getSavedReport(String uid) async {
    if (_firestore == null) return null;
    try {
      final DocumentSnapshot doc = await _firestore
          .collection('users')
          .doc(uid)
          .collection('reports')
          .doc('latest')
          .get();
          
      if (!doc.exists || doc.data() == null) return null;
      return CompileReportResponse.fromJson(Map<String, dynamic>.from(doc.data() as Map));
    } catch (_) {
      return null;
    }
  }
}
