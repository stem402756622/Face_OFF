import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/analysis_history.dart';
import '../models/face_analysis_result.dart';
import '../models/medical_solution.dart';
import '../services/skin_health_service.dart';
import '../services/style_enhancement_service.dart';
import '../services/database_helper.dart';
import '../widgets/progress_chart.dart';
import 'results_screen.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;
  final SkinHealthService _skinHealthService = SkinHealthService();
  final StyleEnhancementService _styleEnhancementService =
      StyleEnhancementService();
  List<AnalysisHistory> _analyses = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadAnalyses();
  }

  Future<void> _loadAnalyses() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final analyses = await _dbHelper.getAllAnalyses();
      setState(() {
        _analyses = analyses;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('Error loading analyses: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _deleteAnalysis(int id) async {
    try {
      await _dbHelper.deleteAnalysis(id);
      _loadAnalyses();
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Analysis deleted')));
      }
    } catch (e) {
      debugPrint('Error deleting analysis: $e');
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error deleting: $e')));
      }
    }
  }

  Future<void> _deleteAllAnalyses() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete All History'),
        content: const Text(
          'Are you sure you want to delete all analysis history? This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete All'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await _dbHelper.deleteAllAnalyses();
        _loadAnalyses();
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text('All analyses deleted')));
        }
      } catch (e) {
        debugPrint('Error deleting all analyses: $e');
      }
    }
  }

  void _viewAnalysis(AnalysisHistory history) {
    final faceAnalysis = FaceAnalysisResult(
      attractivenessScore: history.attractivenessScore,
      bestAngle: history.bestAngle,
      bestAngleDescription: history.bestAngleDescription,
      facialFeatures: Map<String, double>.from(
        jsonDecode(history.facialFeaturesJson),
      ),
      overallAnalysis: history.overallAnalysis,
      imageBase64: history.imageBase64,
    );

    final medicalSolution = MedicalSolution(
      condition: history.medicalCondition,
      description: history.medicalDescription,
      recommendations: List<String>.from(
        jsonDecode(history.medicalRecommendationsJson),
      ),
      severity: history.medicalSeverity,
      treatments: List<String>.from(jsonDecode(history.medicalTreatmentsJson)),
    );

    // Generate skin health and style suggestions for old analyses
    final skinHealth = _skinHealthService.analyzeSkinHealth(faceAnalysis);
    final styleSuggestions = _styleEnhancementService.generateSuggestions(
      faceAnalysis,
    );

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ResultsScreen(
          faceAnalysis: faceAnalysis,
          medicalSolution: medicalSolution,
          skinHealth: skinHealth,
          styleSuggestions: styleSuggestions,
          shouldSave: false,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Colors.purple[50]!, Colors.blue[50]!, Colors.white],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // App Bar
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back),
                      onPressed: () => Navigator.pop(context),
                      color: Colors.black87,
                    ),
                    const Expanded(
                      child: Text(
                        'Analysis History',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                    ),
                    if (_analyses.isNotEmpty)
                      IconButton(
                        icon: const Icon(Icons.delete_outline),
                        onPressed: _deleteAllAnalyses,
                        color: Colors.red,
                        tooltip: 'Delete All',
                      ),
                    const SizedBox(width: 8),
                  ],
                ),
              ),
              // Content
              Expanded(
                child: _isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : _analyses.isEmpty
                    ? _buildEmptyState()
                    : _buildHistoryList(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.history, size: 80, color: Colors.grey[400]),
          const SizedBox(height: 24),
          Text(
            'No Analysis History',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Your face analyses will appear here',
            style: TextStyle(fontSize: 16, color: Colors.grey[500]),
          ),
        ],
      ),
    );
  }

  Widget _buildHistoryList() {
    return RefreshIndicator(
      onRefresh: _loadAnalyses,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _analyses.length + 1, // +1 for progress chart
        itemBuilder: (context, index) {
          if (index == 0) {
            // Show progress chart at the top
            return Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: ProgressChart(analyses: _analyses),
            );
          }
          final analysis = _analyses[index - 1];
          return _buildHistoryCard(analysis);
        },
      ),
    );
  }

  Widget _buildHistoryCard(AnalysisHistory analysis) {
    final dateFormat = DateFormat('MMM dd, yyyy • hh:mm a');
    final score = analysis.attractivenessScore;
    Color scoreColor;
    if (score >= 80) {
      scoreColor = Colors.green;
    } else if (score >= 65) {
      scoreColor = Colors.blue;
    } else if (score >= 50) {
      scoreColor = Colors.orange;
    } else {
      scoreColor = Colors.red;
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        onTap: () => _viewAnalysis(analysis),
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // Image Thumbnail
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.memory(
                  base64Decode(analysis.imageBase64),
                  width: 80,
                  height: 80,
                  fit: BoxFit.cover,
                ),
              ),
              const SizedBox(width: 16),
              // Details
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: scoreColor.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            '${score.toStringAsFixed(1)}/100',
                            style: TextStyle(
                              color: scoreColor,
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            analysis.bestAngle,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.black87,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      analysis.medicalCondition,
                      style: TextStyle(fontSize: 14, color: Colors.grey[700]),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      dateFormat.format(analysis.createdAt),
                      style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                    ),
                  ],
                ),
              ),
              // Delete Button
              IconButton(
                icon: const Icon(Icons.delete_outline),
                onPressed: () => _deleteAnalysis(analysis.id!),
                color: Colors.red[300],
                tooltip: 'Delete',
              ),
            ],
          ),
        ),
      ),
    );
  }
}
