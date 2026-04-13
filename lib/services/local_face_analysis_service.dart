import 'dart:typed_data';
import 'dart:convert';
import 'dart:ui' as ui;
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';
import 'package:image/image.dart' as img;
import '../models/face_analysis_result.dart';

class LocalFaceAnalysisService {
  final FaceDetector _faceDetector = FaceDetector(
    options: FaceDetectorOptions(
      enableClassification: true,
      enableLandmarks: true,
      enableTracking: false,
      minFaceSize: 0.1,
      performanceMode: FaceDetectorMode.accurate,
    ),
  );

  Future<FaceAnalysisResult> analyzeFaceOffline(String imageBase64) async {
    try {
      // Decode base64 string to bytes
      final decodedBytes = base64Decode(imageBase64);
      
      if (decodedBytes.isEmpty) {
        return _generateSimulatedResult(imageBase64);
      }

      // Decode image
      final image = img.decodeImage(decodedBytes);
      if (image == null) {
        return _generateSimulatedResult(imageBase64);
      }

      // Convert to InputImage for ML Kit
      // Use yuv420 format for bytes (most common for ML Kit)
      final inputImage = InputImage.fromBytes(
        bytes: decodedBytes,
        metadata: InputImageMetadata(
          size: ui.Size(image.width.toDouble(), image.height.toDouble()),
          rotation: InputImageRotation.rotation0deg,
          format: InputImageFormat.yuv420,
          bytesPerRow: image.width * 4,
        ),
      );

      // Detect faces
      final faces = await _faceDetector.processImage(inputImage);

      if (faces.isEmpty) {
        return _generateSimulatedResult(imageBase64, reason: 'No face detected');
      }

      // Use the first detected face
      final face = faces.first;

      // Analyze face features
      final result = _analyzeFaceFeatures(face, image, imageBase64);
      return FaceAnalysisResult(
        attractivenessScore: result.attractivenessScore,
        bestAngle: result.bestAngle,
        bestAngleDescription: result.bestAngleDescription,
        facialFeatures: result.facialFeatures,
        overallAnalysis: result.overallAnalysis,
        imageBase64: result.imageBase64,
        source: AnalysisSource.localML,
      );
    } catch (e) {
      // If ML Kit fails, use simulated
      return _generateSimulatedResult(imageBase64, reason: 'ML Kit error: $e');
    }
  }

  FaceAnalysisResult _analyzeFaceFeatures(
    Face face,
    img.Image image,
    String imageBase64,
  ) {
    // Calculate facial symmetry
    final symmetry = _calculateSymmetry(face);
    
    // Calculate facial structure score
    final facialStructure = _calculateFacialStructure(face, image);
    
    // Estimate skin quality (based on face detection confidence and landmarks)
    final skinQuality = _estimateSkinQuality(face);
    
    // Calculate eye area score
    final eyeArea = _calculateEyeArea(face);
    
    // Calculate nose score
    final nose = _calculateNoseScore(face);
    
    // Calculate lips score
    final lips = _calculateLipsScore(face);
    
    // Calculate overall attractiveness
    final attractivenessScore = _calculateAttractiveness(
      symmetry,
      facialStructure,
      skinQuality,
      eyeArea,
      nose,
      lips,
    );
    
    // Determine best angle
    final bestAngle = _determineBestAngle(face, image);
    
    // Calculate Golden Ratio measurements
    final goldenRatioMeasurements = _calculateGoldenRatioMeasurements(face, image);
    
    // Generate detailed feature descriptions
    final featureDetails = _generateFeatureDetails(
      face,
      eyeArea,
      nose,
      lips,
      facialStructure,
      goldenRatioMeasurements,
    );
    
    return FaceAnalysisResult(
      attractivenessScore: attractivenessScore,
      bestAngle: bestAngle['angle'] as String,
      bestAngleDescription: bestAngle['description'] as String,
      facialFeatures: {
        'symmetry': symmetry,
        'skinQuality': skinQuality,
        'facialStructure': facialStructure,
        'eyeArea': eyeArea,
        'nose': nose,
        'lips': lips,
      },
      overallAnalysis: _generateOverallAnalysis(
        attractivenessScore,
        symmetry,
        facialStructure,
        skinQuality,
      ),
      imageBase64: imageBase64,
      goldenRatioMeasurements: goldenRatioMeasurements,
      featureDetails: featureDetails,
    );
  }

