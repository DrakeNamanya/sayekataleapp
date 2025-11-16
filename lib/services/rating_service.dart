import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../models/order.dart' as app_order;
import '../models/user.dart';
import '../models/farmer_rating.dart';

/// Service for calculating and updating user system ratings
///
/// Rating calculation is based on:
/// 1. Total Completed Orders (quantity metric)
/// 2. Average Customer Rating (quality metric from reviews)
/// 3. Order Fulfillment Rate (reliability metric)
/// 4. Consistency (performance over time)
class RatingService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Calculate and update system rating for a user
  ///
  /// This method:
  /// - Fetches all orders where user is seller
  /// - Calculates performance metrics
  /// - Computes weighted system rating
  /// - Updates user profile with new rating
  Future<UserRatingMetrics> calculateAndUpdateUserRating(String userId) async {
    try {
      if (kDebugMode) {
        debugPrint('📊 Calculating rating for user: $userId');
      }

      // Fetch user data
      final userDoc = await _firestore.collection('users').doc(userId).get();
      if (!userDoc.exists) {
        throw Exception('User not found: $userId');
      }

      final user = AppUser.fromFirestore(userDoc.data()!, userDoc.id);

      // Calculate metrics
      final metrics = await _calculateUserMetrics(userId, user.role);

      // Calculate weighted system rating
      final systemRating = _calculateWeightedRating(metrics);

      // Update user profile
      await _firestore.collection('users').doc(userId).update({
        'system_rating': systemRating,
        'total_completed_orders': metrics.totalCompletedOrders,
        'average_customer_rating': metrics.averageCustomerRating,
        'order_fulfillment_rate': metrics.orderFulfillmentRate,
        'last_rating_update': DateTime.now().toIso8601String(),
      });

      if (kDebugMode) {
        debugPrint('✅ Rating updated for $userId: $systemRating/5.0');
        debugPrint('   Completed Orders: ${metrics.totalCompletedOrders}');
        debugPrint(
          '   Avg Customer Rating: ${metrics.averageCustomerRating.toStringAsFixed(2)}/5.0',
        );
        debugPrint(
          '   Fulfillment Rate: ${metrics.orderFulfillmentRate.toStringAsFixed(1)}%',
        );
      }

      return UserRatingMetrics(
        userId: userId,
        systemRating: systemRating,
        totalCompletedOrders: metrics.totalCompletedOrders,
        averageCustomerRating: metrics.averageCustomerRating,
        orderFulfillmentRate: metrics.orderFulfillmentRate,
        totalOrders: metrics.totalOrders,
        totalDeliveredOrders: metrics.totalDeliveredOrders,
        totalReviewedOrders: metrics.totalReviewedOrders,
      );
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Error calculating rating for $userId: $e');
      }
      rethrow;
    }
  }

  /// Calculate user performance metrics from order history
  Future<_MetricsData> _calculateUserMetrics(
    String userId,
    UserRole role,
  ) async {
    // Query orders based on user role
    Query<Map<String, dynamic>> ordersQuery;

    if (role == UserRole.sme) {
      // SME is a buyer - query by buyer_id
      ordersQuery = _firestore
          .collection('orders')
          .where('buyer_id', isEqualTo: userId);
    } else {
      // SHG/PSA are sellers - query by farmer_id (seller_id)
      ordersQuery = _firestore
          .collection('orders')
          .where('farmer_id', isEqualTo: userId);
    }

    final ordersSnapshot = await ordersQuery.get();
    final orders = ordersSnapshot.docs
        .map((doc) => app_order.Order.fromFirestore(doc.data(), doc.id))
        .toList();

    if (orders.isEmpty) {
      return _MetricsData(
        totalOrders: 0,
        totalCompletedOrders: 0,
        totalDeliveredOrders: 0,
        totalReviewedOrders: 0,
        totalRatingPoints: 0.0,
        orderFulfillmentRate: 0.0,
        averageCustomerRating: 0.0,
      );
    }

    // Calculate metrics
    int totalOrders = orders.length;
    int totalCompletedOrders = 0;
    int totalDeliveredOrders = 0;
    int totalReviewedOrders = 0;
    double totalRatingPoints = 0.0;

    for (var order in orders) {
      // Count completed orders
      if (order.status == app_order.OrderStatus.completed) {
        totalCompletedOrders++;
      }

      // Count delivered orders (includes completed)
      if (order.status == app_order.OrderStatus.delivered ||
          order.status == app_order.OrderStatus.completed) {
        totalDeliveredOrders++;
      }

      // Count reviewed orders and sum ratings
      if (order.rating != null && order.rating! > 0) {
        totalReviewedOrders++;
        totalRatingPoints += order.rating!.toDouble();
      }
    }

    // Calculate rates
    double orderFulfillmentRate = totalOrders > 0
        ? (totalDeliveredOrders / totalOrders * 100)
        : 0.0;

    double averageCustomerRating = totalReviewedOrders > 0
        ? (totalRatingPoints / totalReviewedOrders)
        : 0.0;

    return _MetricsData(
      totalOrders: totalOrders,
      totalCompletedOrders: totalCompletedOrders,
      totalDeliveredOrders: totalDeliveredOrders,
      totalReviewedOrders: totalReviewedOrders,
      totalRatingPoints: totalRatingPoints,
      orderFulfillmentRate: orderFulfillmentRate,
      averageCustomerRating: averageCustomerRating,
    );
  }

  /// Calculate weighted system rating from metrics
  ///
  /// Rating Formula:
  /// - Base Rating (40%): Scaled from completed orders count (0-50 orders = 0-5 stars)
  /// - Customer Rating (40%): Average customer ratings (0-5 stars)
  /// - Fulfillment Rate (20%): Order fulfillment percentage (0-100% = 0-5 stars)
  double _calculateWeightedRating(_MetricsData metrics) {
    // Base rating from completed orders (0-50 orders = 0-5 stars)
    // Scale: 10 orders = 1 star, 50+ orders = 5 stars
    double baseRating = (metrics.totalCompletedOrders / 10).clamp(0.0, 5.0);
    double baseWeight = 0.40;

    // Customer rating weight (direct 0-5 stars)
    double customerRating = metrics.averageCustomerRating;
    double customerWeight = 0.40;

    // Fulfillment rate (0-100% converted to 0-5 stars)
    double fulfillmentRating = (metrics.orderFulfillmentRate / 100) * 5;
    double fulfillmentWeight = 0.20;

    // Calculate weighted average
    double systemRating =
        (baseRating * baseWeight) +
        (customerRating * customerWeight) +
        (fulfillmentRating * fulfillmentWeight);

    // Ensure rating is between 0-5
    return systemRating.clamp(0.0, 5.0);
  }

  /// Calculate ratings for all users in the system
  ///
  /// This can be run periodically (e.g., daily) to update all user ratings
  Future<List<UserRatingMetrics>> calculateAllUserRatings() async {
    try {
      if (kDebugMode) {
        debugPrint('📊 Starting batch rating calculation for all users...');
      }

      final usersSnapshot = await _firestore.collection('users').get();
      final results = <UserRatingMetrics>[];

      for (var userDoc in usersSnapshot.docs) {
        try {
          final metrics = await calculateAndUpdateUserRating(userDoc.id);
          results.add(metrics);
        } catch (e) {
          if (kDebugMode) {
            debugPrint('⚠️ Failed to calculate rating for ${userDoc.id}: $e');
          }
          // Continue with other users even if one fails
        }
      }

      if (kDebugMode) {
        debugPrint(
          '✅ Batch rating calculation complete: ${results.length} users updated',
        );
      }

      return results;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Error in batch rating calculation: $e');
      }
      rethrow;
    }
  }

  /// Get user rating metrics without updating
  Future<UserRatingMetrics> getUserRatingMetrics(String userId) async {
    final userDoc = await _firestore.collection('users').doc(userId).get();
    if (!userDoc.exists) {
      throw Exception('User not found: $userId');
    }

    final data = userDoc.data()!;
    final user = AppUser.fromFirestore(data, userDoc.id);

    return UserRatingMetrics(
      userId: userId,
      systemRating: user.systemRating,
      totalCompletedOrders: user.totalCompletedOrders,
      averageCustomerRating: user.averageCustomerRating,
      orderFulfillmentRate: user.orderFulfillmentRate,
      totalOrders: 0, // Not stored in user model
      totalDeliveredOrders: 0, // Not stored in user model
      totalReviewedOrders: 0, // Not stored in user model
    );
  }

  /// Get multiple farmer ratings by their IDs
  /// Used for displaying ratings in product listings
  Future<Map<String, FarmerRating>> getFarmerRatings(
    List<String> farmerIds,
  ) async {
    try {
      if (farmerIds.isEmpty) {
        return {};
      }

      if (kDebugMode) {
        debugPrint('📊 Fetching ratings for ${farmerIds.length} farmers');
      }

      final ratingsMap = <String, FarmerRating>{};

      // Fetch ratings for each farmer
      for (final farmerId in farmerIds) {
        try {
          final ratingDoc = await _firestore
              .collection('farmer_ratings')
              .doc(farmerId)
              .get();

          if (ratingDoc.exists && ratingDoc.data() != null) {
            // Parse FarmerRating from Firestore data
            final farmerRating = FarmerRating.fromFirestore(
              ratingDoc.data()!,
              farmerId,
            );
            ratingsMap[farmerId] = farmerRating;
          }
        } catch (e) {
          if (kDebugMode) {
            debugPrint('⚠️ Failed to fetch rating for $farmerId: $e');
          }
          // Continue with other farmers even if one fails
        }
      }

      if (kDebugMode) {
        debugPrint('✅ Fetched ${ratingsMap.length} farmer ratings');
      }

      return ratingsMap;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Error fetching farmer ratings: $e');
      }
      rethrow;
    }
  }

  /// Submit a review for an order
  /// Creates review document and updates farmer rating statistics
  Future<void> submitReview(dynamic review) async {
    try {
      if (kDebugMode) {
        debugPrint('📝 Submitting review for order: ${review.orderId}');
      }

      // Create review document
      final reviewRef = _firestore.collection('reviews').doc();
      await reviewRef.set({
        'order_id': review.orderId,
        'user_id': review.userId,
        'user_name': review.userName,
        'farm_id': review.farmId,
        'product_id': review.productId,
        'rating': review.rating,
        'comment': review.comment,
        'photo_urls': review.photoUrls ?? [],
        'created_at': review.createdAt.toIso8601String(),
      });

      // Update order with review info
      await _firestore.collection('orders').doc(review.orderId).update({
        'rating': review.rating.toInt(),
        'review': review.comment,
        'review_photos': review.photoUrls ?? [],
        'reviewed_at': DateTime.now().toIso8601String(),
        'status': 'completed',
      });

      // Get farmer name from order
      final orderDoc = await _firestore
          .collection('orders')
          .doc(review.orderId)
          .get();
      if (orderDoc.exists) {
        final orderData = orderDoc.data()!;
        final farmerId = orderData['farmer_id'];
        final farmerName = orderData['farmer_name'];

        // Update farmer's rating statistics
        await _updateFarmerRating(farmerId, farmerName, review.rating.toInt());

        // Update seller's system rating after review submission
        try {
          await calculateAndUpdateUserRating(farmerId);
          if (kDebugMode) {
            debugPrint('⭐ Seller system rating updated for $farmerId');
          }
        } catch (e) {
          if (kDebugMode) {
            debugPrint('⚠️ Error updating seller system rating: $e');
          }
          // Don't fail the review submission if rating update fails
        }
      }

      if (kDebugMode) {
        debugPrint('✅ Review submitted successfully');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Error submitting review: $e');
      }
      rethrow;
    }
  }

  /// Update farmer's rating statistics
  Future<void> _updateFarmerRating(
    String farmerId,
    String farmerName,
    int rating,
  ) async {
    try {
      final ratingDoc = _firestore.collection('farmer_ratings').doc(farmerId);
      final ratingSnapshot = await ratingDoc.get();

      if (ratingSnapshot.exists) {
        // Update existing rating
        final data = ratingSnapshot.data()!;
        final currentAverage = (data['average_rating'] ?? 0.0).toDouble();
        final currentTotal = data['total_ratings'] ?? 0;
        final currentDistribution =
            (data['rating_distribution'] as List<dynamic>?)
                ?.map((e) => e as int)
                .toList() ??
            [0, 0, 0, 0, 0];

        // Calculate new average
        final newTotal = currentTotal + 1;
        final newAverage =
            ((currentAverage * currentTotal) + rating) / newTotal;

        // Update distribution
        currentDistribution[rating - 1]++;

        await ratingDoc.update({
          'average_rating': newAverage,
          'total_ratings': newTotal,
          'rating_distribution': currentDistribution,
          'last_rated_at': DateTime.now().toIso8601String(),
          'updated_at': DateTime.now().toIso8601String(),
        });
      } else {
        // Create new rating record
        final distribution = [0, 0, 0, 0, 0];
        distribution[rating - 1] = 1;

        await ratingDoc.set({
          'farmer_name': farmerName,
          'average_rating': rating.toDouble(),
          'total_ratings': 1,
          'total_orders': 0,
          'total_deliveries': 0,
          'rating_distribution': distribution,
          'last_rated_at': DateTime.now().toIso8601String(),
          'updated_at': DateTime.now().toIso8601String(),
        });
      }

      if (kDebugMode) {
        debugPrint('✅ Farmer rating updated for $farmerId');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Error updating farmer rating: $e');
      }
      // Don't rethrow - rating update failure shouldn't block review submission
    }
  }
}

