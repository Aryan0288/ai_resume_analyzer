import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../../features/resume/data/models/analyze_resume_response.dart';
import '../../features/interview/data/models/generate_questions_response.dart';
import '../../features/interview/data/models/evaluate_answer_response.dart';
import '../../features/quiz/data/models/generate_quiz_response.dart';
import '../../features/report/data/models/compile_report_response.dart';

/// Direct Client-Side Gemini AI Service.
/// Enables 100% live Gemini AI functionality directly in Flutter without requiring Cloud Functions deployment.
class GeminiService {
  static String apiKey = '';

  static List<String> get apiKeysList {
    const envKeys = String.fromEnvironment('GEMINI_API_KEYS', defaultValue: '');
    const singleEnvKey = String.fromEnvironment('GEMINI_API_KEY', defaultValue: '');

    final rawString = envKeys.isNotEmpty
        ? envKeys
        : (singleEnvKey.isNotEmpty ? singleEnvKey : apiKey);

    final List<String> result = [];
    if (rawString.contains(',') || rawString.contains(';')) {
      result.addAll(rawString.split(RegExp(r'[,;]')).map((k) => k.trim()));
    } else {
      result.add(rawString.trim());
    }

    return result
        .where((k) => k.isNotEmpty && !k.startsWith('YOUR_GEMINI_API_KEY'))
        .toList();
  }

  static bool get isApiKeyConfigured => apiKeysList.isNotEmpty;

  /// 1. Analyze Resume with Gemini AI
  static Future<AnalyzeResumeResponse?> analyzeResume(
      String resumeText, String targetRole) async {
    if (!isApiKeyConfigured) return null;

    final prompt = '''
You are an expert ATS Resume Coach and Senior Technical Recruiter.
Evaluate the following resume for the target role: "${targetRole.isEmpty ? "Software Engineer" : targetRole}".

Return ONLY valid JSON matching this exact structure:
{
  "healthScore": 85,
  "atsScore": 88,
  "contentScore": 82,
  "formattingScore": 90,
  "grammarScore": 95,
  "recommendedSkills": ["GraphQL", "CI/CD Pipelines", "Unit Testing", "Docker"],
  "detectedSkills": ["Flutter", "Dart", "REST APIs", "Firebase"],
  "critiques": [
    {
      "id": "crit_1",
      "type": "weakness",
      "title": "Missing Quantifiable Metrics",
      "description": "Your bullet points describe tasks without metric outcomes.",
      "beforeText": "Original weak bullet text",
      "afterText": "Improved metric-driven bullet text"
    }
  ]
}

Resume Text:
"""
$resumeText
"""
''';

    try {
      final json = await _callGeminiApi(prompt);
      if (json == null) return null;
      return AnalyzeResumeResponse.fromJson(json);
    } catch (e) {
      debugPrint('[GeminiService] analyzeResume error: $e');
      return null;
    }
  }

  /// 2. Generate Multi-Category Interview Questions with Gemini AI
  static Future<GenerateQuestionsResponse?> generateQuestions(
      String resumeText, String category) async {
    if (!isApiKeyConfigured) return null;

    final prompt = '''
You are a Friendly Technical Interview Mentor.
Analyze this candidate's resume text:
"""
$resumeText
"""

Generate 25 clear, progressive, beginner-to-intermediate level interview questions tailored directly to the candidate's target role and listed skills.

IMPORTANT INSTRUCTIONS:
1. Start with core fundamental questions for their niche target role (for example, if they target Flutter Developer, start with "What is Flutter and how does it differ from React Native?", "What is the difference between Stateless and Stateful Widgets?").
2. Use simple, conversational, easy-to-understand English (avoid overly complex or academic jargon).
3. Include questions for ONLY these 2 exact categories (approx 12-13 in each):
   - "Common Questions" (core fundamentals, basic concepts, and standard interview questions for their role)
   - "Resume-Based" (questions specific to their listed projects, real-world experience, tools, and accomplishments)

CRITICAL: For every question, write a simple, easy-to-understand, complete answer in the "savedAnswer" field, AND ALWAYS INCLUDE A PRACTICAL REAL-WORLD PROJECT EXAMPLE in the answer (e.g. "Example: In an e-commerce shopping app, a Stateful Widget is used for the shopping cart counter...").

Return ONLY valid JSON matching this exact structure:
{
  "questions": [
    {
      "id": "q_1",
      "category": "Common Questions",
      "difficulty": "Easy",
      "text": "What is Flutter and how does it differ from React Native?",
      "estimatedMinutes": 5,
      "savedAnswer": "Flutter is Google's open-source UI toolkit for building natively compiled applications from a single codebase using Dart. React Native uses a JavaScript bridge to communicate with native components, whereas Flutter renders everything directly onto a canvas using Skia/Impeller. Example: In a banking app built with Flutter, UI components render identically across iOS and Android with smooth 60 FPS performance without relying on platform-specific UI bridges.",
      "isCompleted": false,
      "aiEvaluation": ""
    }
  ]
}
''';

    try {
      final json = await _callGeminiApi(prompt);
      if (json == null) return null;
      return GenerateQuestionsResponse.fromJson(json);
    } catch (e) {
      debugPrint('[GeminiService] generateQuestions error: $e');
      return null;
    }
  }