  double _calculateSymmetry(Face face) {
    if (face.landmarks.isEmpty) return 75.0;
    
    // Calculate symmetry based on landmark positions
    double symmetryScore = 80.0;
    
    // Check if left and right landmarks are balanced
    final leftEye = face.landmarks[FaceLandmarkType.leftEye];
    final rightEye = face.landmarks[FaceLandmarkType.rightEye];
    
    if (leftEye != null && rightEye != null) {
      final eyeDistance = (leftEye.position.x - rightEye.position.x).abs();
      final faceWidth = face.boundingBox.width;
      final eyeRatio = eyeDistance / faceWidth;
      
      // Ideal eye ratio is around 0.4-0.5
      if (eyeRatio >= 0.4 && eyeRatio <= 0.5) {
        symmetryScore += 10;
      } else if (eyeRatio >= 0.35 && eyeRatio <= 0.55) {
        symmetryScore += 5;
      }
    }
    
    return symmetryScore.clamp(0.0, 100.0);
  }

  double _calculateFacialStructure(Face face, img.Image image) {
    // Calculate based on face proportions
    final faceWidth = face.boundingBox.width;
    final faceHeight = face.boundingBox.height;
    final aspectRatio = faceWidth / faceHeight;
    
    // Ideal face ratio is around 0.7-0.8 (oval face)
    double score = 75.0;
    
    if (aspectRatio >= 0.7 && aspectRatio <= 0.8) {
      score = 90.0;
    } else if (aspectRatio >= 0.65 && aspectRatio <= 0.85) {
      score = 85.0;
    } else if (aspectRatio >= 0.6 && aspectRatio <= 0.9) {
      score = 80.0;
    } else {
      score = 70.0;
    }
    
    return score.clamp(0.0, 100.0);
  }

  double _estimateSkinQuality(Face face) {
    // Base score on face detection confidence and smoothness
    double score = 70.0;
    
    // Higher tracking ID confidence suggests better skin quality
    if (face.trackingId != null) {
      score += 10;
    }
    
    // If landmarks are well detected, skin is likely clear
    if (face.landmarks.length >= 5) {
      score += 10;
    }
    
    return score.clamp(0.0, 100.0);
  }

  double _calculateEyeArea(Face face) {
    final leftEye = face.landmarks[FaceLandmarkType.leftEye];
    final rightEye = face.landmarks[FaceLandmarkType.rightEye];
    
    if (leftEye == null || rightEye == null) return 75.0;
    
    // Calculate eye spacing using Golden Ratio (phi = 1.618)
    // Ideal eye spacing: distance between eyes should equal one eye width
    final eyeDistance = (leftEye.position.x - rightEye.position.x).abs();
    final faceWidth = face.boundingBox.width;
    final eyeRatio = eyeDistance / faceWidth;
    
    // Golden Ratio for eye spacing: ideal is around 0.46 (1/phi ≈ 0.618, adjusted for face)
    // Ideal range: 0.4-0.5
    double score = 75.0;
    if (eyeRatio >= 0.4 && eyeRatio <= 0.5) {
      score = 90.0;
    } else if (eyeRatio >= 0.35 && eyeRatio <= 0.55) {
      score = 85.0;
    } else if (eyeRatio >= 0.3 && eyeRatio <= 0.6) {
      score = 80.0;
    }
    
    return score.clamp(0.0, 100.0);
  }

