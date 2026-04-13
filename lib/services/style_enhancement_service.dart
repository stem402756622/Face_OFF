import '../models/face_analysis_result.dart';
import '../models/style_suggestions.dart';

class StyleEnhancementService {
  StyleSuggestions generateSuggestions(FaceAnalysisResult faceAnalysis) {
    // Determine face shape based on facial features
    final faceShape = _determineFaceShape(faceAnalysis);
    
    // Generate hairstyle suggestions based on face shape
    final hairstyles = _getHairstyleSuggestions(faceShape, faceAnalysis);
    
    // Generate skincare routine based on skin quality
    final skincareRoutine = _getSkincareRoutine(faceAnalysis);
    
    // Generate makeup techniques based on facial features
    final makeupTechniques = _getMakeupTechniques(faceAnalysis);
    
    // Generate grooming habits
    final groomingHabits = _getGroomingHabits(faceAnalysis);
    
    // Overall recommendation
    final overallRecommendation = _getOverallRecommendation(
      faceAnalysis,
      faceShape,
    );
    
    return StyleSuggestions(
      hairstyles: hairstyles,
      skincareRoutine: skincareRoutine,
      makeupTechniques: makeupTechniques,
      groomingHabits: groomingHabits,
      faceShape: faceShape,
      overallRecommendation: overallRecommendation,
    );
  }
  
  String _determineFaceShape(FaceAnalysisResult faceAnalysis) {
    final facialStructure = faceAnalysis.facialFeatures['facialStructure'] ?? 75.0;
    final symmetry = faceAnalysis.facialFeatures['symmetry'] ?? 75.0;
    
    // Simplified face shape determination based on features
    if (symmetry >= 85 && facialStructure >= 85) {
      return 'Oval';
    } else if (facialStructure < 70) {
      return 'Round';
    } else if (symmetry < 70) {
      return 'Square';
    } else {
      return 'Heart';
    }
  }
  
  List<String> _getHairstyleSuggestions(String faceShape, FaceAnalysisResult faceAnalysis) {
    final suggestions = <String>[];
    
    switch (faceShape) {
      case 'Oval':
        suggestions.addAll([
          'Long layers with side-swept bangs',
          'Shoulder-length bob with soft waves',
          'Pixie cut with textured top',
          'Long, straight hair with face-framing layers',
        ]);
        break;
      case 'Round':
        suggestions.addAll([
          'Long layers that extend below the chin',
          'Side-parted hairstyle with volume at the crown',
          'Angled bob that\'s longer in the front',
          'Layered cut with height at the top',
        ]);
        break;
      case 'Square':
        suggestions.addAll([
          'Soft, wavy hairstyles to soften angles',
          'Long layers with side-swept bangs',
          'Shoulder-length cut with rounded edges',
          'Pixie cut with side-swept bangs',
        ]);
        break;
      case 'Heart':
        suggestions.addAll([
          'Chin-length bob to balance the forehead',
          'Long layers with side-swept bangs',
          'Shoulder-length cut with volume at the bottom',
          'Layered cut that adds width at the jawline',
        ]);
        break;
      default:
        suggestions.addAll([
          'Layered cut for versatility',
          'Side-swept bangs to frame the face',
          'Length that complements your features',
        ]);
    }
    
    return suggestions;
  }
  
