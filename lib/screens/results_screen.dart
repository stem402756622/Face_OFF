import 'dart:convert';
import 'package:flutter/material.dart';
import 'dart:math' as math;
import '../models/face_analysis_result.dart';
import '../models/medical_solution.dart';
import '../models/skin_health.dart';
import '../models/style_suggestions.dart';
import '../models/analysis_history.dart';
import '../services/database_helper.dart';
import '../widgets/attractiveness_scale.dart';
import '../widgets/best_angle_card.dart';
import '../widgets/feature_breakdown.dart';
import '../widgets/medical_solution_card.dart';
import '../widgets/analysis_source_badge.dart';
import '../widgets/skin_health_card.dart';
import '../widgets/style_suggestions_card.dart';
import '../widgets/golden_ratio_card.dart';

class ResultsScreen extends StatefulWidget {
  final FaceAnalysisResult faceAnalysis;
  final MedicalSolution medicalSolution;
  final SkinHealth? skinHealth;
  final StyleSuggestions? styleSuggestions;
  final bool shouldSave;

  const ResultsScreen({
    super.key,
    required this.faceAnalysis,
    required this.medicalSolution,
    this.skinHealth,
    this.styleSuggestions,
    this.shouldSave = true,
  });

  @override
  State<ResultsScreen> createState() => _ResultsScreenState();
}

