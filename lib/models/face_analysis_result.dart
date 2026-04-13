enum AnalysisSource {
  api,
  cached,
  localML,
  simulated,
}

class FaceAnalysisResult {
  final double attractivenessScore;
  final String bestAngle;
  final String bestAngleDescription;
  final Map<String, double> facialFeatures;
  final String overallAnalysis;
  final String imageBase64;
  final AnalysisSource source;
  // Golden Ratio measurements
  final Map<String, double> goldenRatioMeasurements;
  // Detailed feature measurements
  final Map<String, String> featureDetails;

  FaceAnalysisResult({
    required this.attractivenessScore,
    required this.bestAngle,
    required this.bestAngleDescription,
    required this.facialFeatures,
    required this.overallAnalysis,
    required this.imageBase64,
    this.source = AnalysisSource.api,
    Map<String, double>? goldenRatioMeasurements,
    Map<String, String>? featureDetails,
  })  : goldenRatioMeasurements = goldenRatioMeasurements ?? {},
        featureDetails = featureDetails ?? {};

  factory FaceAnalysisResult.fromJson(Map<String, dynamic> json) {
    return FaceAnalysisResult(
      attractivenessScore: (json['attractivenessScore'] as num?)?.toDouble() ?? 0.0,
      bestAngle: json['bestAngle'] as String? ?? 'Front',
      bestAngleDescription: json['bestAngleDescription'] as String? ?? '',
      facialFeatures: Map<String, double>.from(
        json['facialFeatures'] as Map? ?? {},
      ),
      overallAnalysis: json['overallAnalysis'] as String? ?? '',
      imageBase64: json['imageBase64'] as String? ?? '',
      source: json['source'] != null
          ? AnalysisSource.values.firstWhere(
              (e) => e.toString() == json['source'],
              orElse: () => AnalysisSource.api,
            )
          : AnalysisSource.api,
      goldenRatioMeasurements: Map<String, double>.from(
        json['goldenRatioMeasurements'] as Map? ?? {},
      ),
      featureDetails: Map<String, String>.from(
        json['featureDetails'] as Map? ?? {},
      ),
    );
  }
}

