class AnalysisHistory {
  final int? id;
  final double attractivenessScore;
  final String bestAngle;
  final String bestAngleDescription;
  final String overallAnalysis;
  final String imageBase64;
  final String facialFeaturesJson;
  final String medicalCondition;
  final String medicalSeverity;
  final String medicalDescription;
  final String medicalRecommendationsJson;
  final String medicalTreatmentsJson;
  final DateTime createdAt;

  AnalysisHistory({
    this.id,
    required this.attractivenessScore,
    required this.bestAngle,
    required this.bestAngleDescription,
    required this.overallAnalysis,
    required this.imageBase64,
    required this.facialFeaturesJson,
    required this.medicalCondition,
    required this.medicalSeverity,
    required this.medicalDescription,
    required this.medicalRecommendationsJson,
    required this.medicalTreatmentsJson,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'attractivenessScore': attractivenessScore,
      'bestAngle': bestAngle,
      'bestAngleDescription': bestAngleDescription,
      'overallAnalysis': overallAnalysis,
      'imageBase64': imageBase64,
      'facialFeaturesJson': facialFeaturesJson,
      'medicalCondition': medicalCondition,
      'medicalSeverity': medicalSeverity,
      'medicalDescription': medicalDescription,
      'medicalRecommendationsJson': medicalRecommendationsJson,
      'medicalTreatmentsJson': medicalTreatmentsJson,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory AnalysisHistory.fromMap(Map<String, dynamic> map) {
    return AnalysisHistory(
      id: map['id'] as int?,
      attractivenessScore: (map['attractivenessScore'] as num).toDouble(),
      bestAngle: map['bestAngle'] as String,
      bestAngleDescription: map['bestAngleDescription'] as String,
      overallAnalysis: map['overallAnalysis'] as String,
      imageBase64: map['imageBase64'] as String,
      facialFeaturesJson: map['facialFeaturesJson'] as String,
      medicalCondition: map['medicalCondition'] as String,
      medicalSeverity: map['medicalSeverity'] as String,
      medicalDescription: map['medicalDescription'] as String,
      medicalRecommendationsJson: map['medicalRecommendationsJson'] as String,
      medicalTreatmentsJson: map['medicalTreatmentsJson'] as String,
      createdAt: DateTime.parse(map['createdAt'] as String),
    );
  }
}

