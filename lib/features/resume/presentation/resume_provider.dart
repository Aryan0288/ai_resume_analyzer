import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:syncfusion_flutter_pdf/pdf.dart';
import '../domain/critique_item.dart';
import '../data/resume_repository.dart';
import '../data/models/analyze_resume_request.dart';
import '../../../core/services/pdf_parser_service.dart';
import '../../../core/services/local_storage_service.dart';

enum IngestionState { idle, parsing, analyzing, success, error }

/// State manager governing resume picking, text extraction, password decryption, and AI analysis.
class ResumeProvider extends ChangeNotifier {
  final ResumeRepository _repository;

  ResumeProvider(this._repository);

  IngestionState _state = IngestionState.idle;
  IngestionState get state => _state;

  bool _isAnalyzing = false;
  bool get isAnalyzing => _isAnalyzing;

  String _extractedText = '';
  String get extractedText => _extractedText;

  String _targetRole = '';
  String get targetRole => _targetRole;

  bool _requiresPassword = false;
  bool get requiresPassword => _requiresPassword;

  String _errorMessage = '';
  String get errorMessage => _errorMessage;

  String _selectedFileName = '';
  String get selectedFileName => _selectedFileName;

  Uint8List? _selectedFileBytes;
  Uint8List? get selectedFileBytes => _selectedFileBytes;

  // Current resume session ID (used as Firestore document key)
  String _resumeId = '';

  int _healthScore = 0;
  int get healthScore => _healthScore;

  int _atsScore = 85;
  int get atsScore => _atsScore;

  int _contentScore = 64;
  int get contentScore => _contentScore;

  int _formattingScore = 92;
  int get formattingScore => _formattingScore;

  int _grammarScore = 78;
  int get grammarScore => _grammarScore;

  List<String> _recommendedSkills = [];
  List<String> get recommendedSkills => _recommendedSkills;

  List<String> _detectedSkills = [];
  List<String> get detectedSkills => _detectedSkills;

  List<CritiqueItem> _critiques = [];
  List<CritiqueItem> get critiques => _critiques;

  /// Update active target career role
  void setTargetRole(String role) {
    if (_targetRole != role) {
      _targetRole = role;
      notifyListeners();
    }
  }

  /// Manually edit parsed text block
  void updateExtractedText(String text) {
    if (_extractedText != text) {
      _extractedText = text;
      notifyListeners();
    }
  }

  /// Loads a pre-formatted sample resume for instant 1-click testing.
  void loadSampleResume([String? role]) {
    _targetRole = role ?? (_targetRole.isEmpty ? 'Software Engineer' : _targetRole);
    _selectedFileName = 'sample_software_engineer_resume.pdf';
    _extractedText = '''
Alex Rivera
Senior Software Engineer | alex.rivera@email.com | (555) 019-2834 | San Francisco, CA

SUMMARY
Experienced Senior Software Engineer with 6+ years specializing in cross-platform mobile development, cloud architectures, and responsive web systems. Proven track record leading agile engineering teams and shipping scalable Flutter applications.

WORK EXPERIENCE
Senior Mobile Developer | TechCraft Solutions | 2021 – Present
• Spearheaded mobile development using Flutter, Dart, and Firebase for over 250,000 active users.
• Reduced app startup time by 35% through widget tree optimizations and lazy loading.
• Integrated REST APIs, GraphQL endpoints, and WebSockets for real-time data sync.

Software Engineer | DevPulse Innovations | 2018 – 2021
• Built and maintained enterprise web applications using JavaScript, HTML5, CSS3, and Node.js.
• Managed CI/CD pipelines on GitHub Actions and deployed microservices on AWS Lambda.

SKILLS
• Languages: Dart, JavaScript, TypeScript, Python, SQL
• Frameworks & Tools: Flutter, Firebase, Riverpod, Provider, Git, Docker, REST APIs
• Education: B.S. in Computer Science, State University (2018)
'''.trim();

    // Create synthetic PDF bytes so original PDF viewer renders sample resume
    try {
      final document = PdfDocument();
      final page = document.pages.add();
      final font = PdfStandardFont(PdfFontFamily.helvetica, 10);
      final layoutFormat = PdfLayoutFormat(layoutType: PdfLayoutType.paginate);
      final textElement = PdfTextElement(text: _extractedText, font: font);
      textElement.draw(page: page, bounds: Rect.fromLTWH(0, 0, page.getClientSize().width, page.getClientSize().height), format: layoutFormat);
      _selectedFileBytes = Uint8List.fromList(document.saveSync());
      document.dispose();
    } catch (_) {}

    _resumeId = DateTime.now().millisecondsSinceEpoch.toString();
    _state = IngestionState.success;
    _errorMessage = '';
    notifyListeners();
  }

