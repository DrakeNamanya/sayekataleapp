import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../models/user.dart';
import '../models/order.dart' as app_order;
import '../models/subscription.dart';

/// Service for fetching and calculating analytics data
class AnalyticsService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Get comprehensive analytics data
  Future<AnalyticsData> getAnalytics({
    String? district,
    UserRole? role,
    String? productCategory,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      // Fetch users
      final usersData = await _getUsersAnalytics(district: district, role: role);

      // Fetch orders
      final ordersData = await _getOrdersAnalytics(
        district: district,
        productCategory: productCategory,
        startDate: startDate,
        endDate: endDate,
      );

      // Fetch subscriptions
      final subscriptionData = await _getSubscriptionAnalytics(
        startDate: startDate,
        endDate: endDate,
      );

      return AnalyticsData(
        totalUsers: usersData['total'] ?? 0,
        activeUsers: usersData['active'] ?? 0,
        shgCount: usersData['shg'] ?? 0,
        smeCount: usersData['sme'] ?? 0,
        psaCount: usersData['psa'] ?? 0,
        usersByDistrict: usersData['by_district'] ?? {},
        totalOrders: ordersData['total'] ?? 0,
        pendingOrders: ordersData['pending'] ?? 0,
        confirmedOrders: ordersData['confirmed'] ?? 0,
        deliveredOrders: ordersData['delivered'] ?? 0,
        completedOrders: ordersData['completed'] ?? 0,
        cancelledOrders: ordersData['cancelled'] ?? 0,
        ordersByDistrict: ordersData['by_district'] ?? {},
        ordersByProduct: ordersData['by_product'] ?? {},
        totalOrderRevenue: ordersData['total_revenue'] ?? 0.0,
        totalSubscriptions: subscriptionData['total'] ?? 0,
        activeSubscriptions: subscriptionData['active'] ?? 0,
        subscriptionRevenue: subscriptionData['revenue'] ?? 0.0,
        totalRevenue: (ordersData['total_revenue'] ?? 0.0) +
            (subscriptionData['revenue'] ?? 0.0),
      );
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Error fetching analytics: \$e');
      }
      rethrow;
    }
  }

  /// Get users analytics
  Future<Map<String, dynamic>> _getUsersAnalytics({
    String? district,
    UserRole? role,
  }) async {
    try {
      Query<Map<String, dynamic>> query = _firestore.collection('users');

      // Apply filters
      if (role != null) {
        query = query.where('role', isEqualTo: role.toString().split('.').last);
      }

      if (district != null && district.isNotEmpty) {
        query = query.where('location.district', isEqualTo: district);
      }

      final snapshot = await query.get();
      final users =
          snapshot.docs.map((doc) => AppUser.fromFirestore(doc.data(), doc.id)).toList();

      // Calculate stats
      final total = users.length;
      final active = users.where((u) => !u.isSuspended).length;
      final shgCount = users.where((u) => u.role == UserRole.shg).length;
      final smeCount = users.where((u) => u.role == UserRole.sme).length;
      final psaCount = users.where((u) => u.role == UserRole.psa).length;

      // Group by district
      final byDistrict = <String, int>{};
      for (var user in users) {
        final userDistrict = user.location?.district ?? 'Unknown';
        byDistrict[userDistrict] = (byDistrict[userDistrict] ?? 0) + 1;
      }

      return {
        'total': total,
        'active': active,
        'shg': shgCount,
        'sme': smeCount,
        'psa': psaCount,
        'by_district': byDistrict,
      };
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Error fetching users analytics: \$e');
      }
      return {};
    }
  }

  /// Get orders analytics
  Future<Map<String, dynamic>> _getOrdersAnalytics({
    String? district,
    String? productCategory,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      Query<Map<String, dynamic>> query = _firestore.collection('orders');

      // Apply date filters
      if (startDate != null) {
        query = query.where(
          'created_at',
          isGreaterThanOrEqualTo: startDate.toIso8601String(),
        );
      }
      if (endDate != null) {
        query = query.where(
          'created_at',
          isLessThanOrEqualTo: endDate.toIso8601String(),
        );
      }

      final snapshot = await query.get();
      final orders = snapshot.docs
          .map((doc) => app_order.Order.fromFirestore(doc.data(), doc.id))
          .toList();

      // Apply additional filters
      var filteredOrders = orders;
      if (district != null && district.isNotEmpty) {
        filteredOrders = filteredOrders
            .where((o) => o.buyerLocation?.district == district)
            .toList();
      }
      if (productCategory != null && productCategory.isNotEmpty) {
        filteredOrders = filteredOrders
            .where((o) => o.productCategory.displayName == productCategory)
            .toList();
      }

      // Calculate stats
      final total = filteredOrders.length;
      final pending = filteredOrders
          .where((o) => o.status == app_order.OrderStatus.pending)
          .length;
      final confirmed = filteredOrders
          .where((o) => o.status == app_order.OrderStatus.confirmed)
          .length;
      final delivered = filteredOrders
          .where((o) => o.status == app_order.OrderStatus.delivered)
          .length;
      final completed = filteredOrders
          .where((o) => o.status == app_order.OrderStatus.completed)
          .length;
      final cancelled = filteredOrders
          .where((o) => o.status == app_order.OrderStatus.cancelled)
          .length;

      // Calculate revenue
      final totalRevenue = filteredOrders
          .where((o) => o.status == app_order.OrderStatus.completed)
          .fold<double>(0.0, (sum, order) => sum + order.totalPrice);

      // Group by district
      final byDistrict = <String, int>{};
      for (var order in filteredOrders) {
        final orderDistrict = order.buyerLocation?.district ?? 'Unknown';
        byDistrict[orderDistrict] = (byDistrict[orderDistrict] ?? 0) + 1;
      }

      // Group by product
      final byProduct = <String, int>{};
      for (var order in filteredOrders) {
        final category = order.productCategory.displayName;
        byProduct[category] = (byProduct[category] ?? 0) + 1;
      }

      return {
        'total': total,
        'pending': pending,
        'confirmed': confirmed,
        'delivered': delivered,
        'completed': completed,
        'cancelled': cancelled,
        'total_revenue': totalRevenue,
        'by_district': byDistrict,
        'by_product': byProduct,
      };
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Error fetching orders analytics: \$e');
      }
      return {};
    }
  }

  /// Get subscriptions analytics
  Future<Map<String, dynamic>> _getSubscriptionAnalytics({
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      Query<Map<String, dynamic>> query = _firestore.collection('subscriptions');

      // Apply date filters
      if (startDate != null) {
        query = query.where(
          'created_at',
          isGreaterThanOrEqualTo: Timestamp.fromDate(startDate),
        );
      }
      if (endDate != null) {
        query = query.where(
          'created_at',
          isLessThanOrEqualTo: Timestamp.fromDate(endDate),
        );
      }

      final snapshot = await query.get();
      final subscriptions = snapshot.docs
          .map((doc) => Subscription.fromFirestore(doc.data(), doc.id))
          .toList();

      // Calculate stats
      final total = subscriptions.length;
      final active = subscriptions
          .where((s) => s.status == SubscriptionStatus.active)
          .length;

      // Calculate revenue
      final revenue = subscriptions
          .where((s) => s.status == SubscriptionStatus.active)
          .fold<double>(0.0, (sum, sub) => sum + sub.amount);

      return {
        'total': total,
        'active': active,
        'revenue': revenue,
      };
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Error fetching subscription analytics: \$e');
      }
      return {};
    }
  }

  /// Get list of all districts
  Future<List<String>> getDistricts() async {
    try {
      final snapshot = await _firestore.collection('users').get();
      final districts = <String>{};

      for (var doc in snapshot.docs) {
        final data = doc.data();
        if (data['location'] != null && data['location']['district'] != null) {
          districts.add(data['location']['district'] as String);
        }
      }

      return districts.toList()..sort();
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Error fetching districts: \$e');
      }
      return [];
    }
  }
}

/// Analytics data model
class AnalyticsData {
  final int totalUsers;
  final int activeUsers;
  final int shgCount;
  final int smeCount;
  final int psaCount;
  final Map<String, int> usersByDistrict;
  final int totalOrders;
  final int pendingOrders;
  final int confirmedOrders;
  final int deliveredOrders;
  final int completedOrders;
  final int cancelledOrders;
  final Map<String, int> ordersByDistrict;
  final Map<String, int> ordersByProduct;
  final double totalOrderRevenue;
  final int totalSubscriptions;
  final int activeSubscriptions;
  final double subscriptionRevenue;
  final double totalRevenue;

  AnalyticsData({
    required this.totalUsers,
    required this.activeUsers,
    required this.shgCount,
    required this.smeCount,
    required this.psaCount,
    required this.usersByDistrict,
    required this.totalOrders,
    required this.pendingOrders,
    required this.confirmedOrders,
    required this.deliveredOrders,
    required this.completedOrders,
    required this.cancelledOrders,
    required this.ordersByDistrict,
    required this.ordersByProduct,
    required this.totalOrderRevenue,
    required this.totalSubscriptions,
    required this.activeSubscriptions,
    required this.subscriptionRevenue,
    required this.totalRevenue,
  });
}
