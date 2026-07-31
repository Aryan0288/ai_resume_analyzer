import 'package:flutter/material.dart';
import '../domain/roadmap_step.dart';
import '../data/report_repository.dart';
import '../data/models/compile_report_request.dart';

class ReportProvider extends ChangeNotifier {
  final ReportRepository _repository;

  ReportProvider(this._repository);

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  int _overallReadinessIndex = 0;
  int get overallReadinessIndex => _overallReadinessIndex;

  String _executiveSummary = '';
  String get executiveSummary => _executiveSummary;

  List<String> _strengths = [];
  List<String> get strengths => _strengths;

  List<String> _improvements = [];
  List<String> get improvements => _improvements;

  Map<String, double> _roleCompatibilities = {};
  Map<String, double> get roleCompatibilities => _roleCompatibilities;

  String _averageSalary = '';
  String get averageSalary => _averageSalary;

  int _salaryPercentile = 0;
  int get salaryPercentile => _salaryPercentile;

  List<RoadmapStep> _roadmap = [];
  List<RoadmapStep> get roadmap => _roadmap;

  /// Load or compile fresh dynamic Gemini career report based on resume text.
  Future<void> loadOrCompileReport(
    String uid,
    String resumeText,
    String targetRole,
  ) async {
    if (resumeText.trim().isEmpty) return;
    _isLoading = true;
    notifyListeners();
    try {
      final response = await _repository.compileReport(
        uid,
        CompileReportRequest(resumeText: resumeText, targetRole: targetRole),
      );
      _overallReadinessIndex = response.overallReadinessIndex;
      _executiveSummary = response.executiveSummary;
      _strengths = response.strengths;
      _improvements = response.improvements;
      _roleCompatibilities = response.roleCompatibilities;
      _averageSalary = response.averageSalary;
      _salaryPercentile = response.salaryPercentile;
      if (response.roadmap.isNotEmpty) {
        _roadmap = response.roadmap;
      }
    } catch (_) {}
    _isLoading = false;
    notifyListeners();
  }

  void completeRoadmapStep(String stepId) {
    final idx = _roadmap.indexWhere((s) => s.id == stepId);
    if (idx != -1 && _roadmap[idx].status == 'unlocked') {
      _roadmap[idx] = RoadmapStep(
        id: _roadmap[idx].id,
        title: _roadmap[idx].title,
        description: _roadmap[idx].description,
        status: 'completed',
        actionLabel: 'Completed',
      );
      if (idx + 1 < _roadmap.length && _roadmap[idx + 1].status == 'locked') {
        _roadmap[idx + 1] = RoadmapStep(
          id: _roadmap[idx + 1].id,
          title: _roadmap[idx + 1].title,
          description: _roadmap[idx + 1].description,
          status: 'unlocked',
          actionLabel: 'Start Path',
        );
      }
      notifyListeners();
    }
  }
}