class _ResultsScreenState extends State<ResultsScreen>
    with TickerProviderStateMixin {
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;
  bool _isSaving = false;
  bool _isSaved = false;
  late AnimationController _fadeController;
  late AnimationController _slideController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    if (widget.shouldSave) {
      _saveAnalysis();
    } else {
      _isSaved = true; // Mark as saved for viewing existing analyses
    }
    _setupAnimations();
  }

  void _setupAnimations() {
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _slideController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _fadeController, curve: Curves.easeIn));

    _slideAnimation =
        Tween<Offset>(begin: const Offset(0, 0.3), end: Offset.zero).animate(
          CurvedAnimation(parent: _slideController, curve: Curves.easeOutCubic),
        );

    _fadeController.forward();
    _slideController.forward();
  }

  Future<void> _saveAnalysis() async {
    setState(() {
      _isSaving = true;
    });

    try {
      final history = AnalysisHistory(
        attractivenessScore: widget.faceAnalysis.attractivenessScore,
        bestAngle: widget.faceAnalysis.bestAngle,
        bestAngleDescription: widget.faceAnalysis.bestAngleDescription,
        overallAnalysis: widget.faceAnalysis.overallAnalysis,
        imageBase64: widget.faceAnalysis.imageBase64,
        facialFeaturesJson: jsonEncode(widget.faceAnalysis.facialFeatures),
        medicalCondition: widget.medicalSolution.condition,
        medicalSeverity: widget.medicalSolution.severity,
        medicalDescription: widget.medicalSolution.description,
        medicalRecommendationsJson: jsonEncode(
          widget.medicalSolution.recommendations,
        ),
        medicalTreatmentsJson: jsonEncode(widget.medicalSolution.treatments),
        createdAt: DateTime.now(),
      );

      await _dbHelper.insertAnalysis(history);

      if (mounted) {
        setState(() {
          _isSaving = false;
          _isSaved = true;
        });
      }
    } catch (e) {
      debugPrint('Error saving analysis: $e');
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _slideController.dispose();
    super.dispose();
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
              // Enhanced App Bar
              _buildEnhancedAppBar(),
              // Content
              Expanded(
                child: FadeTransition(
                  opacity: _fadeAnimation,
                  child: SlideTransition(
                    position: _slideAnimation,
                    child: SingleChildScrollView(
                      physics: const BouncingScrollPhysics(),
                      padding: const EdgeInsets.all(20.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Analysis Source Badge with animation
                          _buildAnimatedBadge(),
                          const SizedBox(height: 20),
                          // Enhanced Face Image Preview
                          _buildEnhancedImagePreview(),
                          const SizedBox(height: 24),
                          // Attractiveness Scale with animation
                          _buildAnimatedWidget(
                            delay: 100,
                            child: AttractivenessScale(
                              score: widget.faceAnalysis.attractivenessScore,
                            ),
                          ),
                          const SizedBox(height: 24),
                          // Best Angle Card with animation
                          _buildAnimatedWidget(
                            delay: 200,
                            child: BestAngleCard(
                              bestAngle: widget.faceAnalysis.bestAngle,
                              description:
                                  widget.faceAnalysis.bestAngleDescription,
                            ),
                          ),
                          const SizedBox(height: 24),
                          // Feature Breakdown with animation
                          _buildAnimatedWidget(
                            delay: 300,
                            child: FeatureBreakdown(
                              features: widget.faceAnalysis.facialFeatures,
                            ),
                          ),
                          const SizedBox(height: 24),
                          // Golden Ratio Analysis
                          _buildAnimatedWidget(
                            delay: 350,
                            child: GoldenRatioCard(
                              faceAnalysis: widget.faceAnalysis,
                            ),
                          ),
                          const SizedBox(height: 24),
                          // Enhanced Overall Analysis
                          _buildAnimatedWidget(
                            delay: 400,
                            child: _buildEnhancedAnalysisCard(),
                          ),
                          const SizedBox(height: 24),
                          // Skin Health Analysis
                          if (widget.skinHealth != null) ...[
                            _buildAnimatedWidget(
                              delay: 450,
                              child: SkinHealthCard(
                                skinHealth: widget.skinHealth!,
                              ),
                            ),
                            const SizedBox(height: 24),
                          ],
                          // Style & Enhancement Suggestions Header
                          if (widget.styleSuggestions != null) ...[
                            _buildAnimatedWidget(
                              delay: 480,
                              child: _buildSectionHeader(
                                icon: Icons.style,
                                title: 'Style & Enhancement Suggestions',
                                color: Colors.purple,
                              ),
                            ),
                            const SizedBox(height: 16),
                            // Style Suggestions Card
                            _buildAnimatedWidget(
                              delay: 500,
                              child: StyleSuggestionsCard(
                                styleSuggestions: widget.styleSuggestions!,
                              ),
                            ),
                            const SizedBox(height: 24),
                          ],
                          // Enhanced Medical Solutions Header
                          _buildAnimatedWidget(
                            delay: 500,
                            child: _buildSectionHeader(
                              icon: Icons.medical_services,
                              title: 'Dermatological Solutions',
                              color: Colors.pink,
                            ),
                          ),
                          const SizedBox(height: 16),
                          // Medical Solution Card with animation
                          _buildAnimatedWidget(
                            delay: 600,
                            child: MedicalSolutionCard(
                              solution: widget.medicalSolution,
                            ),
                          ),
                          const SizedBox(height: 40),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEnhancedAppBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.8),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () => Navigator.pop(context),
              borderRadius: BorderRadius.circular(12),
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.arrow_back,
                  color: Colors.black87,
                  size: 24,
                ),
              ),
            ),
          ),
          const Expanded(
            child: Text(
              'Analysis Results',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
                letterSpacing: 0.5,
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: _isSaved ? Colors.green[50] : Colors.grey[100],
              borderRadius: BorderRadius.circular(12),
            ),
            child: _isSaving
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Icon(
                    _isSaved ? Icons.check_circle : Icons.save_outlined,
                    color: _isSaved ? Colors.green[600] : Colors.grey[600],
                    size: 24,
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildAnimatedBadge() {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: const Duration(milliseconds: 600),
      curve: Curves.elasticOut,
      builder: (context, value, child) {
        return Transform.scale(
          scale: value,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [AnalysisSourceBadge(source: widget.faceAnalysis.source)],
          ),
        );
      },
    );
  }

  Widget _buildEnhancedImagePreview() {
    if (widget.faceAnalysis.imageBase64.isEmpty) return const SizedBox.shrink();

    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: const Duration(milliseconds: 800),
      curve: Curves.easeOutCubic,
      builder: (context, value, child) {
        return Transform.scale(
          scale: 0.8 + (value * 0.2),
          child: Opacity(
            opacity: value,
            child: Container(
              width: double.infinity,
              height: 280,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: Colors.purple.withOpacity(0.2),
                    blurRadius: 30,
                    spreadRadius: 5,
                    offset: const Offset(0, 15),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(24),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    Image.memory(
                      base64Decode(widget.faceAnalysis.imageBase64),
                      fit: BoxFit.cover,
                    ),
                    // Gradient overlay
                    Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.transparent,
                            Colors.black.withOpacity(0.1),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildAnimatedWidget({required int delay, required Widget child}) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: Duration(milliseconds: 600 + delay),
      curve: Curves.easeOutCubic,
      builder: (context, value, child) {
        return Opacity(
          opacity: value,
          child: Transform.translate(
            offset: Offset(0, 20 * (1 - value)),
            child: child,
          ),
        );
      },
      child: child,
    );
  }

  Widget _buildEnhancedAnalysisCard() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Colors.white, Colors.blue[50]!],
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.blue.withOpacity(0.15),
            blurRadius: 25,
            spreadRadius: 2,
            offset: const Offset(0, 10),
          ),
        ],
        border: Border.all(color: Colors.blue.withOpacity(0.2), width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.blue[400]!, Colors.blue[600]!],
                  ),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.blue.withOpacity(0.3),
                      blurRadius: 10,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.insights,
                  color: Colors.white,
                  size: 28,
                ),
              ),
              const SizedBox(width: 16),
              const Expanded(
                child: Text(
                  'Overall Analysis',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.7),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Text(
              widget.faceAnalysis.overallAnalysis,
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[800],
                height: 1.7,
                letterSpacing: 0.3,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader({
    required IconData icon,
    required String title,
    required Color color,
  }) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            gradient: LinearGradient(colors: [color, color.withOpacity(0.7)]),
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: color.withOpacity(0.3),
                blurRadius: 10,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: Icon(icon, color: Colors.white, size: 24),
        ),
        const SizedBox(width: 12),
        Text(
          title,
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
            letterSpacing: 0.5,
          ),
        ),
      ],
    );
  }
}
