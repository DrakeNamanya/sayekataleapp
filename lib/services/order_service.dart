import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../models/order.dart' as app_order;
import '../models/cart_item.dart';

/// Service for managing orders in Firestore
class OrderService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // ============================================================================
  // ORDER CREATION (Buyers)
  // ============================================================================

  /// Place order from cart items
  /// Groups cart items by farmer and creates separate orders
  Future<List<app_order.Order>> placeOrdersFromCart({
    required String buyerId,
    required String buyerName,
    required String buyerPhone,
    required List<CartItem> cartItems,
    required app_order.PaymentMethod paymentMethod,
    String? deliveryAddress,
    String? deliveryNotes,
  }) async {
    try {
      if (kDebugMode) {
        debugPrint('📦 Placing orders from ${cartItems.length} cart items');
      }

      // Group cart items by farmer
      final Map<String, List<CartItem>> itemsByFarmer = {};
      for (final item in cartItems) {
        if (!itemsByFarmer.containsKey(item.farmerId)) {
          itemsByFarmer[item.farmerId] = [];
        }
        itemsByFarmer[item.farmerId]!.add(item);
      }

      if (kDebugMode) {
        debugPrint('📊 Creating ${itemsByFarmer.length} orders (one per farmer)');
      }

      // Create one order per farmer
      final List<app_order.Order> createdOrders = [];

      for (final entry in itemsByFarmer.entries) {
        final farmerId = entry.key;
        final farmerItems = entry.value;
        final farmerName = farmerItems.first.farmerName;

        // Calculate total for this farmer's items
        final double total = farmerItems.fold(
          0,
          (sum, item) => sum + (item.price * item.quantity),
        );

        // Convert cart items to order items
        final List<app_order.OrderItem> orderItems = farmerItems.map((cartItem) {
          return app_order.OrderItem(
            productId: cartItem.productId,
            productName: cartItem.productName,
            productImage: cartItem.productImage,
            price: cartItem.price,
            unit: cartItem.unit,
            quantity: cartItem.quantity,
            subtotal: cartItem.price * cartItem.quantity,
          );
        }).toList();

        // Create order
        final order = app_order.Order(
          id: '', // Will be set by Firestore
          buyerId: buyerId,
          buyerName: buyerName,
          buyerPhone: buyerPhone,
          farmerId: farmerId,
          farmerName: farmerName,
          farmerPhone: '', // Will be loaded from farmer profile if needed
          items: orderItems,
          totalAmount: total,
          status: app_order.OrderStatus.pending,
          paymentMethod: paymentMethod,
          deliveryAddress: deliveryAddress,
          deliveryNotes: deliveryNotes,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        // Save to Firestore
        final docRef = await _firestore.collection('orders').add(order.toFirestore());

        if (kDebugMode) {
          debugPrint('✅ app_order.Order created: ${docRef.id} for farmer $farmerName (UGX ${total.toStringAsFixed(0)})');
        }

        createdOrders.add(order.copyWith(id: docRef.id));
      }

      return createdOrders;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Error placing orders: $e');
      }
      rethrow;
    }
  }

  // ============================================================================
  // ORDER RETRIEVAL
  // ============================================================================

  /// Get orders for a buyer
  Future<List<app_order.Order>> getBuyerOrders(String buyerId) async {
    try {
      final querySnapshot = await _firestore
          .collection('orders')
          .where('buyer_id', isEqualTo: buyerId)
          .get();

      final orders = querySnapshot.docs
          .map((doc) => app_order.Order.fromFirestore(doc.data(), doc.id))
          .toList();

      // Sort by created date (newest first)
      orders.sort((a, b) => b.createdAt.compareTo(a.createdAt));

      return orders;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Error fetching buyer orders: $e');
      }
      return [];
    }
  }

  /// Get orders for a farmer
  Future<List<app_order.Order>> getFarmerOrders(String farmerId) async {
    try {
      final querySnapshot = await _firestore
          .collection('orders')
          .where('farmer_id', isEqualTo: farmerId)
          .get();

      final orders = querySnapshot.docs
          .map((doc) => app_order.Order.fromFirestore(doc.data(), doc.id))
          .toList();

      // Sort by created date (newest first)
      orders.sort((a, b) => b.createdAt.compareTo(a.createdAt));

      return orders;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Error fetching farmer orders: $e');
      }
      return [];
    }
  }

  /// Get single order by ID
  Future<app_order.Order?> getOrder(String orderId) async {
    try {
      final doc = await _firestore.collection('orders').doc(orderId).get();

      if (doc.exists) {
        return app_order.Order.fromFirestore(doc.data()!, doc.id);
      }
      return null;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Error fetching order: $e');
      }
      return null;
    }
  }

  /// Stream of orders for real-time updates (for farmers)
  Stream<List<app_order.Order>> streamFarmerOrders(String farmerId) {
    return _firestore
        .collection('orders')
        .where('farmer_id', isEqualTo: farmerId)
        .snapshots()
        .map((snapshot) {
      final orders = snapshot.docs
          .map((doc) => app_order.Order.fromFirestore(doc.data(), doc.id))
          .toList();

      // Sort by created date (newest first)
      orders.sort((a, b) => b.createdAt.compareTo(a.createdAt));

      return orders;
    });
  }

  /// Stream of orders for real-time updates (for buyers)
  Stream<List<app_order.Order>> streamBuyerOrders(String buyerId) {
    return _firestore
        .collection('orders')
        .where('buyer_id', isEqualTo: buyerId)
        .snapshots()
        .map((snapshot) {
      final orders = snapshot.docs
          .map((doc) => app_order.Order.fromFirestore(doc.data(), doc.id))
          .toList();

      // Sort by created date (newest first)
      orders.sort((a, b) => b.createdAt.compareTo(a.createdAt));

      return orders;
    });
  }

  // ============================================================================
  // ORDER STATUS UPDATES (Farmers)
  // ============================================================================

  /// Farmer accepts/confirms order
  Future<void> confirmOrder(String orderId) async {
    try {
      await _firestore.collection('orders').doc(orderId).update({
        'status': app_order.OrderStatus.confirmed.toString().split('.').last,
        'confirmed_at': FieldValue.serverTimestamp(),
        'updated_at': FieldValue.serverTimestamp(),
      });

      if (kDebugMode) {
        debugPrint('✅ app_order.Order $orderId confirmed');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Error confirming order: $e');
      }
      rethrow;
    }
  }

  /// Farmer rejects order
  Future<void> rejectOrder(String orderId, String reason) async {
    try {
      await _firestore.collection('orders').doc(orderId).update({
        'status': app_order.OrderStatus.rejected.toString().split('.').last,
        'rejected_at': FieldValue.serverTimestamp(),
        'rejection_reason': reason,
        'updated_at': FieldValue.serverTimestamp(),
      });

      if (kDebugMode) {
        debugPrint('❌ app_order.Order $orderId rejected: $reason');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Error rejecting order: $e');
      }
      rethrow;
    }
  }

  /// Update order status (general)
  Future<void> updateOrderStatus(String orderId, app_order.OrderStatus newStatus) async {
    try {
      final updateData = {
        'status': newStatus.toString().split('.').last,
        'updated_at': FieldValue.serverTimestamp(),
      };

      // Add specific timestamps based on status
      if (newStatus == app_order.OrderStatus.delivered) {
        updateData['delivered_at'] = FieldValue.serverTimestamp();
      }

      await _firestore.collection('orders').doc(orderId).update(updateData);

      if (kDebugMode) {
        debugPrint('✅ app_order.Order $orderId status updated to ${newStatus.displayName}');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Error updating order status: $e');
      }
      rethrow;
    }
  }

  // ============================================================================
  // ORDER STATISTICS
  // ============================================================================

  /// Get order counts by status for farmer
  Future<Map<app_order.OrderStatus, int>> getFarmerOrderStats(String farmerId) async {
    try {
      final orders = await getFarmerOrders(farmerId);

      final Map<app_order.OrderStatus, int> stats = {};
      for (final status in app_order.OrderStatus.values) {
        stats[status] = orders.where((order) => order.status == status).length;
      }

      return stats;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Error getting farmer order stats: $e');
      }
      return {};
    }
  }

  /// Get total revenue for farmer
  Future<double> getFarmerRevenue(String farmerId) async {
    try {
      final orders = await getFarmerOrders(farmerId);

      // Only count completed/delivered orders
      final completedOrders = orders.where(
        (order) =>
            order.status == app_order.OrderStatus.completed ||
            order.status == app_order.OrderStatus.delivered,
      );

      return completedOrders.fold<double>(0.0, (sum, order) => sum + order.totalAmount);
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Error calculating farmer revenue: $e');
      }
      return 0;
    }
  }

  // ============================================================================
  // DELIVERY CONFIRMATION (Buyer)
  // ============================================================================

  /// Buyer confirms receipt of order
  /// This marks the order as truly completed and triggers stock reduction
  Future<void> confirmReceipt(String orderId) async {
    try {
      if (kDebugMode) {
        debugPrint('✅ Buyer confirming receipt of order: $orderId');
      }

      // Get the order first to reduce stock
      final orderDoc = await _firestore.collection('orders').doc(orderId).get();
      if (!orderDoc.exists) {
        throw Exception('Order not found');
      }

      final order = app_order.Order.fromFirestore(orderDoc.data()!, orderId);

      // Update order status to completed
      await _firestore.collection('orders').doc(orderId).update({
        'status': app_order.OrderStatus.completed.toString().split('.').last,
        'is_received_by_buyer': true,
        'received_at': FieldValue.serverTimestamp(),
        'updated_at': FieldValue.serverTimestamp(),
      });

      // Reduce stock for each product in the order
      for (final item in order.items) {
        try {
          // Get current product stock
          final productDoc = await _firestore.collection('products').doc(item.productId).get();
          
          if (productDoc.exists) {
            final currentStock = productDoc.data()?['stock_quantity'] ?? 0;
            final newStock = (currentStock - item.quantity).clamp(0, double.infinity).toInt();

            await _firestore.collection('products').doc(item.productId).update({
              'stock_quantity': newStock,
              'is_available': newStock > 0,
              'updated_at': FieldValue.serverTimestamp(),
            });

            if (kDebugMode) {
              debugPrint('📉 Stock reduced for ${item.productName}: $currentStock → $newStock');
            }
          }
        } catch (e) {
          if (kDebugMode) {
            debugPrint('⚠️ Error reducing stock for product ${item.productId}: $e');
          }
          // Continue with other products even if one fails
        }
      }

      if (kDebugMode) {
        debugPrint('✅ Order $orderId marked as completed and stock reduced');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Error confirming receipt: $e');
      }
      rethrow;
    }
  }

  // ============================================================================
  // SME/BUYER STATISTICS
  // ============================================================================

  /// Get buyer's monthly spending (current month)
  Future<double> getBuyerMonthlySpending(String buyerId) async {
    try {
      final now = DateTime.now();
      final firstDayOfMonth = DateTime(now.year, now.month, 1);
      
      final orders = await getBuyerOrders(buyerId);
      
      // Filter orders from current month that are completed or delivered
      final monthlyOrders = orders.where((order) {
        return order.createdAt.isAfter(firstDayOfMonth) &&
               (order.status == app_order.OrderStatus.completed ||
                order.status == app_order.OrderStatus.delivered ||
                order.isReceivedByBuyer);
      });

      return monthlyOrders.fold<double>(0.0, (sum, order) => sum + order.totalAmount);
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Error calculating monthly spending: $e');
      }
      return 0;
    }
  }

  /// Get completed orders count (received by buyer)
  Future<int> getBuyerCompletedOrdersCount(String buyerId) async {
    try {
      final orders = await getBuyerOrders(buyerId);
      return orders.where((order) => 
        order.isReceivedByBuyer || 
        order.status == app_order.OrderStatus.completed
      ).length;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Error getting completed orders count: $e');
      }
      return 0;
    }
  }

  /// Get active orders count (not yet received)
  Future<int> getBuyerActiveOrdersCount(String buyerId) async {
    try {
      final orders = await getBuyerOrders(buyerId);
      return orders.where((order) => 
        !order.isReceivedByBuyer && 
        order.status != app_order.OrderStatus.completed &&
        order.status != app_order.OrderStatus.cancelled &&
        order.status != app_order.OrderStatus.rejected
      ).length;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Error getting active orders count: $e');
      }
      return 0;
    }
  }

  /// Get recent orders (completed within 24 hours)
  Future<List<app_order.Order>> getBuyerRecentOrders(String buyerId) async {
    try {
      final orders = await getBuyerOrders(buyerId);
      final yesterday = DateTime.now().subtract(const Duration(hours: 24));
      
      return orders.where((order) => 
        order.isReceivedByBuyer &&
        order.receivedAt != null &&
        order.receivedAt!.isAfter(yesterday)
      ).toList();
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Error getting recent orders: $e');
      }
      return [];
    }
  }
}
