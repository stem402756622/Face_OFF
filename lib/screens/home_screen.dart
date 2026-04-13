import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shimmer/shimmer.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'dart:math' as math;
import '../services/image_service.dart';
import '../services/face_analysis_service.dart';
import '../services/medical_solution_service.dart';
import '../services/skin_health_service.dart';
import '../services/style_enhancement_service.dart';
import '../services/connectivity_service.dart';
import '../services/database_helper.dart';
import 'results_screen.dart';
import 'history_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with SingleTickerProviderStateMixin {
  final ImageService _imageService = ImageService();
  final FaceAnalysisService _faceAnalysisService = FaceAnalysisService();
  final MedicalSolutionService _medicalSolutionService =
      MedicalSolutionService();
  final SkinHealthService _skinHealthService = SkinHealthService();
  final StyleEnhancementService _styleEnhancementService =
      StyleEnhancementService();
  final ConnectivityService _connectivityService = ConnectivityService.instance;
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;

  bool _isLoading = false;
  bool _isOnline = true;
  int _analysisCount = 0;
  late AnimationController _animationController;
  late Animation<double> _logoAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _checkConnectivity();
    _loadAnalysisCount();
    _setupAnimations();

    _connectivityService.connectivityStream.listen((results) {
      setState(() {
        _isOnline =
            results.isNotEmpty &&
            !results.contains(ConnectivityResult.none) &&
            (results.contains(ConnectivityResult.mobile) ||
                results.contains(ConnectivityResult.wifi) ||
                results.contains(ConnectivityResult.ethernet));
      });
    });
  }

  void _setupAnimations() {
    _animationController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );

    _logoAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.elasticOut),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.3, 1.0, curve: Curves.easeIn),
      ),
    );

    _animationController.forward();
  }

  Future<void> _loadAnalysisCount() async {
    final count = await _dbHelper.getAnalysisCount();
    setState(() {
      _analysisCount = count;
    });
  }

  Future<void> _checkConnectivity() async {
    final isConnected = await _connectivityService.isConnected();
    setState(() {
      _isOnline = isConnected;
    });
  }

  Future<void> _analyzeFace(ImageSource source) async {
    // Check connectivity first
    final isConnected = await _connectivityService.isConnected();
    if (!isConnected) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Face analysis is not available in offline mode. Please check your internet connection.',
            ),
            backgroundColor: Colors.red,
          ),
        );
      }
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      String? imageBase64;

      if (source == ImageSource.camera) {
        imageBase64 = await _imageService.pickAndEncodeImage();
      } else {
        imageBase64 = await _imageService.pickFromGallery();
      }

      if (imageBase64 == null) {
        setState(() {
          _isLoading = false;
        });
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text('No image selected')));
        }
        return;
      }

      // Analyze face
      final faceAnalysis = await _faceAnalysisService.analyzeFace(imageBase64);

      // Get medical solutions
      final medicalSolution = await _medicalSolutionService.getMedicalSolutions(
        faceAnalysis,
      );

      // Get skin health analysis
      final skinHealth = _skinHealthService.analyzeSkinHealth(faceAnalysis);

      // Get style suggestions
      final styleSuggestions = _styleEnhancementService.generateSuggestions(
        faceAnalysis,
      );

      if (mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ResultsScreen(
              faceAnalysis: faceAnalysis,
              medicalSolution: medicalSolution,
              skinHealth: skinHealth,
              styleSuggestions: styleSuggestions,
            ),
          ),
        ).then((_) => _loadAnalysisCount());
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
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
          child: _isLoading
              ? _buildLoadingState()
              : Stack(
                  children: [
                    _buildAnimatedBackground(),
                    _buildMainContent(),
                    _buildTopBar(),
                  ],
                ),
        ),
      ),
    );
  }

  Widget _buildAnimatedBackground() {
    return Positioned.fill(child: CustomPaint(painter: _ParticlePainter()));
  }

  Widget _buildTopBar() {
    return Positioned(
      top: 16,
      left: 16,
      right: 16,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Offline Indicator
          if (!_isOnline)
            Expanded(
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: Colors.orange[600],
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.orange.withOpacity(0.3),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.wifi_off, color: Colors.white, size: 16),
                    SizedBox(width: 8),
                    Text(
                      'Offline Mode',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          if (!_isOnline) const SizedBox(width: 8),
          // History Button
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.purple.withOpacity(0.2),
                  blurRadius: 15,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const HistoryScreen(),
                    ),
                  ).then((_) => _loadAnalysisCount());
                },
                borderRadius: BorderRadius.circular(30),
                child: Container(
                  padding: const EdgeInsets.all(12),
                  child: Stack(
                    children: [
                      Icon(Icons.history, color: Colors.purple[600], size: 24),
                      if (_analysisCount > 0)
                        Positioned(
                          right: 0,
                          top: 0,
                          child: Container(
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              color: Colors.red,
                              shape: BoxShape.circle,
                            ),
                            constraints: const BoxConstraints(
                              minWidth: 16,
                              minHeight: 16,
                            ),
                            child: Text(
                              '$_analysisCount',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Shimmer.fromColors(
            baseColor: Colors.grey[300]!,
            highlightColor: Colors.grey[100]!,
            child: Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF667eea), Color(0xFF764ba2)],
                ),
                shape: BoxShape.circle,
              ),
            ),
          ),
          const SizedBox(height: 32),
          const Text(
            'Analyzing your face...',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 16),
          const CircularProgressIndicator(),
        ],
      ),
    );
  }

  Widget _buildMainContent() {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            const SizedBox(height: 80),
            // Animated Logo
            AnimatedBuilder(
              animation: _logoAnimation,
              builder: (context, child) {
                return Transform.scale(
                  scale: _logoAnimation.value,
                  child: Transform.rotate(
                    angle: (1 - _logoAnimation.value) * 0.2,
                    child: Container(
                      width: 140,
                      height: 140,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [Color(0xFF667eea), Color(0xFF764ba2)],
                        ),
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.purple.withOpacity(0.4),
                            blurRadius: 30,
                            spreadRadius: 5,
                            offset: const Offset(0, 15),
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.face,
                        size: 70,
                        color: Colors.white,
                      ),
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 32),
            // App Title
            FadeTransition(
              opacity: _fadeAnimation,
              child: Column(
                children: [
                  const Text(
                    'FaceOFF',
                    style: TextStyle(
                      fontSize: 48,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                      letterSpacing: 1.5,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Advanced Face Analysis',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 18,
                      color: Colors.grey[700],
                      height: 1.5,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 50),
            // Stats Card
            FadeTransition(opacity: _fadeAnimation, child: _buildStatsCard()),
            const SizedBox(height: 30),
            // Show different content based on connectivity
            if (_isOnline) ...[
              // Enhanced Action Buttons
              FadeTransition(
                opacity: _fadeAnimation,
                child: _buildEnhancedActionButton(
                  icon: Icons.camera_alt,
                  label: 'Scan with Camera',
                  subtitle: 'Take a photo for analysis',
                  color: const Color(0xFF667eea),
                  onTap: () => _analyzeFace(ImageSource.camera),
                ),
              ),
              const SizedBox(height: 16),
              FadeTransition(
                opacity: _fadeAnimation,
                child: _buildEnhancedActionButton(
                  icon: Icons.photo_library,
                  label: 'Choose from Gallery',
                  subtitle: 'Select an existing photo',
                  color: const Color(0xFF764ba2),
                  onTap: () => _analyzeFace(ImageSource.gallery),
                ),
              ),
              const SizedBox(height: 30),
              // Feature Cards
              FadeTransition(
                opacity: _fadeAnimation,
                child: _buildFeatureGrid(),
              ),
            ] else ...[
              // Offline Mode Content
              FadeTransition(
                opacity: _fadeAnimation,
                child: _buildOfflineContent(),
              ),
            ],
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildStatsCard() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Colors.white, Colors.purple[50]!],
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.purple.withOpacity(0.1),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
        border: Border.all(color: Colors.purple.withOpacity(0.1), width: 1),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildStatItem(
            Icons.analytics,
            '$_analysisCount',
            'Analyses',
            Colors.purple,
          ),
          Container(width: 1, height: 40, color: Colors.grey[300]),
          _buildStatItem(
            Icons.psychology,
            _isOnline ? 'Cloud' : 'Local',
            'Mode',
            _isOnline ? Colors.green : Colors.orange,
          ),
          Container(width: 1, height: 40, color: Colors.grey[300]),
          _buildStatItem(Icons.trending_up, '100%', 'Accurate', Colors.blue),
        ],
      ),
    );
  }

  Widget _buildStatItem(
    IconData icon,
    String value,
    String label,
    Color color,
  ) {
    return Column(
      children: [
        Icon(icon, color: color, size: 28),
        const SizedBox(height: 8),
        Text(
          value,
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        const SizedBox(height: 4),
        Text(label, style: TextStyle(fontSize: 12, color: Colors.grey[600])),
      ],
    );
  }

  Widget _buildEnhancedActionButton({
    required IconData icon,
    required String label,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: const Duration(milliseconds: 300),
      builder: (context, value, child) {
        return Transform.scale(
          scale: value,
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: onTap,
              borderRadius: BorderRadius.circular(20),
              child: Ink(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [color, color.withOpacity(0.8)],
                  ),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: color.withOpacity(0.4),
                      blurRadius: 25,
                      offset: const Offset(0, 10),
                      spreadRadius: 2,
                    ),
                  ],
                ),
                child: Container(
                  padding: const EdgeInsets.all(20),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Icon(icon, color: Colors.white, size: 32),
                      ),
                      const SizedBox(width: 20),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              label,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              subtitle,
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.9),
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Icon(
                        Icons.arrow_forward_ios,
                        color: Colors.white,
                        size: 20,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildFeatureGrid() {
    return Row(
      children: [
        Expanded(
          child: _buildFeatureCard(
            icon: Icons.analytics,
            title: 'Smart Analysis',
            description: 'Advanced facial scoring',
            color: Colors.purple,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildFeatureCard(
            icon: Icons.camera_alt,
            title: 'Best Angles',
            description: 'Find your pose',
            color: Colors.blue,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildFeatureCard(
            icon: Icons.medical_services,
            title: 'Solutions',
            description: 'Skincare advice',
            color: Colors.pink,
          ),
        ),
      ],
    );
  }

  Widget _buildOfflineContent() {
    return Column(
      children: [
        // Offline Message
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.orange[50],
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.orange[200]!, width: 1),
          ),
          child: Column(
            children: [
              Icon(Icons.wifi_off, size: 48, color: Colors.orange[600]),
              const SizedBox(height: 16),
              Text(
                'Offline Mode',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.orange[800],
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Face analysis requires an internet connection.\nYou can view your analysis history below.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.orange[700],
                  height: 1.5,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 30),
        // View History Button
        _buildEnhancedActionButton(
          icon: Icons.history,
          label: 'View Analysis History',
          subtitle: 'See your previous analyses',
          color: const Color(0xFF667eea),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const HistoryScreen()),
            ).then((_) => _loadAnalysisCount());
          },
        ),
        const SizedBox(height: 20),
        // History Stats
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.purple.withOpacity(0.1),
                blurRadius: 15,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.history, color: Colors.purple[600], size: 32),
              const SizedBox(width: 16),
              Text(
                '$_analysisCount Saved Analyses',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.purple[800],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildFeatureCard({
    required IconData icon,
    required String title,
    required String description,
    required Color color,
  }) {
    return Container(
      constraints: const BoxConstraints(minHeight: 160, maxHeight: 180),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.1),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
        border: Border.all(color: color.withOpacity(0.2), width: 1),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(height: 10),
          Flexible(
            child: Text(
              title,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: color,
              ),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(height: 4),
          Flexible(
            child: Text(
              description,
              style: TextStyle(fontSize: 11, color: Colors.grey[600]),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}

class _ParticlePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.purple.withOpacity(0.05)
      ..style = PaintingStyle.fill;

    final random = math.Random(42);
    for (int i = 0; i < 20; i++) {
      final x = random.nextDouble() * size.width;
      final y = random.nextDouble() * size.height;
      final radius = random.nextDouble() * 3 + 1;
      canvas.drawCircle(Offset(x, y), radius, paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