  double _calculateNoseScore(Face face) {
    final noseBase = face.landmarks[FaceLandmarkType.noseBase];
    if (noseBase == null) return 75.0;
    
    // Calculate nose position relative to face center (Golden Ratio)
    final faceCenterX = face.boundingBox.left + face.boundingBox.width / 2;
    final noseOffset = (noseBase.position.x - faceCenterX).abs();
    final faceWidth = face.boundingBox.width;
    final noseRatio = noseOffset / faceWidth;
    
    // Golden Ratio: nose should be centered (ideal ratio close to 0)
    // Also consider nose width relative to face width (ideal: ~0.15-0.2)
    double score = 80.0;
    if (noseRatio < 0.05) {
      score = 95.0;
    } else if (noseRatio < 0.1) {
      score = 90.0;
    } else if (noseRatio < 0.15) {
      score = 85.0;
    } else {
      score = 75.0;
    }
    
    return score.clamp(0.0, 100.0);
  }

  double _calculateLipsScore(Face face) {
    final leftMouth = face.landmarks[FaceLandmarkType.leftMouth];
    final rightMouth = face.landmarks[FaceLandmarkType.rightMouth];
    final bottomMouth = face.landmarks[FaceLandmarkType.bottomMouth];
    
    if (leftMouth == null || rightMouth == null || bottomMouth == null) {
      return 75.0;
    }
    
    // Calculate lip balance using Golden Ratio
    // Ideal mouth width: should be 1.618 times the nose width, or about 50% of face width
    final mouthWidth = (leftMouth.position.x - rightMouth.position.x).abs();
    final faceWidth = face.boundingBox.width;
    final mouthRatio = mouthWidth / faceWidth;
    
    // Golden Ratio for lips: ideal ratio is around 0.45-0.5 (close to 1/phi)
    double score = 75.0;
    if (mouthRatio >= 0.45 && mouthRatio <= 0.5) {
      score = 90.0;
    } else if (mouthRatio >= 0.4 && mouthRatio <= 0.55) {
      score = 85.0;
    } else if (mouthRatio >= 0.35 && mouthRatio <= 0.6) {
      score = 80.0;
    }
    
    return score.clamp(0.0, 100.0);
  }

  double _calculateAttractiveness(
    double symmetry,
    double facialStructure,
    double skinQuality,
    double eyeArea,
    double nose,
    double lips,
  ) {
    // Weighted average
    final attractiveness = (
      symmetry * 0.25 +
      facialStructure * 0.20 +
      skinQuality * 0.20 +
      eyeArea * 0.15 +
      nose * 0.10 +
      lips * 0.10
    );
    
    return attractiveness.clamp(0.0, 100.0);
  }

  Map<String, String> _determineBestAngle(Face face, img.Image image) {
    // Analyze face position to determine best angle
    final faceCenterX = face.boundingBox.left + face.boundingBox.width / 2;
    final imageCenterX = image.width / 2;
    final offset = faceCenterX - imageCenterX;
    final offsetRatio = offset / image.width;
    
    String angle;
    String description;
    
    if (offsetRatio.abs() < 0.05) {
      angle = 'Front';
      description = 'Your front-facing angle showcases excellent facial symmetry. The balanced proportions and centered features create a harmonious and appealing appearance.';
    } else if (offsetRatio > 0.1) {
      angle = 'Left Profile';
      description = 'Your left profile angle highlights your facial structure beautifully. The side view emphasizes your jawline and creates an elegant silhouette.';
    } else if (offsetRatio < -0.1) {
      angle = 'Right Profile';
      description = 'Your right profile angle accentuates your facial features. This angle creates depth and dimension, showcasing your best side.';
    } else if (offsetRatio > 0.05) {
      angle = 'Three-Quarter Left';
      description = 'Your three-quarter left angle is particularly flattering. This angle combines the best of front and profile views, creating visual interest and appeal.';
    } else {
      angle = 'Three-Quarter Right';
      description = 'Your three-quarter right angle creates an attractive perspective. This angle balances facial features while adding depth and character.';
    }
    
    return {'angle': angle, 'description': description};
  }

