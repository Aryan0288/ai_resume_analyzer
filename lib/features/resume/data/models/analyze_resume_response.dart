import '../../domain/critique_item.dart';

class AnalyzeResumeResponse {
  final int healthScore;
  final int atsScore;
  final int contentScore;
  final int formattingScore;
  final int grammarScore;
  final List<String> recommendedSkills;
  final List<String> detectedSkills;
  final List<CritiqueItem> critiques;

  AnalyzeResumeResponse({
    required this.healthScore,
    this.atsScore = 85,
    this.contentScore = 64,
    this.formattingScore = 92,
    this.grammarScore = 78,
    this.recommendedSkills = const [],
    this.detectedSkills = const [],
    required this.critiques,
  });

  factory AnalyzeResumeResponse.fromJson(Map<String, dynamic> json) {
    final list = (json['critiques'] as List? ?? [])
        .map((item) => CritiqueItem.fromJson(Map<String, dynamic>.from(item as Map)))
        .toList();
    return AnalyzeResumeResponse(
      healthScore: (json['healthScore'] ?? 72) as int,
      atsScore: (json['atsScore'] ?? 85) as int,
      contentScore: (json['contentScore'] ?? 64) as int,
      formattingScore: (json['formattingScore'] ?? 92) as int,
      grammarScore: (json['grammarScore'] ?? 78) as int,
      recommendedSkills: List<String>.from(json['recommendedSkills'] ?? []),
      detectedSkills: List<String>.from(json['detectedSkills'] ?? []),
      critiques: list,
    );
  }

  Map<String, dynamic> toJson() => {
    'healthScore': healthScore,
    'atsScore': atsScore,
    'contentScore': contentScore,
    'formattingScore': formattingScore,
    'grammarScore': grammarScore,
    'recommendedSkills': recommendedSkills,
    'detectedSkills': detectedSkills,
    'critiques': critiques.map((c) => c.toJson()).toList(),
  };
}