  List<String> _getSkincareRoutine(FaceAnalysisResult faceAnalysis) {
    final skinQuality = faceAnalysis.facialFeatures['skinQuality'] ?? 75.0;
    final suggestions = <String>[];
    
    if (skinQuality >= 80) {
      suggestions.addAll([
        'Maintain current routine with gentle cleanser',
        'Use SPF 30+ sunscreen daily',
        'Apply antioxidant serum in the morning',
        'Moisturize twice daily with lightweight formula',
        'Weekly exfoliation with gentle scrub',
      ]);
    } else if (skinQuality >= 60) {
      suggestions.addAll([
        'Use gentle, pH-balanced cleanser twice daily',
        'Apply SPF 30+ sunscreen every morning',
        'Incorporate vitamin C serum for brightening',
        'Use hyaluronic acid moisturizer for hydration',
        'Exfoliate 2-3 times per week',
        'Consider retinol for evening routine',
      ]);
    } else {
      suggestions.addAll([
        'Start with gentle cleanser suitable for your skin type',
        'Daily SPF 30+ sunscreen application is essential',
        'Use niacinamide serum to improve texture',
        'Moisturize with ceramide-rich formula',
        'Exfoliate 2-3 times per week with AHA/BHA',
        'Consider professional consultation for targeted treatment',
      ]);
    }
    
    return suggestions;
  }
  
  List<String> _getMakeupTechniques(FaceAnalysisResult faceAnalysis) {
    final symmetry = faceAnalysis.facialFeatures['symmetry'] ?? 75.0;
    final eyeArea = faceAnalysis.facialFeatures['eyeArea'] ?? 75.0;
    final lips = faceAnalysis.facialFeatures['lips'] ?? 75.0;
    
    final suggestions = <String>[];
    
    // Eye enhancement
    if (eyeArea < 80) {
      suggestions.add('Use eyeliner to define and enhance eye shape');
      suggestions.add('Apply mascara to add volume and length to lashes');
      suggestions.add('Use light eyeshadow on the inner corners to brighten');
    } else {
      suggestions.add('Subtle eye makeup to enhance natural beauty');
      suggestions.add('Soft, blended eyeshadow for depth');
    }
    
    // Lip enhancement
    if (lips < 80) {
      suggestions.add('Use lip liner to define and enhance lip shape');
      suggestions.add('Apply lip gloss for added volume');
      suggestions.add('Choose colors that complement your skin tone');
    } else {
      suggestions.add('Natural lip color to enhance your features');
    }
    
    // Symmetry enhancement
    if (symmetry < 75) {
      suggestions.add('Use contouring to balance facial features');
      suggestions.add('Apply highlighter to emphasize your best features');
      suggestions.add('Blend foundation evenly for natural symmetry');
    }
    
    // General techniques
    suggestions.add('Use primer before foundation for smooth application');
    suggestions.add('Set makeup with translucent powder');
    suggestions.add('Blend all products thoroughly for natural look');
    
    return suggestions;
  }
  
  List<String> _getGroomingHabits(FaceAnalysisResult faceAnalysis) {
    final suggestions = <String>[
      'Maintain regular facial hair grooming routine',
      'Keep eyebrows well-groomed and shaped',
      'Trim nose and ear hair regularly',
      'Use quality shaving products to prevent irritation',
      'Moisturize after shaving or grooming',
      'Maintain consistent skincare routine',
      'Stay hydrated and maintain balanced diet',
      'Get adequate sleep for skin health',
      'Protect skin from sun exposure daily',
    ];
    
    return suggestions;
  }
  
  String _getOverallRecommendation(FaceAnalysisResult faceAnalysis, String faceShape) {
    final score = faceAnalysis.attractivenessScore;
    final buffer = StringBuffer();
    
    buffer.write('Based on your ${faceShape.toLowerCase()} face shape and analysis results, ');
    
    if (score >= 85) {
      buffer.write('you have excellent facial features. Focus on maintaining your current routine and subtle enhancements that highlight your natural beauty.');
    } else if (score >= 75) {
      buffer.write('you have strong facial features. Consider targeted improvements in skincare and styling to enhance your best features.');
    } else if (score >= 65) {
      buffer.write('there are several opportunities to enhance your appearance. A consistent skincare routine and strategic styling can make a significant difference.');
    } else {
      buffer.write('focus on building a comprehensive skincare routine and exploring styles that complement your unique features.');
    }
    
    return buffer.toString();
  }
}

