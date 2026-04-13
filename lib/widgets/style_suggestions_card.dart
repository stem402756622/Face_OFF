import 'package:flutter/material.dart';
import '../models/style_suggestions.dart';

class StyleSuggestionsCard extends StatelessWidget {
  final StyleSuggestions styleSuggestions;

  const StyleSuggestionsCard({
    super.key,
    required this.styleSuggestions,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
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
            blurRadius: 20,
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
                      Colors.purple[600]!,
                    ],
                  ),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Icon(
                  Icons.style,
                  color: Colors.white,
                  size: 28,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Style & Enhancement Suggestions',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.purple[100],
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        'Face Shape: ${styleSuggestions.faceShape}',
                        style: TextStyle(
                          color: Colors.purple[800],
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          if (styleSuggestions.overallRecommendation.isNotEmpty) ...[
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.7),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Text(
                styleSuggestions.overallRecommendation,
                style: TextStyle(
                  fontSize: 15,
                  color: Colors.grey[800],
                  height: 1.6,
                ),
              ),
            ),
            const SizedBox(height: 20),
          ],
          _buildSuggestionSection(
            'Hairstyles',
            Icons.content_cut,
            styleSuggestions.hairstyles,
            Colors.blue,
          ),
          const SizedBox(height: 16),
          _buildSuggestionSection(
            'Skincare Routine',
            Icons.spa,
            styleSuggestions.skincareRoutine,
            Colors.green,
          ),
          const SizedBox(height: 16),
          _buildSuggestionSection(
            'Makeup Techniques',
            Icons.face,
            styleSuggestions.makeupTechniques,
            Colors.pink,
          ),
          const SizedBox(height: 16),
          _buildSuggestionSection(
            'Grooming Habits',
            Icons.check_circle_outline,
            styleSuggestions.groomingHabits,
            Colors.orange,
          ),
        ],
      ),
    );
  }

  Widget _buildSuggestionSection(
    String title,
    IconData icon,
    List<String> suggestions,
    Color color,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(width: 8),
            Text(
              title,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.grey[800],
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        ...suggestions.map((suggestion) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  margin: const EdgeInsets.only(top: 6, right: 12),
                  width: 6,
                  height: 6,
                  decoration: BoxDecoration(
                    color: color,
                    shape: BoxShape.circle,
                  ),
                ),
                Expanded(
                  child: Text(
                    suggestion,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[700],
                      height: 1.5,
                    ),
                  ),
                ),
              ],
            ),
          );
        }),
      ],
    );
  }
}

