import 'package:flutter/material.dart';
import 'package:timeago/timeago.dart' as timeago;
import '../models/review.dart';
import '../utils/app_theme.dart';
import 'star_rating_widget.dart';

/// Widget to display a single review in a card format
class ReviewCard extends StatelessWidget {
  final Review review;
  final bool showFarmerName;
  final VoidCallback? onTap;

  const ReviewCard({
    super.key,
    required this.review,
    this.showFarmerName = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header: User info and rating
              Row(
                children: [
                  // User avatar
                  CircleAvatar(
                    radius: 20,
                    backgroundColor: AppTheme.primaryColor.withValues(alpha: 0.1),
                    child: Text(
                      review.userName.isNotEmpty
                          ? review.userName[0].toUpperCase()
                          : '?',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: AppTheme.primaryColor,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  // User name and date
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          review.userName,
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 15,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          timeago.format(review.createdAt),
                          style: TextStyle(
                            fontSize: 12,
                            color: AppTheme.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Rating stars
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      StarRatingWidget(
                        rating: review.rating,
                        size: 16,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        review.rating.toStringAsFixed(1),
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.primaryColor,
                        ),
                      ),
                    ],
                  ),
                ],
              ),

              // Comment
              if (review.comment != null && review.comment!.isNotEmpty) ...[
                const SizedBox(height: 12),
                Text(
                  review.comment!,
                  style: const TextStyle(
                    fontSize: 14,
                    height: 1.5,
                    color: AppTheme.textPrimary,
                  ),
                ),
              ],

              // Photos
              if (review.hasPhotos) ...[
                const SizedBox(height: 12),
                _buildPhotoGrid(),
              ],

              // Order ID footer
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(
                    Icons.receipt_long_outlined,
                    size: 14,
                    color: AppTheme.textSecondary,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    'Order #${review.orderId.substring(0, 8)}',
                    style: TextStyle(
                      fontSize: 11,
                      color: AppTheme.textSecondary,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPhotoGrid() {
    final photoCount = review.photoUrls.length;
    final displayCount = photoCount > 4 ? 3 : photoCount;

    return SizedBox(
      height: 80,
      child: Row(
        children: [
          ...List.generate(displayCount, (index) {
            return Padding(
              padding: const EdgeInsets.only(right: 8),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  width: 80,
                  height: 80,
                  color: Colors.grey.shade200,
                  child: Image.network(
                    review.photoUrls[index],
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return Center(
                        child: Icon(
                          Icons.image_outlined,
                          color: Colors.grey.shade400,
                        ),
                      );
                    },
                  ),
                ),
              ),
            );
          }),
          if (photoCount > 4)
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.7),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Center(
                child: Text(
                  '+${photoCount - 3}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// Compact version of review card for lists
class ReviewCardCompact extends StatelessWidget {
  final Review review;
  final VoidCallback? onTap;

  const ReviewCardCompact({
    super.key,
    required this.review,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      elevation: 0,
      color: Colors.grey.shade50,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              // Rating
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppTheme.primaryColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.star,
                      size: 14,
                      color: Colors.amber,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      review.rating.toStringAsFixed(1),
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              // Content
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      review.userName,
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                      ),
                    ),
                    if (review.comment != null && review.comment!.isNotEmpty)
                      Text(
                        review.comment!,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 12,
                          color: AppTheme.textSecondary,
                        ),
                      ),
                  ],
                ),
              ),
              // Time
              Text(
                timeago.format(review.createdAt),
                style: TextStyle(
                  fontSize: 11,
                  color: AppTheme.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
