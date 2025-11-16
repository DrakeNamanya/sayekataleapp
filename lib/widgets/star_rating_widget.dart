import 'package:flutter/material.dart';

/// Reusable star rating widget with interactive and read-only modes
///
/// Usage:
/// ```dart
/// // Read-only display
/// StarRatingWidget(
///   rating: 4.5,
///   size: 20,
/// )
///
/// // Interactive rating input
/// StarRatingWidget.interactive(
///   initialRating: 3.0,
///   onRatingChanged: (rating) => print('New rating: $rating'),
///   size: 32,
/// )
/// ```
class StarRatingWidget extends StatefulWidget {
  final double rating;
  final ValueChanged<double>? onRatingChanged;
  final double size;
  final Color color;
  final bool interactive;
  final bool allowHalfStars;
  final int starCount;
  final MainAxisSize mainAxisSize;
  final MainAxisAlignment mainAxisAlignment;

  /// Create a read-only star rating display
  const StarRatingWidget({
    super.key,
    required this.rating,
    this.size = 20,
    this.color = Colors.amber,
    this.starCount = 5,
    this.mainAxisSize = MainAxisSize.min,
    this.mainAxisAlignment = MainAxisAlignment.start,
  }) : interactive = false,
       onRatingChanged = null,
       allowHalfStars = true;

  /// Create an interactive star rating input
  const StarRatingWidget.interactive({
    super.key,
    required double initialRating,
    required this.onRatingChanged,
    this.size = 32,
    this.color = Colors.amber,
    this.allowHalfStars = false,
    this.starCount = 5,
    this.mainAxisSize = MainAxisSize.min,
    this.mainAxisAlignment = MainAxisAlignment.center,
  }) : rating = initialRating,
       interactive = true;

  @override
  State<StarRatingWidget> createState() => _StarRatingWidgetState();
}

class _StarRatingWidgetState extends State<StarRatingWidget> {
  late double _currentRating;

  @override
  void initState() {
    super.initState();
    _currentRating = widget.rating;
  }

  @override
  void didUpdateWidget(StarRatingWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.rating != widget.rating) {
      _currentRating = widget.rating;
    }
  }

  void _handleTap(int starIndex) {
    if (!widget.interactive || widget.onRatingChanged == null) return;

    setState(() {
      _currentRating = (starIndex + 1).toDouble();
    });
    widget.onRatingChanged!(_currentRating);
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: widget.mainAxisSize,
      mainAxisAlignment: widget.mainAxisAlignment,
      children: List.generate(widget.starCount, (index) {
        return widget.interactive
            ? _buildInteractiveStar(index)
            : _buildReadOnlyStar(index);
      }),
    );
  }

  Widget _buildReadOnlyStar(int index) {
    final starValue = index + 1;
    IconData iconData;

    if (widget.allowHalfStars) {
      // Half-star support for read-only mode
      if (starValue <= _currentRating.floor()) {
        iconData = Icons.star;
      } else if (starValue <= _currentRating) {
        iconData = Icons.star_half;
      } else {
        iconData = Icons.star_border;
      }
    } else {
      // Full stars only
      iconData = starValue <= _currentRating.round()
          ? Icons.star
          : Icons.star_border;
    }

    return Icon(iconData, color: widget.color, size: widget.size);
  }

  Widget _buildInteractiveStar(int index) {
    final starValue = index + 1;
    final isFilled = starValue <= _currentRating;

    return GestureDetector(
      onTap: () => _handleTap(index),
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: widget.size * 0.05),
        child: Icon(
          isFilled ? Icons.star : Icons.star_border,
          color: widget.color,
          size: widget.size,
        ),
      ),
    );
  }
}

/// Extension methods for star rating utilities
extension StarRatingExtension on double {
  /// Get rating quality text based on value
  String get ratingQuality {
    if (this >= 4.5) return 'Excellent';
    if (this >= 4.0) return 'Very Good';
    if (this >= 3.5) return 'Good';
    if (this >= 3.0) return 'Average';
    if (this >= 2.0) return 'Below Average';
    return 'Poor';
  }

  /// Get rating color based on value
  Color get ratingColor {
    if (this >= 4.0) return Colors.green;
    if (this >= 3.0) return Colors.orange;
    return Colors.red;
  }
}
