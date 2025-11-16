/// Model for tracking farmer/seller ratings and statistics
class FarmerRating {
  final String farmerId; // Farmer's user ID
  final String farmerName; // Farmer's name
  final double averageRating; // Average rating (1-5)
  final int totalRatings; // Total number of ratings received
  final int totalOrders; // Total completed orders
  final int totalDeliveries; // Total successful deliveries
  final List<int>
  ratingDistribution; // [1-star count, 2-star, 3-star, 4-star, 5-star]
  final DateTime? lastRatedAt; // When last rating was received
  final DateTime updatedAt; // Last update time

  FarmerRating({
    required this.farmerId,
    required this.farmerName,
    this.averageRating = 0.0,
    this.totalRatings = 0,
    this.totalOrders = 0,
    this.totalDeliveries = 0,
    List<int>? ratingDistribution,
    this.lastRatedAt,
    required this.updatedAt,
  }) : ratingDistribution = ratingDistribution ?? [0, 0, 0, 0, 0];

  /// Create from Firestore document
  factory FarmerRating.fromFirestore(Map<String, dynamic> data, String id) {
    DateTime? parseDateTime(dynamic value) {
      if (value == null) return null;
      if (value is DateTime) return value;
      if (value is String) return DateTime.parse(value);
      if (value.runtimeType.toString().contains('Timestamp')) {
        return (value as dynamic).toDate();
      }
      return null;
    }

    return FarmerRating(
      farmerId: id,
      farmerName: data['farmer_name'] ?? '',
      averageRating: (data['average_rating'] ?? 0.0).toDouble(),
      totalRatings: data['total_ratings'] ?? 0,
      totalOrders: data['total_orders'] ?? 0,
      totalDeliveries: data['total_deliveries'] ?? 0,
      ratingDistribution:
          (data['rating_distribution'] as List<dynamic>?)
              ?.map((e) => e as int)
              .toList() ??
          [0, 0, 0, 0, 0],
      lastRatedAt: parseDateTime(data['last_rated_at']),
      updatedAt: parseDateTime(data['updated_at']) ?? DateTime.now(),
    );
  }

  /// Convert to Firestore map
  Map<String, dynamic> toFirestore() {
    return {
      'farmer_name': farmerName,
      'average_rating': averageRating,
      'total_ratings': totalRatings,
      'total_orders': totalOrders,
      'total_deliveries': totalDeliveries,
      'rating_distribution': ratingDistribution,
      'last_rated_at': lastRatedAt?.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  /// Get rating percentage for a specific star count (1-5)
  double getRatingPercentage(int starCount) {
    if (totalRatings == 0) return 0.0;
    if (starCount < 1 || starCount > 5) return 0.0;
    return (ratingDistribution[starCount - 1] / totalRatings) * 100;
  }

  /// Check if farmer is highly rated (>= 4.0 stars)
  bool get isHighlyRated => averageRating >= 4.0;

  /// Check if farmer has sufficient ratings (>= 5 ratings)
  bool get hasSufficientRatings => totalRatings >= 5;

  /// Get rating quality description
  String get ratingQuality {
    if (averageRating >= 4.5) return 'Excellent';
    if (averageRating >= 4.0) return 'Very Good';
    if (averageRating >= 3.5) return 'Good';
    if (averageRating >= 3.0) return 'Average';
    if (averageRating >= 2.0) return 'Below Average';
    return 'Poor';
  }
}
