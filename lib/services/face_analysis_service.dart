import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../models/face_analysis_result.dart';
import 'connectivity_service.dart';
import 'cache_service.dart';
import 'local_face_analysis_service.dart';

class FaceAnalysisService {
  static const String apiUrl = 'https://api.openai.com/v1/chat/completions';
  // API key should be set via environment variable OPENAI_API_KEY
  // For local development, you can set it in your environment or use a config file
  static String get apiKey => const String.fromEnvironment(
    'OPENAI_API_KEY',
    defaultValue: '',
  );
  
  final ConnectivityService _connectivityService = ConnectivityService.instance;
  final CacheService _cacheService = CacheService.instance;
  final LocalFaceAnalysisService _localAnalysisService = LocalFaceAnalysisService();

  Future<FaceAnalysisResult> analyzeFace(String imageBase64) async {
    // Check cache first (works offline)
    final cachedData = await _cacheService.getCachedFaceAnalysis(imageBase64);
    if (cachedData != null) {
      debugPrint('Using cached face analysis');
      final enhancedJson = <String, dynamic>{
        ...cachedData,
        'imageBase64': imageBase64,
        'source': 'AnalysisSource.cached',
        'goldenRatioMeasurements': cachedData['goldenRatioMeasurements'] ?? <String, dynamic>{},
        'featureDetails': cachedData['featureDetails'] ?? <String, dynamic>{},
      };
      return FaceAnalysisResult.fromJson(enhancedJson);
    }

    // Check connectivity
    final isConnected = await _connectivityService.isConnected();
    if (!isConnected) {
      debugPrint('Offline: Using local ML face analysis');
      // Try local ML analysis first
      try {
        final localResult = await _localAnalysisService.analyzeFaceOffline(imageBase64);
        return localResult;
      } catch (e) {
        debugPrint('Local ML failed, using simulated: $e');
        return _generateSimulatedResult(imageBase64);
      }
    }

    // Try API call
    try {
      final response = await http.post(
        Uri.parse(apiUrl),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $apiKey',
        },
        body: jsonEncode({
          'model': 'gpt-4o',
          'messages': [
            {
              'role': 'user',
              'content': [
                {
                  'type': 'text',
                  'text': '''Analyze this face image and provide a detailed facial analysis. 
                  
Return ONLY a valid JSON object with the following structure (no markdown, no code blocks, just pure JSON):
{
  "attractivenessScore": <number between 0-100>,
  "bestAngle": "<string describing the best angle: Front, Left Profile, Right Profile, Three-Quarter Left, or Three-Quarter Right>",
  "bestAngleDescription": "<detailed description of why this is the best angle, mentioning facial symmetry, features, lighting, etc.>",
  "facialFeatures": {
    "symmetry": <number 0-100>,
    "skinQuality": <number 0-100>,
    "facialStructure": <number 0-100>,
    "eyeArea": <number 0-100>,
    "nose": <number 0-100>,
    "lips": <number 0-100>
  },
  "overallAnalysis": "<comprehensive analysis of the face including symmetry, proportions, skin condition, and overall appearance>"
}

Be professional, constructive, and detailed in your analysis.'''
                },
                {
                  'type': 'image_url',
                  'image_url': {
                    'url': 'data:image/jpeg;base64,$imageBase64',
                    'detail': 'high'
                  }
                }
              ]
            }
          ],
          'max_tokens': 1500,
          'response_format': {'type': 'json_object'},
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final content = data['choices'][0]['message']['content'];
        
        // Try to parse JSON, handling potential markdown code blocks
        String jsonContent = content.trim();
        if (jsonContent.startsWith('```')) {
          // Remove markdown code blocks if present
          jsonContent = jsonContent
              .replaceFirst(RegExp(r'```json\n?'), '')
              .replaceFirst(RegExp(r'```\n?'), '')
              .trim();
        }
        
        final analysisJson = jsonDecode(jsonContent);
        
        // Cache the successful response
        await _cacheService.cacheFaceAnalysis(imageBase64, analysisJson);
        
        // Ensure Golden Ratio measurements and feature details are included
        final enhancedJson = <String, dynamic>{
          ...analysisJson,
          'imageBase64': imageBase64,
          'source': 'AnalysisSource.api',
          'goldenRatioMeasurements': analysisJson['goldenRatioMeasurements'] ?? <String, dynamic>{},
          'featureDetails': analysisJson['featureDetails'] ?? <String, dynamic>{},
        };
        
        return FaceAnalysisResult.fromJson(enhancedJson);
      } else {
        // Log error for debugging
        debugPrint('API Error: ${response.statusCode} - ${response.body}');
        
        // Check if it's a quota/rate limit error (429 or insufficient_quota)
        bool isQuotaError = false;
        if (response.statusCode == 429) {
          isQuotaError = true;
        } else {
          try {
            final errorData = jsonDecode(response.body);
            if (errorData['error'] != null) {
              final errorType = errorData['error']['type'] as String?;
              final errorCode = errorData['error']['code'] as String?;
              if (errorType == 'insufficient_quota' || 
                  errorCode == 'insufficient_quota' ||
                  errorType == 'rate_limit_exceeded' ||
                  errorCode == 'rate_limit_exceeded') {
                isQuotaError = true;
              }
            }
          } catch (e) {
            // If we can't parse the error, continue with normal error handling
          }
        }
        
        // If quota error, use local ML model
        if (isQuotaError) {
          debugPrint('API Quota exceeded, using local ML model');
          try {
            final localResult = await _localAnalysisService.analyzeFaceOffline(imageBase64);
            return localResult;
          } catch (e) {
            debugPrint('Local ML failed, using simulated: $e');
            return _generateSimulatedResult(imageBase64);
          }
        }
        
        // For other errors, try local ML first
        try {
          final localResult = await _localAnalysisService.analyzeFaceOffline(imageBase64);
          return localResult;
        } catch (e) {
          debugPrint('Local ML failed, using simulated: $e');
          return _generateSimulatedResult(imageBase64);
        }
      }
    } catch (e) {
      // Log error for debugging
      debugPrint('Face Analysis Error: $e');
      
      // If API call fails (including quota errors), use local ML model
      debugPrint('API call failed, using local ML model');
      try {
        final localResult = await _localAnalysisService.analyzeFaceOffline(imageBase64);
        return localResult;
      } catch (e) {
        debugPrint('Local ML failed, using simulated: $e');
        // Try cache again (might have been added by another request)
        final cachedData = await _cacheService.getCachedFaceAnalysis(imageBase64);
        if (cachedData != null) {
          final enhancedJson = <String, dynamic>{
            ...cachedData,
            'imageBase64': imageBase64,
            'source': 'AnalysisSource.cached',
            'goldenRatioMeasurements': cachedData['goldenRatioMeasurements'] ?? <String, dynamic>{},
            'featureDetails': cachedData['featureDetails'] ?? <String, dynamic>{},
          };
          return FaceAnalysisResult.fromJson(enhancedJson);
        }
        return _generateSimulatedResult(imageBase64);
      }
    }
  }

  FaceAnalysisResult _generateSimulatedResult(String imageBase64) {
    final result = _generateSimulatedResultInternal(imageBase64);
    return FaceAnalysisResult(
      attractivenessScore: result.attractivenessScore,
      bestAngle: result.bestAngle,
      bestAngleDescription: result.bestAngleDescription,
      facialFeatures: result.facialFeatures,
      overallAnalysis: result.overallAnalysis,
      imageBase64: result.imageBase64,
      source: AnalysisSource.simulated,
      goldenRatioMeasurements: result.goldenRatioMeasurements,
      featureDetails: result.featureDetails,
    );
  }

  FaceAnalysisResult _generateSimulatedResultInternal(String imageBase64) {
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
    
    return FaceAnalysisResult(
      attractivenessScore: attractiveness,
      bestAngle: bestAngle['angle'] as String,
      bestAngleDescription: bestAngle['desc'] as String,
      facialFeatures: {
        'symmetry': 78.0 + (DateTime.now().millisecond % 8),
        'skinQuality': 75.0 + (DateTime.now().millisecond % 10),
        'facialStructure': 80.0 + (DateTime.now().millisecond % 6),
        'eyeArea': 82.0 + (DateTime.now().millisecond % 8),
        'nose': 76.0 + (DateTime.now().millisecond % 6),
        'lips': 79.0 + (DateTime.now().millisecond % 7),
      },
      overallAnalysis: 'Your face shows good overall symmetry and balanced features. The facial structure is well-proportioned with clear skin tone. Consider maintaining good skincare routine for optimal appearance.',
      imageBase64: imageBase64,
      source: AnalysisSource.simulated, // This will be overridden by _generateSimulatedResult
    );
  }
}