  /// 3. Evaluate Interview Answer with Gemini AI
  static Future<EvaluateAnswerResponse?> evaluateAnswer(
      String questionText, String answerText) async {
    if (!isApiKeyConfigured) return null;

    final prompt = '''
You are a Senior Bar Raiser Interviewer. Evaluate this candidate response:
Question: "$questionText"
User Answer: "$answerText"

Return ONLY valid JSON matching this exact structure:
{
  "feedback": "Detailed AI Coach feedback evaluating STAR format, technical depth, and actionable advice.",
  "overallScore": 8,
  "sampleAnswer": "High-scoring example STAR answer for this question...",
  "subMetrics": {
    "Technical Accuracy": 9,
    "STAR Format": 8,
    "Clarity": 8
  }
}
''';

    try {
      final json = await _callGeminiApi(prompt);
      if (json == null) return null;
      return EvaluateAnswerResponse.fromJson(json);
    } catch (e) {
      debugPrint('[GeminiService] evaluateAnswer error: $e');
      return null;
    }
  }

  /// 4. Generate Skill Quiz MCQs with Gemini AI
  static Future<GenerateQuizResponse?> generateQuiz(List<String> skills, [String resumeText = '']) async {
    if (!isApiKeyConfigured) return null;

    final prompt = '''
You are an expert Technical Assessment Author.
Generate 20 high-quality, practical multiple-choice skill assessment questions based on these candidate skills: ${jsonEncode(skills)} and resume context:
"""
$resumeText
"""

Return ONLY valid JSON matching this exact structure:
{
  "questions": [
    {
      "id": "qz_1",
      "text": "Question text testing practical engineering concept?",
      "options": ["Option A", "Option B", "Option C", "Option D"],
      "correctOptionIndex": 0,
      "difficulty": "Medium",
      "estimatedSeconds": 45,
      "coachExplanation": "Detailed explanation of why Option A is correct and why other options fail."
    }
  ]
}
''';

    try {
      final json = await _callGeminiApi(prompt);
      if (json == null) return null;
      return GenerateQuizResponse.fromJson(json);
    } catch (e) {
      debugPrint('[GeminiService] generateQuiz error: $e');
      return null;
    }
  }

  /// 5. Compile Career Report & Roadmap with Gemini AI
  static Future<CompileReportResponse?> compileReport(
      String resumeText, String targetRole) async {
    if (!isApiKeyConfigured) return null;

    final prompt = '''
You are a Principal Technical Career Strategist.
Evaluate this candidate's resume for the target role: "${targetRole.isEmpty ? "Software Engineer" : targetRole}".
Resume Text:
"""
$resumeText
"""

Return ONLY valid JSON matching this exact structure:
{
  "overallReadinessIndex": 82,
  "executiveSummary": "Detailed multi-paragraph executive summary evaluating candidate's readiness, key gaps, and growth path.",
  "strengths": ["Specific candidate strength 1", "Specific candidate strength 2", "Specific candidate strength 3"],
  "improvements": ["Specific area for improvement 1", "Specific area for improvement 2", "Specific area for improvement 3"],
  "roleCompatibilities": {
    "${targetRole.isEmpty ? "Software Engineer" : targetRole}": 88,
    "Tech Lead": 74,
    "Senior Engineer": 82
  },
  "averageSalary": "\$135,000 / yr",
  "salaryPercentile": 78,
  "roadmap": [
    {
      "id": "step_1",
      "title": "Resume Metric Optimization",
      "description": "Quantify outcomes across work experience bullet points.",
      "status": "completed",
      "actionLabel": "View Corrections"
    },
    {
      "id": "step_2",
      "title": "Technical Skill Assessment",
      "description": "Complete skill quiz on core architecture requirements.",
      "status": "unlocked",
      "actionLabel": "Take Quiz"
    },
    {
      "id": "step_3",
      "title": "Behavioral STAR Practice",
      "description": "Practice STAR questions for high-impact project delivery.",
      "status": "unlocked",
      "actionLabel": "Start Practice"
    }
  ]
}
''';

    try {
      final json = await _callGeminiApi(prompt);
      if (json == null) return null;
      return CompileReportResponse.fromJson(json);
    } catch (e) {
      debugPrint('[GeminiService] compileReport error: $e');
      return null;
    }
  }

