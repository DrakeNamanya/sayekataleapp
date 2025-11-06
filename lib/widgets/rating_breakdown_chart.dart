import 'package:flutter/material.dart';
import '../models/farmer_rating.dart';
import '../utils/app_theme.dart';

/// Widget to display rating breakdown with horizontal bars
class RatingBreakdownChart extends StatelessWidget {
  final FarmerRating rating;
  
  const RatingBreakdownChart({
    super.key,
    required this.rating,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Rating Breakdown',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        
        // Overall rating summary
        Row(
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  rating.averageRating.toStringAsFixed(1),
                  style: const TextStyle(
                    fontSize: 48,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.primaryColor,
                  ),
                ),
                Row(
                  children: List.generate(5, (index) {
                    return Icon(
                      index < rating.averageRating.floor()
                          ? Icons.star
                          : (index < rating.averageRating
                              ? Icons.star_half
                              : Icons.star_border),
                      color: Colors.amber,
                      size: 24,
                    );
                  }),
                ),
                const SizedBox(height: 4),
                Text(
                  '${rating.totalRatings} reviews',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ],
        ),
        
        const SizedBox(height: 24),
        
        // Rating bars (5-star to 1-star)
        ...List.generate(5, (index) {
          final starCount = 5 - index;  // Start from 5-star
          return _buildRatingBar(
            context,
            starCount,
            rating.ratingDistribution[starCount - 1],
            rating.totalRatings,
          );
        }),
      ],
    );
  }

  Widget _buildRatingBar(
    BuildContext context,
    int starCount,
    int count,
    int total,
  ) {
    final percentage = total > 0 ? (count / total) * 100 : 0.0;
    
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          // Star label
          SizedBox(
            width: 50,
            child: Row(
              children: [
                Text(
                  '$starCount',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(width: 4),
                const Icon(Icons.star, size: 16, color: Colors.amber),
              ],
            ),
          ),
          
          // Progress bar
          Expanded(
            child: Stack(
              children: [
                // Background
                Container(
                  height: 8,
                  decoration: BoxDecoration(
                    color: Colors.grey[200],
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                // Foreground (filled portion)
                FractionallySizedBox(
                  widthFactor: percentage / 100,
                  child: Container(
                    height: 8,
                    decoration: BoxDecoration(
                      color: AppTheme.primaryColor,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ),
              ],
            ),
          ),
          
          // Count and percentage
          SizedBox(
            width: 60,
            child: Text(
              '${percentage.toStringAsFixed(0)}% ($count)',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
              ),
              textAlign: TextAlign.end,
            ),
          ),
        ],
      ),
    );
  }
}