/// Internal metrics data structure for calculations
class _MetricsData {
  final int totalOrders;
  final int totalCompletedOrders;
  final int totalDeliveredOrders;
  final int totalReviewedOrders;
  final double totalRatingPoints;
  final double orderFulfillmentRate;
  final double averageCustomerRating;

  _MetricsData({
    required this.totalOrders,
    required this.totalCompletedOrders,
    required this.totalDeliveredOrders,
    required this.totalReviewedOrders,
    required this.totalRatingPoints,
    required this.orderFulfillmentRate,
    required this.averageCustomerRating,
  });
}

/// User rating metrics result
class UserRatingMetrics {
  final String userId;
  final double systemRating;
  final int totalCompletedOrders;
  final double averageCustomerRating;
  final double orderFulfillmentRate;
  final int totalOrders;
  final int totalDeliveredOrders;
  final int totalReviewedOrders;

  UserRatingMetrics({
    required this.userId,
    required this.systemRating,
    required this.totalCompletedOrders,
    required this.averageCustomerRating,
    required this.orderFulfillmentRate,
    required this.totalOrders,
    required this.totalDeliveredOrders,
    required this.totalReviewedOrders,
  });

  @override
  String toString() {
    return 'UserRatingMetrics(userId: $userId, rating: $systemRating/5.0, '
        'completed: $totalCompletedOrders, avgRating: $averageCustomerRating, '
        'fulfillment: ${orderFulfillmentRate.toStringAsFixed(1)}%)';
  }
}
