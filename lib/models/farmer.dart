import 'product.dart';
import 'user.dart';

/// Farmer model representing SHG (farmer) users with their products and ratings
class Farmer {
  final String id;
  final String name;
  final String phone;
  final String? profileImage;
  final Location? location;
  final double rating;
  final int totalReviews;
  final int totalOrders;
  final List<Product> products;
  final bool isVerified;
  final DateTime joinedDate;

  Farmer({
    required this.id,
    required this.name,
    required this.phone,
    this.profileImage,
    this.location,
    this.rating = 0.0,
    this.totalReviews = 0,
    this.totalOrders = 0,
    this.products = const [],
    this.isVerified = false,
    required this.joinedDate,
  });

  /// Get distance from another location (in kilometers)
  double? getDistanceFrom(Location? otherLocation) {
    if (location == null || otherLocation == null) return null;
    return location!.distanceTo(otherLocation);
  }

  /// Get formatted distance string
  String getDistanceText(Location? otherLocation) {
    final distance = getDistanceFrom(otherLocation);
    if (distance == null) return 'Distance unknown';

    if (distance < 1) {
      return '${(distance * 1000).toStringAsFixed(0)}m away';
    } else {
      return '${distance.toStringAsFixed(1)}km away';
    }
  }

  /// Get products by category
  List<Product> getProductsByCategory(ProductCategory category) {
    if (category.isMainCategory) {
      return products
          .where((p) => p.category.parentCategory == category)
          .toList();
    } else {
      return products.where((p) => p.category == category).toList();
    }
  }

  factory Farmer.fromAppUser(AppUser user, List<Product> products) {
    return Farmer(
      id: user.id,
      name: user.name,
      phone: user.phone,
      profileImage: user.profileImage,
      location: user.location,
      rating: 0.0, // Default, should be calculated from reviews
      totalReviews: 0,
      totalOrders: 0,
      products: products,
      isVerified: user.isProfileComplete,
      joinedDate: user.createdAt,
    );
  }

  factory Farmer.fromMap(Map<String, dynamic> data, String id) {
    return Farmer(
      id: id,
      name: data['name'] ?? '',
      phone: data['phone'] ?? '',
      profileImage: data['profile_image'],
      location: data['location'] != null
          ? Location.fromMap(data['location'])
          : null,
      rating: (data['rating'] ?? 0.0).toDouble(),
      totalReviews: data['total_reviews'] ?? 0,
      totalOrders: data['total_orders'] ?? 0,
      products:
          (data['products'] as List<dynamic>?)
              ?.map((p) => Product.fromFirestore(p, p['id'] ?? ''))
              .toList() ??
          [],
      isVerified: data['is_verified'] ?? false,
      joinedDate: data['joined_date'] != null
          ? DateTime.parse(data['joined_date'])
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'phone': phone,
      'profile_image': profileImage,
      'location': location?.toMap(),
      'rating': rating,
      'total_reviews': totalReviews,
      'total_orders': totalOrders,
      'products': products.map((p) => p.toFirestore()).toList(),
      'is_verified': isVerified,
      'joined_date': joinedDate.toIso8601String(),
    };
  }
}

/// Review/Rating model for farmer reviews
class FarmerReview {
  final String id;
  final String farmerId;
  final String customerId;
  final String customerName;
  final double rating;
  final String? comment;
  final DateTime createdAt;

  FarmerReview({
    required this.id,
    required this.farmerId,
    required this.customerId,
    required this.customerName,
    required this.rating,
    this.comment,
    required this.createdAt,
  });

  factory FarmerReview.fromMap(Map<String, dynamic> data, String id) {
    return FarmerReview(
      id: id,
      farmerId: data['farmer_id'] ?? '',
      customerId: data['customer_id'] ?? '',
      customerName: data['customer_name'] ?? '',
      rating: (data['rating'] ?? 0.0).toDouble(),
      comment: data['comment'],
      createdAt: DateTime.parse(data['created_at']),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'farmer_id': farmerId,
      'customer_id': customerId,
      'customer_name': customerName,
      'rating': rating,
      'comment': comment,
      'created_at': createdAt.toIso8601String(),
    };
  }
}
