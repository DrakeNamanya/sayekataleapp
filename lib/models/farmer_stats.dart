/// Enhanced farmer statistics for seller profiles
class FarmerStats {
  final String farmerId;
  final int totalProducts;
  final int activeProducts;
  final int totalOrders;
  final int completedOrders;
  final int totalReviews;
  final double averageRating;
  final double fulfillmentRate;  // Percentage of orders fulfilled
  final double responseTime;     // Average response time in hours
  final DateTime memberSince;
  final String? bio;
  final List<String> specialties;
  final bool isVerified;
  final bool isTopSeller;
  final Map<String, int> categoryCounts;  // Product count by category

  FarmerStats({
    required this.farmerId,
    this.totalProducts = 0,
    this.activeProducts = 0,
    this.totalOrders = 0,
    this.completedOrders = 0,
    this.totalReviews = 0,
    this.averageRating = 0.0,
    this.fulfillmentRate = 0.0,
    this.responseTime = 0.0,
    required this.memberSince,
    this.bio,
    this.specialties = const [],
    this.isVerified = false,
    this.isTopSeller = false,
    this.categoryCounts = const {},
  });

  /// Check if farmer is highly active (>= 10 products)
  bool get isHighlyActive => totalProducts >= 10;

  /// Check if farmer is reliable (>= 90% fulfillment)
  bool get isReliable => fulfillmentRate >= 90.0;

  /// Check if farmer has excellent rating (>= 4.5 stars)
  bool get hasExcellentRating => averageRating >= 4.5;

  /// Check if farmer responds quickly (< 24 hours)
  bool get respondsQuickly => responseTime < 24.0;

  /// Get member duration in days
  int get memberDurationDays {
    return DateTime.now().difference(memberSince).inDays;
  }

  /// Get member duration description
  String get memberDurationDescription {
    final days = memberDurationDays;
    if (days < 30) return '$days days';
    if (days < 365) return '${(days / 30).floor()} months';
    return '${(days / 365).floor()} years';
  }

  /// Get seller badges
  List<SellerBadge> get badges {
    final List<SellerBadge> result = [];
    
    if (isVerified) {
      result.add(SellerBadge(
        title: 'Verified Seller',
        icon: 'verified',
        color: '0xFF4CAF50',
      ));
    }
    
    if (isTopSeller) {
      result.add(SellerBadge(
        title: 'Top Seller',
        icon: 'star',
        color: '0xFFFFC107',
      ));
    }
    
    if (respondsQuickly) {
      result.add(SellerBadge(
        title: 'Fast Response',
        icon: 'bolt',
        color: '0xFF2196F3',
      ));
    }
    
    if (isReliable) {
      result.add(SellerBadge(
        title: 'Reliable',
        icon: 'check_circle',
        color: '0xFF4CAF50',
      ));
    }
    
    return result;
  }

  factory FarmerStats.fromFirestore(Map<String, dynamic> data, String id) {
    return FarmerStats(
      farmerId: id,
      totalProducts: data['total_products'] ?? 0,
      activeProducts: data['active_products'] ?? 0,
      totalOrders: data['total_orders'] ?? 0,
      completedOrders: data['completed_orders'] ?? 0,
      totalReviews: data['total_reviews'] ?? 0,
      averageRating: (data['average_rating'] ?? 0.0).toDouble(),
      fulfillmentRate: (data['fulfillment_rate'] ?? 0.0).toDouble(),
      responseTime: (data['response_time'] ?? 0.0).toDouble(),
      memberSince: DateTime.parse(data['member_since'] ?? DateTime.now().toIso8601String()),
      bio: data['bio'],
      specialties: List<String>.from(data['specialties'] ?? []),
      isVerified: data['is_verified'] ?? false,
      isTopSeller: data['is_top_seller'] ?? false,
      categoryCounts: Map<String, int>.from(data['category_counts'] ?? {}),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'total_products': totalProducts,
      'active_products': activeProducts,
      'total_orders': totalOrders,
      'completed_orders': completedOrders,
      'total_reviews': totalReviews,
      'average_rating': averageRating,
      'fulfillment_rate': fulfillmentRate,
      'response_time': responseTime,
      'member_since': memberSince.toIso8601String(),
      'bio': bio,
      'specialties': specialties,
      'is_verified': isVerified,
      'is_top_seller': isTopSeller,
      'category_counts': categoryCounts,
    };
  }
}

/// Seller badge model
class SellerBadge {
  final String title;
  final String icon;
  final String color;  // Hex color string

  SellerBadge({
    required this.title,
    required this.icon,
    required this.color,
  });
}
