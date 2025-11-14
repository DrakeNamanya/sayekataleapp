import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../models/order.dart' as app_order;
import '../models/user.dart';

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
        debugPrint('   Avg Customer Rating: ${metrics.averageCustomerRating.toStringAsFixed(2)}/5.0');
        debugPrint('   Fulfillment Rate: ${metrics.orderFulfillmentRate.toStringAsFixed(1)}%');
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
  Future<_MetricsData> _calculateUserMetrics(String userId, UserRole role) async {
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
    double systemRating = (baseRating * baseWeight) +
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
        debugPrint('✅ Batch rating calculation complete: ${results.length} users updated');
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