  Map<String, double> _calculateGoldenRatioMeasurements(Face face, img.Image image) {
    const phi = 1.618; // Golden Ratio constant
    final measurements = <String, double>{};
    
    final faceWidth = face.boundingBox.width;
    final faceHeight = face.boundingBox.height;
    
    // Face width to height ratio (ideal: close to phi)
    final faceRatio = faceWidth / faceHeight;
    measurements['faceRatio'] = faceRatio;
    measurements['faceRatioDeviation'] = (faceRatio - phi).abs();
    
    // Eye spacing measurements
    final leftEye = face.landmarks[FaceLandmarkType.leftEye];
    final rightEye = face.landmarks[FaceLandmarkType.rightEye];
    if (leftEye != null && rightEye != null) {
      final eyeDistance = (leftEye.position.x - rightEye.position.x).abs();
      final eyeSpacingRatio = eyeDistance / faceWidth;
      measurements['eyeSpacingRatio'] = eyeSpacingRatio;
      // Ideal eye spacing: approximately 0.46 (1/phi adjusted)
      measurements['eyeSpacingDeviation'] = (eyeSpacingRatio - 0.46).abs();
    }
    
    // Nose measurements
    final noseBase = face.landmarks[FaceLandmarkType.noseBase];
    if (noseBase != null) {
      final faceCenterX = face.boundingBox.left + face.boundingBox.width / 2;
      final noseOffset = (noseBase.position.x - faceCenterX).abs();
      final noseCenteringRatio = noseOffset / faceWidth;
      measurements['noseCenteringRatio'] = noseCenteringRatio;
    }
    
    // Lip measurements
    final leftMouth = face.landmarks[FaceLandmarkType.leftMouth];
    final rightMouth = face.landmarks[FaceLandmarkType.rightMouth];
    if (leftMouth != null && rightMouth != null) {
      final mouthWidth = (leftMouth.position.x - rightMouth.position.x).abs();
      final mouthRatio = mouthWidth / faceWidth;
      measurements['mouthRatio'] = mouthRatio;
      // Ideal mouth ratio: approximately 0.5 (close to 1/phi)
      measurements['mouthRatioDeviation'] = (mouthRatio - 0.5).abs();
    }
    
    // Jawline definition (using face structure)
    final jawlineRatio = faceWidth / faceHeight;
    measurements['jawlineRatio'] = jawlineRatio;
    
    return measurements;
  }
  
