import 'package:flutter/material.dart';
import '../models/face_analysis_result.dart';

class AnalysisSourceBadge extends StatelessWidget {
  final AnalysisSource source;

  const AnalysisSourceBadge({super.key, required this.source});

  @override
  Widget build(BuildContext context) {
    Color backgroundColor;
    Color textColor;
    IconData icon;
    String label;

    switch (source) {
      case AnalysisSource.api:
        backgroundColor = Colors.green[100]!;
        textColor = Colors.green[800]!;
        icon = Icons.cloud_done;
        label = 'Cloud Analysis';
        break;
      case AnalysisSource.cached:
        backgroundColor = Colors.blue[100]!;
        textColor = Colors.blue[800]!;
        icon = Icons.cached;
        label = 'Cached';
        break;
      case AnalysisSource.localML:
        backgroundColor = Colors.purple[100]!;
        textColor = Colors.purple[800]!;
        icon = Icons.psychology;
        label = 'Local ML';
        break;
      case AnalysisSource.simulated:
        backgroundColor = Colors.orange[100]!;
        textColor = Colors.orange[800]!;
        icon = Icons.auto_awesome;
        label = 'Simulated';
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: textColor.withOpacity(0.3), width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: textColor),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              color: textColor,
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}

