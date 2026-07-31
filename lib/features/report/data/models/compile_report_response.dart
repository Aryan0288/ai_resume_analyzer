import '../../domain/roadmap_step.dart';

class CompileReportResponse {
  final int overallReadinessIndex;
  final String executiveSummary;
  final List<String> strengths;
  final List<String> improvements;
  final Map<String, double> roleCompatibilities;
  final String averageSalary;
  final int salaryPercentile;
  final List<RoadmapStep> roadmap;

  CompileReportResponse({
    required this.overallReadinessIndex,
    required this.executiveSummary,
    required this.strengths,
    required this.improvements,
    required this.roleCompatibilities,
    required this.averageSalary,
    required this.salaryPercentile,
    required this.roadmap,
  });

  factory CompileReportResponse.fromJson(Map<String, dynamic> json) {
    final roadmapList = (json['roadmap'] as List? ?? [])
        .map((item) => RoadmapStep.fromJson(Map<String, dynamic>.from(item as Map)))
        .toList();
    return CompileReportResponse(
      overallReadinessIndex: (json['overallReadinessIndex'] ?? 0) as int,
      executiveSummary: (json['executiveSummary'] ?? '') as String,
      strengths: List<String>.from(json['strengths'] ?? []),
      improvements: List<String>.from(json['improvements'] ?? []),
      roleCompatibilities: Map<String, double>.from(json['roleCompatibilities'] ?? {}),
      averageSalary: (json['averageSalary'] ?? '') as String,
      salaryPercentile: (json['salaryPercentile'] ?? 0) as int,
      roadmap: roadmapList,
    );
  }

  Map<String, dynamic> toJson() => {
    'overallReadinessIndex': overallReadinessIndex,
    'executiveSummary': executiveSummary,
    'strengths': strengths,
    'improvements': improvements,
    'roleCompatibilities': roleCompatibilities,
    'averageSalary': averageSalary,
    'salaryPercentile': salaryPercentile,
    'roadmap': roadmap.map((s) => s.toJson()).toList(),
  };
}
