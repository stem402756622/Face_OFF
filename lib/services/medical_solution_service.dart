import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:crypto/crypto.dart';
import '../models/face_analysis_result.dart';
import '../models/medical_solution.dart';
import 'connectivity_service.dart';
import 'cache_service.dart';

class MedicalSolutionService {
  static const String apiUrl = 'https://api.openai.com/v1/chat/completions';
  // API key should be set via environment variable OPENAI_API_KEY
  // For local development, you can set it in your environment or use a config file
  static String get apiKey => const String.fromEnvironment(
    'OPENAI_API_KEY',
    defaultValue: '',
  );
  
  final ConnectivityService _connectivityService = ConnectivityService.instance;
  final CacheService _cacheService = CacheService.instance;

  String _generateAnalysisKey(FaceAnalysisResult faceAnalysis) {
    final keyData = '${faceAnalysis.attractivenessScore}_${faceAnalysis.overallAnalysis}';
    final bytes = utf8.encode(keyData);
    final hash = sha256.convert(bytes);
    return hash.toString();
  }

  Future<MedicalSolution> getMedicalSolutions(FaceAnalysisResult faceAnalysis) async {
    // Check cache first (works offline)
    final analysisKey = _generateAnalysisKey(faceAnalysis);
    final cachedData = await _cacheService.getCachedMedicalSolution(analysisKey);
    if (cachedData != null) {
      debugPrint('Using cached medical solution');
      return MedicalSolution.fromJson(cachedData);
    }

    // Check connectivity
    final isConnected = await _connectivityService.isConnected();
    if (!isConnected) {
      debugPrint('Offline: Using simulated medical solution');
      return _generateSimulatedSolution(faceAnalysis);
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
              'content': '''Based on this facial analysis, provide professional dermatological recommendations and solutions.

Face Analysis Details:
- Overall Analysis: ${faceAnalysis.overallAnalysis}
- Attractiveness Score: ${faceAnalysis.attractivenessScore.toStringAsFixed(1)}/100
- Facial Features Scores:
  - Symmetry: ${faceAnalysis.facialFeatures['symmetry']?.toStringAsFixed(1) ?? 'N/A'}/100
  - Skin Quality: ${faceAnalysis.facialFeatures['skinQuality']?.toStringAsFixed(1) ?? 'N/A'}/100
  - Facial Structure: ${faceAnalysis.facialFeatures['facialStructure']?.toStringAsFixed(1) ?? 'N/A'}/100
  - Eye Area: ${faceAnalysis.facialFeatures['eyeArea']?.toStringAsFixed(1) ?? 'N/A'}/100
  - Nose: ${faceAnalysis.facialFeatures['nose']?.toStringAsFixed(1) ?? 'N/A'}/100
  - Lips: ${faceAnalysis.facialFeatures['lips']?.toStringAsFixed(1) ?? 'N/A'}/100

Return ONLY a valid JSON object with the following structure (no markdown, no code blocks, just pure JSON):
{
  "condition": "<skin condition assessment: e.g., 'Healthy Skin', 'Mild Skin Concerns', 'Moderate Skin Issues', etc.>",
  "description": "<detailed description of the skin condition based on the analysis>",
  "recommendations": ["<recommendation 1>", "<recommendation 2>", "<recommendation 3>", "<recommendation 4>"],
  "severity": "<Low, Moderate, or High>",
  "treatments": ["<treatment 1>", "<treatment 2>", "<treatment 3>"]
}

Provide professional, evidence-based dermatological advice. Focus on skincare routines, products, and treatments that are appropriate for the identified skin condition.'''
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
        
        final solutionJson = jsonDecode(jsonContent);
        
        // Cache the successful response
        await _cacheService.cacheMedicalSolution(analysisKey, solutionJson);
        
        return MedicalSolution.fromJson(solutionJson);
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
        
        // If quota error, immediately use simulated solution (based on face analysis)
        if (isQuotaError) {
          debugPrint('API Quota exceeded, using simulated medical solution based on face analysis');
        }
        
        // Always fall back to simulated solution for medical (since we don't have local ML for medical)
        return _generateSimulatedSolution(faceAnalysis);
      }
    } catch (e) {
      // Log error for debugging
      debugPrint('Medical Solution Error: $e');
      // If network error, try cache again
      final cachedData = await _cacheService.getCachedMedicalSolution(analysisKey);
      if (cachedData != null) {
        return MedicalSolution.fromJson(cachedData);
      }
      return _generateSimulatedSolution(faceAnalysis);
    }
  }

  MedicalSolution _generateSimulatedSolution(FaceAnalysisResult faceAnalysis) {
    // Simulated medical solution based on analysis
    final skinScore = faceAnalysis.facialFeatures['skinQuality'] ?? 75.0;
    
    List<String> recommendations = [];
    List<String> treatments = [];
    String condition = 'Healthy Skin';
    String severity = 'Low';
    
    if (skinScore < 70) {
      condition = 'Mild Skin Concerns';
      severity = 'Moderate';
      recommendations = [
        'Use a gentle cleanser twice daily',
        'Apply moisturizer with SPF 30+ every morning',
        'Consider incorporating retinol in your evening routine',
        'Stay hydrated and maintain a balanced diet',
      ];
      treatments = [
        'Topical retinoids',
        'Vitamin C serum',
        'Hyaluronic acid moisturizer',
        'Regular exfoliation (2-3 times per week)',
      ];
    } else {
      recommendations = [
        'Maintain current skincare routine',
        'Continue using sunscreen daily',
        'Stay hydrated',
        'Regular facial cleansing',
      ];
      treatments = [
        'Preventive skincare maintenance',
        'Regular moisturization',
      ];
    }
    
    return MedicalSolution(
      condition: condition,
      description: 'Based on the facial analysis, your skin shows ${skinScore > 75 ? "good" : "moderate"} quality. ${skinScore < 70 ? "Some improvements can be made through targeted skincare." : "Maintain your current routine for optimal results."}',
      recommendations: recommendations,
      severity: severity,
      treatments: treatments,
    );
  }
}

