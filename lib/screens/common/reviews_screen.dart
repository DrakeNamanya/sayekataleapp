import 'package:flutter/material.dart';
import '../../models/review.dart';
import '../../services/rating_service.dart';
import '../../utils/app_theme.dart';
import '../../widgets/star_rating_widget.dart';
import '../../widgets/rating_breakdown_chart.dart';
import '../../widgets/review_card.dart';

/// Screen to display all reviews for a farmer or product
class ReviewsScreen extends StatefulWidget {
  final String? farmerId;
  final String? productId;
  final String title;

  const ReviewsScreen({
    super.key,
    this.farmerId,
    this.productId,
    required this.title,
  }) : assert(farmerId != null || productId != null,
            'Either farmerId or productId must be provided');

  @override
  State<ReviewsScreen> createState() => _ReviewsScreenState();
}

class _ReviewsScreenState extends State<ReviewsScreen> {
  final RatingService _ratingService = RatingService();
  List<Review> _reviews = [];
  List<Review> _filteredReviews = [];
  bool _isLoading = true;
  
  // Filter and sort options
  int? _minRatingFilter;
  String _sortBy = 'recent'; // 'recent', 'highest', 'lowest'

  @override
  void initState() {
    super.initState();
    _loadReviews();
  }

  Future<void> _loadReviews() async {
    setState(() {
      _isLoading = true;
    });

    try {
      List<Review> reviews;
      
      if (widget.farmerId != null) {
        reviews = await _ratingService.getFarmerReviews(
          widget.farmerId!,
          limit: 1000,
        );
      } else {
        reviews = await _ratingService.getProductReviews(
          widget.productId!,
          limit: 1000,
        );
      }

      setState(() {
        _reviews = reviews;
        _applyFiltersAndSort();
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _applyFiltersAndSort() {
    // Apply rating filter
    var filtered = _reviews;
    if (_minRatingFilter != null) {
      filtered = filtered.where((r) => r.rating >= _minRatingFilter!).toList();
    }

    // Apply sorting
    switch (_sortBy) {
      case 'recent':
        filtered.sort((a, b) => b.createdAt.compareTo(a.createdAt));
        break;
      case 'highest':
        filtered.sort((a, b) => b.rating.compareTo(a.rating));
        break;
      case 'lowest':
        filtered.sort((a, b) => a.rating.compareTo(b.rating));
        break;
    }

    setState(() {
      _filteredReviews = filtered;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: _showFilterBottomSheet,
          ),
        ],
      ),
      body: SafeArea(
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _buildContent(),
      ),
    );
  }

  Widget _buildContent() {
    if (_reviews.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.rate_review_outlined,
              size: 80,
              color: Colors.grey.shade400,
            ),
            const SizedBox(height: 16),
            Text(
              'No reviews yet',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: AppTheme.textSecondary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Be the first to leave a review!',
              style: TextStyle(
                fontSize: 14,
                color: AppTheme.textSecondary,
              ),
            ),
          ],
        ),
      );
    }

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Rating breakdown chart
          if (widget.farmerId != null)
            FutureBuilder(
              future: _ratingService.getFarmerRating(widget.farmerId!),
              builder: (context, snapshot) {
                if (snapshot.hasData && snapshot.data != null) {
                  return Padding(
                    padding: const EdgeInsets.all(16),
                    child: RatingBreakdownChart(rating: snapshot.data!),
                  );
                }
                return const SizedBox.shrink();
              },
            ),

          // Filter/Sort indicator
          if (_minRatingFilter != null || _sortBy != 'recent')
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              color: AppTheme.primaryColor.withValues(alpha: 0.1),
              child: Row(
                children: [
                  Icon(
                    Icons.filter_list,
                    size: 16,
                    color: AppTheme.primaryColor,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _buildFilterText(),
                      style: const TextStyle(
                        fontSize: 13,
                        color: AppTheme.primaryColor,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  TextButton(
                    onPressed: () {
                      setState(() {
                        _minRatingFilter = null;
                        _sortBy = 'recent';
                        _applyFiltersAndSort();
                      });
                    },
                    child: const Text('Clear'),
                  ),
                ],
              ),
            ),

          // Reviews count
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              '${_filteredReviews.length} ${_filteredReviews.length == 1 ? 'Review' : 'Reviews'}',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),

          // Reviews list
          if (_filteredReviews.isEmpty)
            Center(
              child: Padding(
                padding: const EdgeInsets.all(32.0),
                child: Column(
                  children: [
                    Icon(
                      Icons.filter_alt_off_outlined,
                      size: 64,
                      color: Colors.grey.shade400,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'No reviews match your filters',
                      style: TextStyle(
                        fontSize: 16,
                        color: AppTheme.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextButton(
                      onPressed: () {
                        setState(() {
                          _minRatingFilter = null;
                          _sortBy = 'recent';
                          _applyFiltersAndSort();
                        });
                      },
                      child: const Text('Clear filters'),
                    ),
                  ],
                ),
              ),
            )
          else
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: _filteredReviews.length,
              itemBuilder: (context, index) {
                return ReviewCard(review: _filteredReviews[index]);
              },
            ),

          const SizedBox(height: 24),
        ],
      ),
    );
  }

  String _buildFilterText() {
    final parts = <String>[];
    
    if (_minRatingFilter != null) {
      parts.add('$_minRatingFilter+ stars');
    }
    
    if (_sortBy != 'recent') {
      parts.add('Sorted by ${_sortBy == 'highest' ? 'Highest' : 'Lowest'} rating');
    }
    
    return parts.isEmpty ? 'Filtered' : parts.join(' • ');
  }

  void _showFilterBottomSheet() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Filter & Sort Reviews',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Filter by rating
              const Text(
                'Minimum Rating',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                children: [null, 5, 4, 3, 2, 1].map((rating) {
                  final isSelected = _minRatingFilter == rating;
                  return ChoiceChip(
                    label: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (rating != null) ...[
                          Text('$rating'),
                          const SizedBox(width: 4),
                          const Icon(Icons.star, size: 16, color: Colors.amber),
                          const SizedBox(width: 4),
                          const Text('+'),
                        ] else
                          const Text('All'),
                      ],
                    ),
                    selected: isSelected,
                    onSelected: (selected) {
                      setModalState(() {
                        _minRatingFilter = selected ? rating : null;
                      });
                    },
                    selectedColor: AppTheme.primaryColor.withValues(alpha: 0.2),
                    labelStyle: TextStyle(
                      color: isSelected ? AppTheme.primaryColor : AppTheme.textPrimary,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                    ),
                  );
                }).toList(),
              ),

              const SizedBox(height: 24),

              // Sort by
              const Text(
                'Sort By',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 12),
              RadioListTile<String>(
                title: const Text('Most Recent'),
                value: 'recent',
                groupValue: _sortBy,
                onChanged: (value) {
                  setModalState(() {
                    _sortBy = value!;
                  });
                },
                activeColor: AppTheme.primaryColor,
              ),
              RadioListTile<String>(
                title: const Text('Highest Rating'),
                value: 'highest',
                groupValue: _sortBy,
                onChanged: (value) {
                  setModalState(() {
                    _sortBy = value!;
                  });
                },
                activeColor: AppTheme.primaryColor,
              ),
              RadioListTile<String>(
                title: const Text('Lowest Rating'),
                value: 'lowest',
                groupValue: _sortBy,
                onChanged: (value) {
                  setModalState(() {
                    _sortBy = value!;
                  });
                },
                activeColor: AppTheme.primaryColor,
              ),

              const SizedBox(height: 24),

              // Apply button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    setState(() {
                      _applyFiltersAndSort();
                    });
                    Navigator.pop(context);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryColor,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: const Text(
                    'Apply Filters',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }
}
