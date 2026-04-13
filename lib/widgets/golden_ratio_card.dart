import 'package:flutter/material.dart';
import '../models/face_analysis_result.dart';

class GoldenRatioCard extends StatelessWidget {
  final FaceAnalysisResult faceAnalysis;

  const GoldenRatioCard({
    super.key,
    required this.faceAnalysis,
  });

  @override
  Widget build(BuildContext context) {
    final measurements = faceAnalysis.goldenRatioMeasurements;
    final details = faceAnalysis.featureDetails;
    
    if (measurements.isEmpty && details.isEmpty) {
      return const SizedBox.shrink();
    }

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.white,
            Colors.amber[50]!,
          ],
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.amber.withOpacity(0.15),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
        border: Border.all(
          color: Colors.amber.withOpacity(0.2),
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
                      Colors.amber[400]!,
                      Colors.amber[600]!,
                    ],
                  ),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Icon(
                  Icons.auto_awesome,
                  color: Colors.white,
                  size: 28,
                ),
              ),
              const SizedBox(width: 16),
              const Expanded(
                child: Text(
                  'Golden Ratio Analysis',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          if (details.containsKey('goldenRatioCompliance')) ...[
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.7),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Text(
                details['goldenRatioCompliance']!,
                style: TextStyle(
                  fontSize: 15,
                  color: Colors.grey[800],
                  height: 1.6,
                ),
              ),
            ),
            const SizedBox(height: 20),
          ],
          if (details.containsKey('eyeSpacing')) ...[
            _buildDetailItem('Eye Spacing', details['eyeSpacing']!, Icons.remove_red_eye),
            const SizedBox(height: 12),
          ],
          if (details.containsKey('noseShape')) ...[
            _buildDetailItem('Nose Shape', details['noseShape']!, Icons.face),
            const SizedBox(height: 12),
          ],
          if (details.containsKey('jawlineDefinition')) ...[
            _buildDetailItem('Jawline Definition', details['jawlineDefinition']!, Icons.straighten),
            const SizedBox(height: 12),
          ],
          if (details.containsKey('lipBalance')) ...[
            _buildDetailItem('Lip Balance', details['lipBalance']!, Icons.favorite),
          ],
        ],
      ),
    );
  }

  Widget _buildDetailItem(String title, String description, IconData icon) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.amber[100],
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: Colors.amber[800], size: 20),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey[800],
                ),
              ),
              const SizedBox(height: 4),
              Text(
                description,
                style: TextStyle(
                  fontSize: 13,
                  color: Colors.grey[700],
                  height: 1.5,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

