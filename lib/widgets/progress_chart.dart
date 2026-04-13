import 'package:flutter/material.dart';
import 'dart:math' as math;
import '../models/analysis_history.dart';

class ProgressChart extends StatelessWidget {
  final List<AnalysisHistory> analyses;

  const ProgressChart({
    super.key,
    required this.analyses,
  });

  @override
  Widget build(BuildContext context) {
    if (analyses.length < 2) {
      return const SizedBox.shrink();
    }

    // Sort by date (oldest first)
    final sortedAnalyses = List<AnalysisHistory>.from(analyses)
      ..sort((a, b) => a.createdAt.compareTo(b.createdAt));

    final scores = sortedAnalyses.map((a) => a.attractivenessScore).toList();
    final dates = sortedAnalyses.map((a) => a.createdAt).toList();

    final maxScore = scores.reduce(math.max);
    final minScore = scores.reduce(math.min);
    final scoreRange = maxScore - minScore;
    final padding = scoreRange > 0 ? scoreRange * 0.2 : 10;

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.white,
            Colors.blue[50]!,
          ],
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.blue.withOpacity(0.15),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
        border: Border.all(
          color: Colors.blue.withOpacity(0.2),
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
                      Colors.blue[400]!,
                      Colors.blue[600]!,
                    ],
                  ),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Icon(
                  Icons.trending_up,
                  color: Colors.white,
                  size: 28,
                ),
              ),
              const SizedBox(width: 16),
              const Expanded(
                child: Text(
                  'Progress Tracking',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          SizedBox(
            height: 200,
            child: CustomPaint(
              painter: _ProgressChartPainter(
                scores: scores,
                dates: dates,
                minScore: minScore - padding,
                maxScore: maxScore + padding,
              ),
              child: Container(),
            ),
          ),
          const SizedBox(height: 16),
          _buildStatsRow(sortedAnalyses),
        ],
      ),
    );
  }

  Widget _buildStatsRow(List<AnalysisHistory> sortedAnalyses) {
    final firstScore = sortedAnalyses.first.attractivenessScore;
    final lastScore = sortedAnalyses.last.attractivenessScore;
    final change = lastScore - firstScore;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: [
        _buildStatItem(
          'First Score',
          firstScore.toStringAsFixed(1),
          Colors.grey,
        ),
        _buildStatItem(
          'Latest Score',
          lastScore.toStringAsFixed(1),
          Colors.blue,
        ),
        _buildStatItem(
          'Change',
          '${change >= 0 ? '+' : ''}${change.toStringAsFixed(1)}',
          change >= 0 ? Colors.green : Colors.red,
        ),
        _buildStatItem(
          'Total Analyses',
          '${sortedAnalyses.length}',
          Colors.purple,
        ),
      ],
    );
  }

  Widget _buildStatItem(String label, String value, Color color) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[600],
          ),
        ),
      ],
    );
  }
}

class _ProgressChartPainter extends CustomPainter {
  final List<double> scores;
  final List<DateTime> dates;
  final double minScore;
  final double maxScore;

  _ProgressChartPainter({
    required this.scores,
    required this.dates,
    required this.minScore,
    required this.maxScore,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (scores.isEmpty) return;

    final paint = Paint()
      ..color = Colors.blue
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke;

    final fillPaint = Paint()
      ..color = Colors.blue.withOpacity(0.1)
      ..style = PaintingStyle.fill;

    final pointPaint = Paint()
      ..color = Colors.blue
      ..style = PaintingStyle.fill;

    final scoreRange = maxScore - minScore;
    final padding = 40.0;
    final chartWidth = size.width - padding * 2;
    final chartHeight = size.height - padding * 2;

    final points = <Offset>[];
    for (int i = 0; i < scores.length; i++) {
      final x = padding + (chartWidth / (scores.length - 1)) * i;
      final normalizedScore = (scores[i] - minScore) / scoreRange;
      final y = padding + chartHeight - (normalizedScore * chartHeight);
      points.add(Offset(x, y));
    }

    // Draw filled area
    if (points.length > 1) {
      final path = Path();
      path.moveTo(points.first.dx, size.height - padding);
      for (final point in points) {
        path.lineTo(point.dx, point.dy);
      }
      path.lineTo(points.last.dx, size.height - padding);
      path.close();
      canvas.drawPath(path, fillPaint);
    }

    // Draw line
    if (points.length > 1) {
      final path = Path();
      path.moveTo(points.first.dx, points.first.dy);
      for (int i = 1; i < points.length; i++) {
        path.lineTo(points[i].dx, points[i].dy);
      }
      canvas.drawPath(path, paint);
    }

    // Draw points
    for (final point in points) {
      canvas.drawCircle(point, 5, pointPaint);
    }

    // Draw grid lines and labels
    final gridPaint = Paint()
      ..color = Colors.grey[300]!
      ..strokeWidth = 1;

    final textPainter = TextPainter(
      textDirection: TextDirection.ltr,
    );

    // Y-axis labels
    for (int i = 0; i <= 4; i++) {
      final score = minScore + (scoreRange / 4) * i;
      final y = padding + chartHeight - (i / 4) * chartHeight;
      canvas.drawLine(
        Offset(padding, y),
        Offset(size.width - padding, y),
        gridPaint,
      );
      textPainter.text = TextSpan(
        text: score.toStringAsFixed(0),
        style: TextStyle(
          color: Colors.grey[600],
          fontSize: 10,
        ),
      );
      textPainter.layout();
      textPainter.paint(
        canvas,
        Offset(0, y - textPainter.height / 2),
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

