import 'package:flutter/material.dart';

class FeatureBreakdown extends StatefulWidget {
  final Map<String, double> features;

  const FeatureBreakdown({super.key, required this.features});

  @override
  State<FeatureBreakdown> createState() => _FeatureBreakdownState();
}

class _FeatureBreakdownState extends State<FeatureBreakdown>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.white,
            Colors.purple[50]!,
          ],
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.purple.withOpacity(0.15),
            blurRadius: 25,
            spreadRadius: 2,
            offset: const Offset(0, 10),
          ),
        ],
        border: Border.all(
          color: Colors.purple.withOpacity(0.2),
          width: 1.5,
        ),
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
                    colors: [
                      Colors.purple[400]!,
                      Colors.blue[400]!,
                    ],
                  ),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.purple.withOpacity(0.3),
                      blurRadius: 10,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.analytics,
                  color: Colors.white,
                  size: 28,
                ),
              ),
              const SizedBox(width: 16),
              const Text(
                'Feature Breakdown',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          ...widget.features.entries.toList().asMap().entries.map((entry) {
            final index = entry.key;
            final featureEntry = entry.value;
            final totalFeatures = widget.features.length;
            // Calculate intervals that fit within [0.0, 1.0]
            // Start at 0.2, distribute remaining 0.8 across all features
            final start = 0.2 + (index * 0.7 / totalFeatures);
            final end = (0.2 + ((index + 1) * 0.7 / totalFeatures)).clamp(0.0, 1.0);
            return _AnimatedFeatureItem(
              label: _formatLabel(featureEntry.key),
              score: featureEntry.value,
              animation: Tween<double>(begin: 0.0, end: 1.0).animate(
                CurvedAnimation(
                  parent: _controller,
                  curve: Interval(
                    start.clamp(0.0, 1.0),
                    end,
                    curve: Curves.easeOutCubic,
                  ),
                ),
              ),
            );
          }),
        ],
      ),
    );
  }

  String _formatLabel(String key) {
    return key
        .split(RegExp(r'(?=[A-Z])'))
        .map((word) => word[0].toUpperCase() + word.substring(1))
        .join(' ');
  }
}

class _AnimatedFeatureItem extends StatelessWidget {
  final String label;
  final double score;
  final Animation<double> animation;

  const _AnimatedFeatureItem({
    required this.label,
    required this.score,
    required this.animation,
  });

  @override
  Widget build(BuildContext context) {
    final percentage = (score / 100).clamp(0.0, 1.0);
    final icon = _getIconForFeature(label);
    final color = _getColorForScore(score);

    return AnimatedBuilder(
      animation: animation,
      builder: (context, child) {
        return Opacity(
          opacity: animation.value,
          child: Transform.translate(
            offset: Offset(20 * (1 - animation.value), 0),
            child: Container(
              margin: const EdgeInsets.only(bottom: 20),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.7),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: color.withOpacity(0.2),
                  width: 1,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Icon(icon, color: color, size: 20),
                          const SizedBox(width: 8),
                          Text(
                            label,
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: Colors.grey[800],
                            ),
                          ),
                        ],
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: color.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          score.toStringAsFixed(1),
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: color,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Stack(
                    children: [
                      Container(
                        height: 10,
                        decoration: BoxDecoration(
                          color: Colors.grey[200],
                          borderRadius: BorderRadius.circular(5),
                        ),
                      ),
                      FractionallySizedBox(
                        widthFactor: percentage * animation.value,
                        child: Container(
                          height: 10,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                color,
                                color.withOpacity(0.7),
                              ],
                            ),
                            borderRadius: BorderRadius.circular(5),
                            boxShadow: [
                              BoxShadow(
                                color: color.withOpacity(0.4),
                                blurRadius: 8,
                                spreadRadius: 1,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  IconData _getIconForFeature(String label) {
    if (label.toLowerCase().contains('symmetry')) {
      return Icons.balance;
    } else if (label.toLowerCase().contains('skin')) {
      return Icons.spa;
    } else if (label.toLowerCase().contains('structure')) {
      return Icons.architecture;
    } else if (label.toLowerCase().contains('eye')) {
      return Icons.remove_red_eye;
    } else if (label.toLowerCase().contains('nose')) {
      return Icons.face;
    } else if (label.toLowerCase().contains('lip')) {
      return Icons.favorite;
    }
    return Icons.star;
  }

  Color _getColorForScore(double score) {
    if (score >= 85) return Colors.green;
    if (score >= 75) return Colors.blue;
    if (score >= 65) return Colors.orange;
    return Colors.red;
  }
}