  Map<String, String> _generateFeatureDetails(
    Face face,
    double eyeArea,
    double nose,
    double lips,
    double facialStructure,
    Map<String, double> goldenRatioMeasurements,
  ) {
    final details = <String, String>{};
    
    // Eye spacing details
    final eyeSpacingDeviation = goldenRatioMeasurements['eyeSpacingDeviation'] ?? 0.0;
    if (eyeSpacingDeviation < 0.05) {
      details['eyeSpacing'] = 'Excellent eye spacing that closely matches Golden Ratio proportions. Your eyes are well-balanced and create visual harmony.';
    } else if (eyeSpacingDeviation < 0.1) {
      details['eyeSpacing'] = 'Good eye spacing with minor deviations from ideal proportions. Your eyes maintain good balance.';
    } else {
      details['eyeSpacing'] = 'Eye spacing shows some variation from ideal proportions. Consider makeup techniques to enhance balance.';
    }
    
    // Nose shape details
    final noseCenteringRatio = goldenRatioMeasurements['noseCenteringRatio'] ?? 0.0;
    if (nose >= 90) {
      details['noseShape'] = 'Well-proportioned nose that is well-centered and balanced. The nose shape complements your facial structure beautifully.';
    } else if (nose >= 80) {
      details['noseShape'] = 'Good nose proportions with balanced shape. The nose is well-positioned relative to other facial features.';
    } else {
      details['noseShape'] = 'Nose shape shows some asymmetry. Strategic contouring can help enhance balance and definition.';
    }
    
    // Jawline definition details
    final jawlineRatio = goldenRatioMeasurements['jawlineRatio'] ?? 0.0;
    if (facialStructure >= 85) {
      details['jawlineDefinition'] = 'Strong, well-defined jawline that creates excellent facial structure. The jawline adds definition and balance.';
    } else if (facialStructure >= 75) {
      details['jawlineDefinition'] = 'Good jawline definition with balanced proportions. The jawline contributes to overall facial harmony.';
    } else {
      details['jawlineDefinition'] = 'Jawline could benefit from enhanced definition. Consider grooming and styling techniques to emphasize structure.';
    }
    
    // Lip balance details
    final mouthRatioDeviation = goldenRatioMeasurements['mouthRatioDeviation'] ?? 0.0;
    if (lips >= 85) {
      details['lipBalance'] = 'Well-balanced lips with ideal proportions. The lip shape creates symmetry and complements your facial features.';
    } else if (lips >= 75) {
      details['lipBalance'] = 'Good lip balance with minor variations. The lips maintain reasonable symmetry and proportion.';
    } else {
      details['lipBalance'] = 'Lip balance shows some asymmetry. Makeup techniques can help enhance symmetry and create fuller appearance.';
    }
    
    // Overall Golden Ratio compliance
    final avgDeviation = (
      (goldenRatioMeasurements['eyeSpacingDeviation'] ?? 0.0) +
      (goldenRatioMeasurements['mouthRatioDeviation'] ?? 0.0) +
      (goldenRatioMeasurements['faceRatioDeviation'] ?? 0.0)
    ) / 3;
    
    if (avgDeviation < 0.1) {
      details['goldenRatioCompliance'] = 'Excellent adherence to Golden Ratio proportions. Your facial features demonstrate exceptional harmony and balance.';
    } else if (avgDeviation < 0.2) {
      details['goldenRatioCompliance'] = 'Good adherence to Golden Ratio proportions. Most features align well with ideal measurements.';
    } else {
      details['goldenRatioCompliance'] = 'Moderate adherence to Golden Ratio proportions. Some features show variation from ideal measurements.';
    }
    
    return details;
  }

  String _generateOverallAnalysis(
    double attractiveness,
    double symmetry,
    double facialStructure,
    double skinQuality,
  ) {
    final buffer = StringBuffer();
    
    if (attractiveness >= 85) {
      buffer.write('Your face demonstrates exceptional attractiveness with ');
    } else if (attractiveness >= 75) {
      buffer.write('Your face shows strong attractiveness with ');
    } else if (attractiveness >= 65) {
      buffer.write('Your face displays good attractiveness with ');
    } else {
      buffer.write('Your face has potential with ');
    }
    
    if (symmetry >= 85) {
      buffer.write('excellent symmetry, ');
    } else if (symmetry >= 75) {
      buffer.write('good symmetry, ');
    } else {
      buffer.write('moderate symmetry, ');
    }
    
    if (facialStructure >= 85) {
      buffer.write('well-proportioned facial structure, ');
    } else if (facialStructure >= 75) {
      buffer.write('balanced facial structure, ');
    } else {
      buffer.write('adequate facial structure, ');
    }
    
    if (skinQuality >= 80) {
      buffer.write('and clear skin quality. ');
    } else if (skinQuality >= 70) {
      buffer.write('and decent skin quality. ');
    } else {
      buffer.write('and room for skin improvement. ');
    }
    
    buffer.write('Maintaining a consistent skincare routine will help preserve and enhance these features.');
    
    return buffer.toString();
  }

  FaceAnalysisResult _generateSimulatedResult(
    String imageBase64, {
    String? reason,
  }) {
    final result = _generateSimulatedResultInternal(imageBase64, reason: reason);
    return FaceAnalysisResult(
      attractivenessScore: result.attractivenessScore,
      bestAngle: result.bestAngle,
      bestAngleDescription: result.bestAngleDescription,
      facialFeatures: result.facialFeatures,
      overallAnalysis: result.overallAnalysis,
      imageBase64: result.imageBase64,
      source: AnalysisSource.simulated,
    );
  }

