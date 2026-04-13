class MedicalSolution {
  final String condition;
  final String description;
  final List<String> recommendations;
  final String severity;
  final List<String> treatments;

  MedicalSolution({
    required this.condition,
    required this.description,
    required this.recommendations,
    required this.severity,
    required this.treatments,
  });

  factory MedicalSolution.fromJson(Map<String, dynamic> json) {
    return MedicalSolution(
      condition: json['condition'] as String? ?? 'No significant issues detected',
      description: json['description'] as String? ?? '',
      recommendations: List<String>.from(json['recommendations'] as List? ?? []),
      severity: json['severity'] as String? ?? 'Low',
      treatments: List<String>.from(json['treatments'] as List? ?? []),
    );
  }
}

