import '../models/face_analysis_result.dart';
import '../models/skin_health.dart';

class SkinHealthService {
  SkinHealth analyzeSkinHealth(FaceAnalysisResult faceAnalysis) {
    final skinQuality = faceAnalysis.facialFeatures['skinQuality'] ?? 75.0;
    final symmetry = faceAnalysis.facialFeatures['symmetry'] ?? 75.0;
    
    // Calculate skin health score (weighted average)
    final skinHealthScore = (skinQuality * 0.7 + symmetry * 0.3).clamp(0.0, 100.0);
    
    // Determine skin health level
    SkinHealthLevel level;
    String assessment;
    List<String> concerns = [];
    String description;
    
    if (skinHealthScore >= 80) {
      level = SkinHealthLevel.healthy;
      assessment = 'Healthy Skin';
      concerns = [];
      description = 'Your skin shows excellent health with good texture, tone, and radiance. Continue maintaining your current skincare routine for optimal results.';
    } else if (skinHealthScore >= 60) {
      level = SkinHealthLevel.moderate;
      assessment = 'Moderate Skin Health';
      
      if (skinQuality < 70) {
        concerns.add('Uneven skin tone');
      }
      if (symmetry < 70) {
        concerns.add('Texture irregularities');
      }
      if (skinHealthScore < 65) {
        concerns.add('Lack of radiance');
      }
      
      if (concerns.isEmpty) {
        concerns.add('Minor improvements possible');
      }
      
      description = 'Your skin shows moderate health with some areas for improvement. A targeted skincare routine can help enhance texture and radiance.';
    } else {
      level = SkinHealthLevel.low;
      assessment = 'Low Skin Health';
      concerns = [
        'Uneven skin tone',
        'Texture irregularities',
        'Lack of radiance',
        'Visible skin concerns',
      ];
      description = 'Your skin analysis indicates several areas that could benefit from attention. A comprehensive skincare routine and professional consultation may be beneficial.';
    }
    
    return SkinHealth(
      level: level,
      score: skinHealthScore,
      assessment: assessment,
      concerns: concerns,
      description: description,
    );
  }
}

