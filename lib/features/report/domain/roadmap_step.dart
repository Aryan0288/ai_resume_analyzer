class RoadmapStep {
  final String id;
  final String title;
  final String description;
  final String status; // 'completed', 'unlocked', 'locked'
  final String actionLabel;

  RoadmapStep({
    required this.id,
    required this.title,
    required this.description,
    required this.status,
    required this.actionLabel,
  });

  factory RoadmapStep.fromJson(Map<String, dynamic> json) {
    return RoadmapStep(
      id: (json['id'] ?? '') as String,
      title: (json['title'] ?? '') as String,
      description: (json['description'] ?? '') as String,
      status: (json['status'] ?? 'locked') as String,
      actionLabel: (json['actionLabel'] ?? 'Locked') as String,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'description': description,
    'status': status,
    'actionLabel': actionLabel,
  };
}