  /// Triggers file picker dialog and initializes parsing pipelines.
  Future<void> pickAndParseFile(PdfParserService pdfParser) async {
    _state = IngestionState.parsing;
    _requiresPassword = false;
    _errorMessage = '';
    notifyListeners();

    // await Future.delayed(const Duration(seconds: 5));

    try {
      final FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf'],
        withData: true,
      );

      if (result == null || result.files.isEmpty) {
        _state = IngestionState.idle;
        notifyListeners();
        return;
      }

      final file = result.files.first;
      _selectedFileName = file.name;
      _selectedFileBytes = file.bytes;

      if (_selectedFileBytes == null) {
        _state = IngestionState.error;
        _errorMessage = 'Could not load file bytes.';
        notifyListeners();
        return;
      }

      _extractedText = await pdfParser.extractText(_selectedFileBytes!);
      _resumeId = DateTime.now().millisecondsSinceEpoch.toString();

      _state = IngestionState.success;
      notifyListeners();
    } on PdfPasswordException catch (_) {
      _requiresPassword = true;
      _state = IngestionState.idle;
      notifyListeners();
    } catch (e) {
      _state = IngestionState.error;
      _errorMessage = 'Parsing failed: ${e.toString()}';
      notifyListeners();
    }
  }

  /// Decrypts the cached file bytes with the user-provided password.
  Future<void> submitPassword(PdfParserService pdfParser, String password) async {
    if (_selectedFileBytes == null) return;

    _state = IngestionState.parsing;
    _requiresPassword = false;
    _errorMessage = '';
    notifyListeners();

    try {
      _extractedText = await pdfParser.extractText(_selectedFileBytes!, password: password);
      _resumeId = DateTime.now().millisecondsSinceEpoch.toString();
      _state = IngestionState.success;
      notifyListeners();
    } on PdfPasswordException catch (_) {
      _requiresPassword = true;
      _state = IngestionState.idle;
      _errorMessage = 'Incorrect decryption password. Try again.';
      notifyListeners();
    } catch (e) {
      _state = IngestionState.error;
      _errorMessage = 'Decryption failed: ${e.toString()}';
      notifyListeners();
    }
  }

  /// Caches text locally, saves to Firestore, triggers AI analysis via Cloud Function.
  Future<void> verifyAndProceed(
    LocalStorageService storage,
    String uid,
    VoidCallback onSuccess,
  ) async {
    if (_extractedText.trim().isEmpty) {
      _errorMessage = 'Extracted text is empty. Verify content before proceeding.';
      notifyListeners();
      return;
    }

    _state = IngestionState.analyzing;
    _isAnalyzing = true;
    _errorMessage = '';
    notifyListeners();

    try {
      // 1. Cache locally
      await storage.saveResumeText(_extractedText);
      await storage.saveTargetRole(_targetRole);

      // 2. Trigger AI analysis
      final response = await _repository.analyzeResume(
        uid,
        _resumeId,
        AnalyzeResumeRequest(resumeText: _extractedText, targetRole: _targetRole),
      );
      _healthScore = response.healthScore;
      _atsScore = response.atsScore;
      _contentScore = response.contentScore;
      _formattingScore = response.formattingScore;
      _grammarScore = response.grammarScore;
      _recommendedSkills = response.recommendedSkills;
      _detectedSkills = response.detectedSkills;
      _critiques = response.critiques;

      _isAnalyzing = false;
      _state = IngestionState.success;

      // Save activity and score trend to user UID in Firestore and local storage
      try {
        final activityItem = {
          'id': _resumeId.isNotEmpty ? _resumeId : DateTime.now().millisecondsSinceEpoch.toString(),
          'documentName': _selectedFileName.isNotEmpty ? _selectedFileName : 'Uploaded_Resume.pdf',
          'targetRole': _targetRole.isNotEmpty ? _targetRole : 'Target Position Not Set',
          'atsScore': _atsScore,
          'date': DateTime.now().toIso8601String(),
        };
        await storage.addRecentActivity(uid, activityItem);

        final trendItem = {
          'label': 'Run ${storage.getRecentActivities(uid).length}',
          'score': _atsScore,
        };
        await storage.addScoreTrend(uid, trendItem);
      } catch (e) {
        debugPrint('[ResumeProvider] Save user activity error: $e');
      }

      notifyListeners();
      onSuccess();
    } catch (e) {
      _isAnalyzing = false;
      _state = IngestionState.error;
      _errorMessage = 'Resume analysis failed. Please verify your resume text and try again.';
      notifyListeners();
    }
  }

  /// Toggle accordion expansions
  void toggleCritiqueExpansion(String id) {
    final index = _critiques.indexWhere((c) => c.id == id);
    if (index != -1) {
      _critiques[index] = _critiques[index].copyWith(
        isExpanded: !_critiques[index].isExpanded,
      );
      notifyListeners();
    }
  }

  /// Reset ingestion state to select another file
  void reset() {
    _state = IngestionState.idle;
    _extractedText = '';
    _selectedFileName = '';
    _selectedFileBytes = null;
    _requiresPassword = false;
    _errorMessage = '';
    _healthScore = 0;
    _critiques = [];
    _isAnalyzing = false;
    _resumeId = '';
    notifyListeners();
  }
}
