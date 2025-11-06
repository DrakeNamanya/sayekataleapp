class Review {
  final String id;
  final String orderId;
  final String userId;
  final String userName;
  final String farmId;
  final String? productId;
  final double rating;
  final String? comment;
  final List<String> photoUrls;  // Photo URLs for this review
  final DateTime createdAt;

  Review({
    required this.id,
    required this.orderId,
    required this.userId,
    required this.userName,
    required this.farmId,
    this.productId,
    required this.rating,
    this.comment,
    this.photoUrls = const [],
    required this.createdAt,
  });

  factory Review.fromFirestore(Map<String, dynamic> data, String id) {
    return Review(
      id: id,
      orderId: data['order_id'] ?? '',
      userId: data['user_id'] ?? '',
      userName: data['user_name'] ?? '',
      farmId: data['farm_id'] ?? '',
      productId: data['product_id'],
      rating: (data['rating'] ?? 0.0).toDouble(),
      comment: data['comment'],
      photoUrls: (data['photo_urls'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
      createdAt: DateTime.parse(data['created_at']),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'order_id': orderId,
      'user_id': userId,
      'user_name': userName,
      'farm_id': farmId,
      'product_id': productId,
      'rating': rating,
      'comment': comment,
      'photo_urls': photoUrls,
      'created_at': createdAt.toIso8601String(),
    };
  }
  
  /// Check if review has photos
  bool get hasPhotos => photoUrls.isNotEmpty;
}