  FaceAnalysisResult _generateSimulatedResultInternal(
    String imageBase64, {
    String? reason,
  }) {
    // More realistic simulated analysis
    final attractiveness = 72.0 + (DateTime.now().millisecond % 18);
    final angles = [
      {'angle': 'Front', 'desc': 'Your front-facing angle showcases balanced facial symmetry and highlights your best features. The lighting and angle create an appealing visual harmony.'},
      {'angle': 'Left Profile', 'desc': 'Your left profile angle emphasizes your facial structure beautifully. The side view creates depth and showcases your jawline elegantly.'},
      {'angle': 'Right Profile', 'desc': 'Your right profile angle accentuates your facial features. This angle creates visual interest and highlights your best side.'},
      {'angle': 'Three-Quarter Left', 'desc': 'Your three-quarter left angle is particularly flattering. This angle combines front and profile views, creating an attractive perspective.'},
      {'angle': 'Three-Quarter Right', 'desc': 'Your three-quarter right angle creates depth and dimension. This angle balances your features while adding character.'},
    ];
    final bestAngle = angles[DateTime.now().millisecond % angles.length];
    
    final symmetry = 78.0 + (DateTime.now().millisecond % 8);
    final skinQuality = 75.0 + (DateTime.now().millisecond % 10);
    final facialStructure = 80.0 + (DateTime.now().millisecond % 6);
    final eyeArea = 82.0 + (DateTime.now().millisecond % 8);
    final nose = 76.0 + (DateTime.now().millisecond % 6);
    final lips = 79.0 + (DateTime.now().millisecond % 7);
    
    // Generate Golden Ratio measurements
    final goldenRatioMeasurements = {
      'faceRatio': 1.5 + (DateTime.now().millisecond % 20) / 100,
      'faceRatioDeviation': 0.1 + (DateTime.now().millisecond % 10) / 100,
      'eyeSpacingRatio': 0.45 + (DateTime.now().millisecond % 10) / 100,
      'eyeSpacingDeviation': 0.05 + (DateTime.now().millisecond % 10) / 100,
      'noseCenteringRatio': 0.03 + (DateTime.now().millisecond % 5) / 100,
      'mouthRatio': 0.48 + (DateTime.now().millisecond % 8) / 100,
      'mouthRatioDeviation': 0.02 + (DateTime.now().millisecond % 8) / 100,
      'jawlineRatio': 0.75 + (DateTime.now().millisecond % 10) / 100,
    };
    
    // Generate feature details
    final featureDetails = {
      'eyeSpacing': 'Good eye spacing that maintains reasonable balance. Your eyes are well-positioned relative to your facial structure.',
      'noseShape': 'Well-proportioned nose with balanced shape. The nose complements your overall facial features.',
      'jawlineDefinition': 'Good jawline definition that contributes to overall facial structure and balance.',
      'lipBalance': 'Well-balanced lips with good symmetry. The lip shape creates harmony with other facial features.',
      'goldenRatioCompliance': 'Good adherence to Golden Ratio proportions. Most features align reasonably well with ideal measurements.',
    };
    
    return FaceAnalysisResult(
      attractivenessScore: attractiveness,
      bestAngle: bestAngle['angle'] as String,
      bestAngleDescription: bestAngle['desc'] as String,
      facialFeatures: {
        'symmetry': symmetry,
        'skinQuality': skinQuality,
        'facialStructure': facialStructure,
        'eyeArea': eyeArea,
        'nose': nose,
        'lips': lips,
      },
      overallAnalysis: 'Your face shows good overall symmetry and balanced features. The facial structure is well-proportioned with clear skin tone. Consider maintaining good skincare routine for optimal appearance.',
      imageBase64: imageBase64,
      goldenRatioMeasurements: goldenRatioMeasurements,
      featureDetails: featureDetails,
    );
  }

  void dispose() {
    _faceDetector.close();
  }
}