  static List<String> get apiKeysList {
    final rawList = [apiKey];
    final List<String> result = [];
    for (final item in rawList) {
      if (item.contains(',') || item.contains(';')) {
        result.addAll(item.split(RegExp(r'[,;]')).map((k) => k.trim()));
      } else {
        result.add(item.trim());
      }
    }
    return result
        .where((k) => k.isNotEmpty && !k.startsWith('YOUR_GEMINI_API_KEY'))
        .toList();
  }

  static const List<String> _models = [
    'gemini-flash-latest',
    'gemini-1.5-flash',
    'gemini-2.0-flash',
    'gemini-1.5-pro',
    'gemini-2.5-flash',
  ];

  /// Helper to post prompt payload to Gemini REST API and return parsed JSON.
  /// Uses X-goog-api-key header, key pool rotation, and retry backoff on 429 rate limit.
  static Future<Map<String, dynamic>?> _callGeminiApi(String prompt) async {
    final keys = apiKeysList;
    if (keys.isEmpty) {
      debugPrint('[GeminiService] No valid Gemini API Key configured.');
      return null;
    }

    for (final model in _models) {
      for (final currentKey in keys) {
        final keyPrefix = currentKey.length > 8 ? currentKey.substring(0, 8) : currentKey;
        final url = Uri.parse(
            'https://generativelanguage.googleapis.com/v1beta/models/$model:generateContent');

        for (int attempt = 0; attempt < 2; attempt++) {
          try {
            final response = await http.post(
              url,
              headers: {
                'Content-Type': 'application/json',
                'X-goog-api-key': currentKey,
              },
              body: jsonEncode({
                'contents': [
                  {
                    'parts': [
                      {'text': prompt}
                    ]
                  }
                ],
                'generationConfig': {
                  'responseMimeType': 'application/json',
                  'temperature': 0.7,
                }
              }),
            );

            if (response.statusCode == 200) {
              final body = jsonDecode(response.body) as Map<String, dynamic>;
              final candidates = body['candidates'] as List?;
              if (candidates != null && candidates.isNotEmpty) {
                final parts = candidates.first['content']?['parts'] as List?;
                if (parts != null && parts.isNotEmpty) {
                  String rawText = parts.first['text'] as String? ?? '';
                  // Clean markdown code blocks if returned
                  rawText = rawText
                      .replaceAll(RegExp(r'^```(json)?\s*', caseSensitive: false), '')
                      .replaceAll(RegExp(r'\s*```$'), '')
                      .trim();
                  if (rawText.isNotEmpty) {
                    debugPrint('[GeminiService] Success via model: $model (Key: $keyPrefix...)');
                    return jsonDecode(rawText) as Map<String, dynamic>;
                  }
                }
              }
            } else if (response.statusCode == 429) {
              debugPrint('[GeminiService] Rate limit (429) on $model (Key: $keyPrefix...). Rotating to next key in pool...');
              break; // Try next API key in pool
            } else if (response.statusCode == 403) {
              debugPrint('[GeminiService] Key revoked or quota limit reached (403) on $model (Key: $keyPrefix...). Rotating to next key in pool...');
              break; // Try next API key in pool
            } else {
              debugPrint('[GeminiService] Model $model returned status ${response.statusCode}: ${response.body}. Trying next key/model...');
              break; // Try next key or model
            }
          } catch (e) {
            debugPrint('[GeminiService] Error calling model $model (Key: $keyPrefix...): $e. Trying next...');
            break;
          }
        }
      }
    }
    debugPrint('[GeminiService] All API keys and fallback models exhausted.');
    return null;
  }
}

