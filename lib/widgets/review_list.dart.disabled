import 'package:flutter/material.dart';
import '../models/review.dart';
import '../services/rating_service.dart';
import '../utils/app_theme.dart';
import 'review_card.dart';

/// Widget to display a paginated list of reviews
class ReviewList extends StatefulWidget {
  final String? farmerId;
  final String? productId;
  final int? minRating;
  final bool compact;
  final int itemsPerPage;

  const ReviewList({
    super.key,
    this.farmerId,
    this.productId,
    this.minRating,
    this.compact = false,
    this.itemsPerPage = 10,
  }) : assert(farmerId != null || productId != null, 'Either farmerId or productId must be provided');

  @override
  State<ReviewList> createState() => _ReviewListState();
}

class _ReviewListState extends State<ReviewList> {
  final RatingService _ratingService = RatingService();
  final List<Review> _reviews = [];
  bool _isLoading = true;
  bool _hasMore = true;
  int _currentPage = 0;

  @override
  void initState() {
    super.initState();
    _loadReviews();
  }

  Future<void> _loadReviews() async {
    if (!_hasMore || _isLoading) return;

    setState(() {
      _isLoading = true;
    });

    try {
      List<Review> newReviews;
      
      if (widget.farmerId != null) {
        newReviews = await _ratingService.getFarmerReviews(
          widget.farmerId!,
          limit: widget.itemsPerPage,
          minRating: widget.minRating,
        );
      } else {
        newReviews = await _ratingService.getProductReviews(
          widget.productId!,
          limit: widget.itemsPerPage,
          minRating: widget.minRating,
        );
      }

      setState(() {
        if (newReviews.isEmpty) {
          _hasMore = false;
        } else {
          _reviews.addAll(newReviews);
          _currentPage++;
          if (newReviews.length < widget.itemsPerPage) {
            _hasMore = false;
          }
        }
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _hasMore = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading && _reviews.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(32.0),
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (_reviews.isEmpty) {
      return _buildEmptyState();
    }

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: _reviews.length + (_hasMore ? 1 : 0),
      itemBuilder: (context, index) {
        // Show loading indicator at the end
        if (index == _reviews.length) {
          return _buildLoadMoreButton();
        }

        final review = _reviews[index];
        return widget.compact
            ? ReviewCardCompact(review: review)
            : ReviewCard(review: review);
      },
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.rate_review_outlined,
              size: 64,
              color: Colors.grey.shade400,
            ),
            const SizedBox(height: 16),
            Text(
              'No reviews yet',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: AppTheme.textSecondary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              widget.minRating != null
                  ? 'No reviews with ${widget.minRating}+ stars'
                  : 'Be the first to leave a review!',
              style: TextStyle(
                fontSize: 14,
                color: AppTheme.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoadMoreButton() {
    if (_isLoading) {
      return const Padding(
        padding: EdgeInsets.all(16.0),
        child: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Center(
        child: OutlinedButton(
          onPressed: _loadReviews,
          style: OutlinedButton.styleFrom(
            foregroundColor: AppTheme.primaryColor,
            side: BorderSide(color: AppTheme.primaryColor),
          ),
          child: const Text('Load More Reviews'),
        ),
      ),
    );
  }
}

/// Widget to display review statistics summary
class ReviewStatsSummary extends StatelessWidget {
  final String farmerId;
  final RatingService ratingService = RatingService();

  ReviewStatsSummary({
    super.key,
    required this.farmerId,
  });

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Map<String, dynamic>>(
      future: ratingService.getFarmerReviewStats(farmerId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(16.0),
              child: CircularProgressIndicator(),
            ),
          );
        }

        if (snapshot.hasError || !snapshot.hasData) {
          return const SizedBox.shrink();
        }

        final stats = snapshot.data!;
        final totalReviews = stats['total_reviews'] as int;
        final averageRating = stats['average_rating'] as double;
        final withPhotos = stats['with_photos'] as int;
        final withComments = stats['with_comments'] as int;

        if (totalReviews == 0) {
          return const SizedBox.shrink();
        }

        return Card(
          margin: const EdgeInsets.symmetric(vertical: 12),
          elevation: 0,
          color: Colors.grey.shade50,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(color: Colors.grey.shade200),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildStatItem(
                  Icons.star,
                  averageRating.toStringAsFixed(1),
                  'Average',
                  Colors.amber,
                ),
                _buildStatItem(
                  Icons.rate_review_outlined,
                  totalReviews.toString(),
                  'Reviews',
                  AppTheme.primaryColor,
                ),
                _buildStatItem(
                  Icons.photo_library_outlined,
                  withPhotos.toString(),
                  'Photos',
                  AppTheme.secondaryColor,
                ),
                _buildStatItem(
                  Icons.comment_outlined,
                  withComments.toString(),
                  'Comments',
                  AppTheme.accentColor,
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildStatItem(IconData icon, String value, String label, Color color) {
    return Column(
      children: [
        Icon(icon, color: color, size: 28),
        const SizedBox(height: 8),
        Text(
          value,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: AppTheme.textPrimary,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: AppTheme.textSecondary,
          ),
        ),
      ],
    );
  }
}
