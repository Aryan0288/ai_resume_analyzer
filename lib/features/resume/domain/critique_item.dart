class CritiqueItem {
  final String id;
  final String type; // 'strength', 'weakness', 'suggestion'
  final String title;
  final String description;
  final String beforeText;
  final String afterText;
  final bool isExpanded;

  CritiqueItem({
    required this.id,
    required this.type,
    required this.title,
    required this.description,
    required this.beforeText,
    required this.afterText,
    this.isExpanded = false,
  });

  CritiqueItem copyWith({
    String? id,
    String? type,
    String? title,
    String? description,
    String? beforeText,
    String? afterText,
    bool? isExpanded,
  }) {
    return CritiqueItem(
      id: id ?? this.id,
      type: type ?? this.type,
      title: title ?? this.title,
      description: description ?? this.description,
      beforeText: beforeText ?? this.beforeText,
      afterText: afterText ?? this.afterText,
      isExpanded: isExpanded ?? this.isExpanded,
    );
  }

  factory CritiqueItem.fromJson(Map<String, dynamic> json) {
    return CritiqueItem(
      id: (json['id'] ?? '') as String,
      type: (json['type'] ?? '') as String,
      title: (json['title'] ?? '') as String,
      description: (json['description'] ?? '') as String,
      beforeText: (json['beforeText'] ?? '') as String,
      afterText: (json['afterText'] ?? '') as String,
      isExpanded: false,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'type': type,
    'title': title,
    'description': description,
    'beforeText': beforeText,
    'afterText': afterText,
  };
}
