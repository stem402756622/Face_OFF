class StyleSuggestions {
  final List<String> hairstyles;
  final List<String> skincareRoutine;
  final List<String> makeupTechniques;
  final List<String> groomingHabits;
  final String faceShape;
  final String overallRecommendation;

  StyleSuggestions({
    required this.hairstyles,
    required this.skincareRoutine,
    required this.makeupTechniques,
    required this.groomingHabits,
    required this.faceShape,
    required this.overallRecommendation,
  });

  factory StyleSuggestions.fromJson(Map<String, dynamic> json) {
    return StyleSuggestions(
      hairstyles: List<String>.from(json['hairstyles'] as List? ?? []),
      skincareRoutine: List<String>.from(json['skincareRoutine'] as List? ?? []),
      makeupTechniques: List<String>.from(json['makeupTechniques'] as List? ?? []),
      groomingHabits: List<String>.from(json['groomingHabits'] as List? ?? []),
      faceShape: json['faceShape'] as String? ?? 'Oval',
      overallRecommendation: json['overallRecommendation'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'hairstyles': hairstyles,
      'skincareRoutine': skincareRoutine,
      'makeupTechniques': makeupTechniques,
      'groomingHabits': groomingHabits,
      'faceShape': faceShape,
      'overallRecommendation': overallRecommendation,
    };
  }
}

