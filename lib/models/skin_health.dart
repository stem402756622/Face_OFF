enum SkinHealthLevel {
  low,
  moderate,
  healthy,
}

class SkinHealth {
  final SkinHealthLevel level;
  final double score;
  final String assessment;
  final List<String> concerns;
  final String description;

  SkinHealth({
    required this.level,
    required this.score,
    required this.assessment,
    required this.concerns,
    required this.description,
  });

  factory SkinHealth.fromJson(Map<String, dynamic> json) {
    return SkinHealth(
      level: _parseLevel(json['level'] as String? ?? 'moderate'),
      score: (json['score'] as num?)?.toDouble() ?? 70.0,
      assessment: json['assessment'] as String? ?? '',
      concerns: List<String>.from(json['concerns'] as List? ?? []),
      description: json['description'] as String? ?? '',
    );
  }

  static SkinHealthLevel _parseLevel(String level) {
    switch (level.toLowerCase()) {
      case 'low':
        return SkinHealthLevel.low;
      case 'healthy':
        return SkinHealthLevel.healthy;
      default:
        return SkinHealthLevel.moderate;
    }
  }

  Map<String, dynamic> toJson() {
    return {
      'level': level.toString().split('.').last,
      'score': score,
      'assessment': assessment,
      'concerns': concerns,
      'description': description,
    };
  }
}

