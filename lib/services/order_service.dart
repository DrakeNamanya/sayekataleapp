import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../models/order.dart' as app_order;
import '../models/cart_item.dart';
import '../models/delivery_tracking.dart';
import 'notification_service.dart';
import 'delivery_tracking_service.dart';
import 'receipt_service.dart';
import 'rating_service.dart';

/// Service for managing orders in Firestore
class OrderService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final NotificationService _notificationService = NotificationService();
  final DeliveryTrackingService _trackingService = DeliveryTrackingService();
  final ReceiptService _receiptService = ReceiptService();
  final RatingService _ratingService = RatingService();

  /// Generate human-readable order number
  String _generateOrderNumber() {
    final now = DateTime.now();
    final year = now.year;
    final timestamp = now.millisecondsSinceEpoch.toString().substring(7);
    return 'ORD-$year-$timestamp';
  }

  // ============================================================================
  // ORDER CREATION (Buyers)
  // ============================================================================

  /// Validate stock availability for cart items
  Future<Map<String, dynamic>> validateCartStock(
    List<CartItem> cartItems,
  ) async {
    final List<String> outOfStockItems = [];
    final List<String> insufficientStockItems = [];

    for (final item in cartItems) {
      try {
        // Fetch current product stock from Firebase
        final productDoc = await _firestore
            .collection('products')
            .doc(item.productId)
            .get();

        if (!productDoc.exists) {
          outOfStockItems.add(item.productName);
          continue;
        }

        final productData = productDoc.data()!;
        final currentStock = productData['stock_quantity'] ?? 0;
        final isAvailable = productData['is_available'] ?? false;

        if (!isAvailable || currentStock == 0) {
          outOfStockItems.add(item.productName);
        } else if (currentStock < item.quantity) {
          insufficientStockItems.add(
            '${item.productName} (Available: $currentStock ${item.unit}, Requested: ${item.quantity} ${item.unit})',
          );
        }
      } catch (e) {
        if (kDebugMode) {
          debugPrint('⚠️ Error checking stock for ${item.productName}: $e');
        }
        outOfStockItems.add(item.productName);
      }
    }

    return {
      'isValid': outOfStockItems.isEmpty && insufficientStockItems.isEmpty,
      'outOfStockItems': outOfStockItems,
      'insufficientStockItems': insufficientStockItems,
    };
  }

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

      // ✅ STEP 1: Validate stock availability before creating orders
      if (kDebugMode) {
        debugPrint('🔍 Validating stock availability...');
      }

      final stockValidation = await validateCartStock(cartItems);

      if (!stockValidation['isValid']) {
        final outOfStock = stockValidation['outOfStockItems'] as List<String>;
        final insufficient =
            stockValidation['insufficientStockItems'] as List<String>;

        String errorMessage = '❌ Cannot place order:\n';
        if (outOfStock.isNotEmpty) {
          errorMessage +=
              '\nOut of stock:\n${outOfStock.map((item) => '  • $item').join('\n')}';
        }
        if (insufficient.isNotEmpty) {
          errorMessage +=
              '\n\nInsufficient stock:\n${insufficient.map((item) => '  • $item').join('\n')}';
        }

        throw Exception(errorMessage);
      }

      if (kDebugMode) {
        debugPrint('✅ Stock validation passed');
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
        debugPrint(
          '📊 Creating ${itemsByFarmer.length} orders (one per farmer)',
        );
      }

      // Create one order per farmer
      final List<app_order.Order> createdOrders = [];

      for (final entry in itemsByFarmer.entries) {
        final farmerId = entry.key;
        final farmerItems = entry.value;
        final farmerName = farmerItems.first.farmerName;

        // Fetch buyer and farmer profiles to get system IDs (national IDs)
        String? buyerSystemId;
        String? farmerSystemId;
        String farmerPhone = '';

        try {
          final buyerDoc = await _firestore
              .collection('users')
              .doc(buyerId)
              .get();
          if (buyerDoc.exists) {
            buyerSystemId = buyerDoc.data()?['national_id'];
          }

          final farmerDoc = await _firestore
              .collection('users')
              .doc(farmerId)
              .get();
          if (farmerDoc.exists) {
            farmerSystemId = farmerDoc.data()?['national_id'];
            farmerPhone = farmerDoc.data()?['phone'] ?? '';
          }
        } catch (e) {
          if (kDebugMode) {
            debugPrint('⚠️ Could not fetch user profiles for system IDs: $e');
          }
        }

        // Calculate total for this farmer's items
        final double total = farmerItems.fold(
          0,
          (acc, item) => acc + (item.price * item.quantity),
        );

        // Convert cart items to order items
        final List<app_order.OrderItem> orderItems = farmerItems.map((
          cartItem,
        ) {
          return app_order.OrderItem(
            productId: cartItem.productId,
            productName: cartItem.productName,
            productImage: cartItem.productImage,
            price: cartItem.price,
            unit: cartItem.unit,
            quantity: cartItem.quantity,
            total: cartItem.price * cartItem.quantity,
          );
        }).toList();

        // Determine order type based on buyer and seller roles
        app_order.OrderType orderType;

        try {
          // Fetch buyer and seller roles to determine order type
          final buyerDoc = await _firestore
              .collection('users')
              .doc(buyerId)
              .get();
          final sellerDoc = await _firestore
              .collection('users')
              .doc(farmerId)
              .get();

          final buyerRole = buyerDoc.exists
              ? (buyerDoc.data()?['role'] as String?)
              : null;
          final sellerRole = sellerDoc.exists
              ? (sellerDoc.data()?['role'] as String?)
              : null;

          if (kDebugMode) {
            debugPrint('📊 Order roles: Buyer=$buyerRole, Seller=$sellerRole');
          }

          // Determine order type based on roles
          if (buyerRole == 'shg' && sellerRole == 'psa') {
            // SHG buying inputs from PSA
            orderType = app_order.OrderType.shgToPsaInputPurchase;
            if (kDebugMode) {
              debugPrint('📦 SHG → PSA: Input purchase order');
            }
          } else {
            // SME buying products from SHG or other combinations
            orderType = app_order.OrderType.smeToShgProductPurchase;
            if (kDebugMode) {
              debugPrint('📦 SME → SHG: Product purchase order');
            }
          }
        } catch (e) {
          if (kDebugMode) {
            debugPrint(
              '⚠️ Error determining order type: $e, defaulting to SME → SHG',
            );
          }
          orderType = app_order.OrderType.smeToShgProductPurchase;
        }

        // Create order (no service fees)
        final order = app_order.Order(
          id: '', // Will be set by Firestore
          type: orderType,
          buyerId: buyerId,
          buyerName: buyerName,
          buyerPhone: buyerPhone,
          sellerId: farmerId,
          sellerName: farmerName,
          sellerPhone: farmerPhone,
          items: orderItems,
          subtotal: total,
          serviceFee: 0.0, // No service fees
          totalAmount: total, // Total equals subtotal (no additional fees)
          status: app_order.OrderStatus.pending,
          paymentMethod: paymentMethod,
          deliveryAddress: deliveryAddress ?? '',
          deliveryNotes: deliveryNotes,
          // Backward compatibility fields
          farmerId: farmerId,
          farmerName: farmerName,
          farmerPhone: farmerPhone,
          orderNumber: _generateOrderNumber(),
          createdAt: DateTime.now(),
        );

        // Save to Firestore
        final docRef = await _firestore
            .collection('orders')
            .add(order.toFirestore());

        if (kDebugMode) {
          debugPrint(
            '✅ app_order.Order created: ${docRef.id} for farmer $farmerName (UGX ${total.toStringAsFixed(0)})',
          );
        }

        final createdOrder = order.copyWith(id: docRef.id);
        createdOrders.add(createdOrder);

        // Send notification to seller about new order
        try {
          await _notificationService.sendNewOrderNotification(
            sellerId: farmerId,
            buyerName: buyerName,
            orderId: docRef.id,
            totalAmount: total,
          );
        } catch (e) {
          if (kDebugMode) {
            debugPrint('⚠️ Failed to send new order notification: $e');
          }
          // Don't fail the order creation if notification fails
        }
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
      // Query by farmer_id (for SHG farmers)
      final farmerQuery = await _firestore
          .collection('orders')
          .where('farmer_id', isEqualTo: farmerId)
          .get();

      // Query by seller_id (for PSA suppliers)
      final sellerQuery = await _firestore
          .collection('orders')
          .where('seller_id', isEqualTo: farmerId)
          .get();

      // Merge results and remove duplicates
      final Map<String, app_order.Order> ordersMap = {};

      for (var doc in farmerQuery.docs) {
        ordersMap[doc.id] = app_order.Order.fromFirestore(doc.data(), doc.id);
      }

      for (var doc in sellerQuery.docs) {
        // Only add if not already in map (avoid duplicates)
        if (!ordersMap.containsKey(doc.id)) {
          ordersMap[doc.id] = app_order.Order.fromFirestore(doc.data(), doc.id);
        }
      }

      final orders = ordersMap.values.toList();

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
      // Validate orderId is not empty or invalid
      if (orderId.isEmpty || orderId == 'orders' || orderId.contains('/')) {
        throw Exception(
          'Invalid order ID: "$orderId". Order ID must be a valid document ID.',
        );
      }

      if (kDebugMode) {
        debugPrint('🔍 Confirming order with ID: "$orderId"');
      }

      // ✅ STEP 1: Get order details to reduce stock
      final orderDoc = await _firestore.collection('orders').doc(orderId).get();
      if (!orderDoc.exists) {
        throw Exception('Order not found');
      }

      final order = app_order.Order.fromFirestore(
        orderDoc.data()!,
        orderDoc.id,
      );

      if (kDebugMode) {
        debugPrint(
          '📦 Confirming order $orderId with ${order.items.length} items',
        );
      }

      // ✅ STEP 2: Reduce stock for each product in the order
      for (final item in order.items) {
        try {
          final productDoc = await _firestore
              .collection('products')
              .doc(item.productId)
              .get();

          if (productDoc.exists) {
            final currentStock = productDoc.data()?['stock_quantity'] ?? 0;
            final newStock = currentStock - item.quantity;

            if (kDebugMode) {
              debugPrint(
                '   📉 ${item.productName}: $currentStock → $newStock ${item.unit}',
              );
            }

            // Update product stock
            await _firestore.collection('products').doc(item.productId).update({
              'stock_quantity': newStock < 0 ? 0 : newStock,
              'is_available': newStock > 0,
              'updated_at': FieldValue.serverTimestamp(),
            });
          } else {
            if (kDebugMode) {
              debugPrint(
                '   ⚠️ Product ${item.productId} not found, skipping stock reduction',
              );
            }
          }
        } catch (e) {
          if (kDebugMode) {
            debugPrint(
              '   ⚠️ Error reducing stock for ${item.productName}: $e',
            );
          }
          // Continue with other items even if one fails
        }
      }

      // ✅ STEP 3: Update order status to confirmed
      await _firestore.collection('orders').doc(orderId).update({
        'status': app_order.OrderStatus.confirmed.toString().split('.').last,
        'confirmed_at': FieldValue.serverTimestamp(),
        'updated_at': FieldValue.serverTimestamp(),
      });

      if (kDebugMode) {
        debugPrint('✅ Order $orderId confirmed and stock reduced');
      }

      // ✅ STEP 4: Send notification to buyer about confirmation
      try {
        await _notificationService.sendOrderConfirmationNotification(
          buyerId: order.buyerId,
          orderId: orderId,
          sellerName: order.sellerName,
        );
      } catch (e) {
        if (kDebugMode) {
          debugPrint('⚠️ Failed to send confirmation notification: $e');
        }
      }

      // Auto-create delivery tracking
      try {
        await _createDeliveryTracking(orderId);
      } catch (e) {
        if (kDebugMode) {
          debugPrint('⚠️ Failed to create delivery tracking: $e');
        }
        // Don't fail order confirmation if tracking creation fails
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Error confirming order: $e');
      }
      rethrow;
    }
  }

  /// Create delivery tracking for confirmed order
  Future<void> _createDeliveryTracking(String orderId) async {
    try {
      // Get order details
      final orderDoc = await _firestore.collection('orders').doc(orderId).get();
      if (!orderDoc.exists) {
        throw Exception('Order not found');
      }

      final order = app_order.Order.fromFirestore(
        orderDoc.data()!,
        orderDoc.id,
      );

      // Get seller (delivery person) info
      final sellerDoc = await _firestore
          .collection('users')
          .doc(order.farmerId)
          .get();
      if (!sellerDoc.exists) {
        throw Exception('Seller not found');
      }
      final sellerData = sellerDoc.data()!;
      final sellerName = sellerData['name'] ?? 'Unknown';
      final sellerPhone = sellerData['phone'] ?? '';
      final sellerLocation = sellerData['location'] as Map<String, dynamic>?;

      // Get buyer (recipient) info
      final buyerDoc = await _firestore
          .collection('users')
          .doc(order.buyerId)
          .get();
      if (!buyerDoc.exists) {
        throw Exception('Buyer not found');
      }
      final buyerData = buyerDoc.data()!;
      final buyerName = buyerData['name'] ?? 'Unknown';
      final buyerPhone = buyerData['phone'] ?? '';
      final buyerLocation = buyerData['location'] as Map<String, dynamic>?;

      // Validate GPS coordinates exist - GPS is MANDATORY for delivery tracking
      if (sellerLocation == null || buyerLocation == null) {
        if (kDebugMode) {
          debugPrint('⚠️ Missing GPS coordinates for order $orderId');
          debugPrint(
            '   Seller location: ${sellerLocation != null ? "Present" : "MISSING"}',
          );
          debugPrint(
            '   Buyer location: ${buyerLocation != null ? "Present" : "MISSING"}',
          );
        }
        throw Exception(
          'GPS_MISSING: Cannot create delivery tracking. '
          '${sellerLocation == null ? "Seller" : "Buyer"} needs to add GPS coordinates in profile settings.',
        );
      }

      // Extract GPS coordinates
      final originLat = sellerLocation['latitude']?.toDouble() ?? 0.0;
      final originLng = sellerLocation['longitude']?.toDouble() ?? 0.0;
      final destLat = buyerLocation['latitude']?.toDouble() ?? 0.0;
      final destLng = buyerLocation['longitude']?.toDouble() ?? 0.0;

      // Validate coordinates are not zero (invalid)
      if (originLat == 0.0 ||
          originLng == 0.0 ||
          destLat == 0.0 ||
          destLng == 0.0) {
        if (kDebugMode) {
          debugPrint('⚠️ Invalid GPS coordinates (0,0) for order $orderId');
        }
        throw Exception(
          'GPS_INVALID: Cannot create delivery tracking. '
          'Please update your GPS coordinates in profile settings.',
        );
      }

      // Determine delivery type (default to SHG_TO_SME)
      String deliveryType = 'SHG_TO_SME';

      if (kDebugMode) {
        debugPrint('🗺️ Creating delivery tracking for order $orderId');
        debugPrint('   Origin: ($originLat, $originLng)');
        debugPrint('   Destination: ($destLat, $destLng)');
      }

      // Create location points
      final originPoint = LocationPoint(
        latitude: originLat,
        longitude: originLng,
        address: sellerLocation['address'],
      );

      final destPoint = LocationPoint(
        latitude: destLat,
        longitude: destLng,
        address: buyerLocation['address'],
      );

      // Calculate distance and duration
      final distance = originPoint.distanceTo(destPoint);
      final duration = _trackingService.calculateEstimatedDuration(distance);

      // Create delivery tracking
      final tracking = DeliveryTracking(
        id: '', // Firestore will generate
        orderId: orderId,
        deliveryType: deliveryType,
        deliveryPersonId: order.farmerId ?? order.sellerId,
        deliveryPersonName: sellerName,
        deliveryPersonPhone: sellerPhone,
        recipientId: order.buyerId,
        recipientName: buyerName,
        recipientPhone: buyerPhone,
        originLocation: originPoint,
        destinationLocation: destPoint,
        status: DeliveryStatus.pending,
        estimatedDistance: distance,
        estimatedDuration: duration,
        notes: order.deliveryNotes,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      final trackingId = await _trackingService.createDeliveryTracking(
        tracking,
      );

      if (kDebugMode) {
        debugPrint(
          '✅ Delivery tracking created: $trackingId for order $orderId',
        );
        debugPrint(
          '   Distance: ${distance.toStringAsFixed(1)} km, ETA: $duration min',
        );
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Error creating delivery tracking: $e');
      }
      rethrow;
    }
  }

  /// Synchronize delivery status to order status
  Future<void> syncDeliveryStatusToOrder(
    String orderId,
    DeliveryStatus deliveryStatus,
  ) async {
    try {
      String orderStatus;

      switch (deliveryStatus) {
        case DeliveryStatus.pending:
          orderStatus = 'confirmed';
          break;
        case DeliveryStatus.confirmed:
          orderStatus = 'confirmed';
          break;
        case DeliveryStatus.inProgress:
          orderStatus = 'shipped';
          break;
        case DeliveryStatus.completed:
          orderStatus = 'delivered';
          break;
        case DeliveryStatus.cancelled:
          orderStatus = 'cancelled';
          break;
        case DeliveryStatus.failed:
          orderStatus = 'cancelled';
          break;
      }

      await _firestore.collection('orders').doc(orderId).update({
        'status': orderStatus,
        'updated_at': FieldValue.serverTimestamp(),
      });

      if (kDebugMode) {
        debugPrint('✅ Order $orderId status synced to $orderStatus');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Error syncing delivery status to order: $e');
      }
      rethrow;
    }
  }

  /// Get delivery tracking for order
  Future<DeliveryTracking?> getOrderDeliveryTracking(String orderId) async {
    try {
      return await _trackingService.getDeliveryTrackingByOrderId(orderId);
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Error getting order delivery tracking: $e');
      }
      return null;
    }
  }

  /// Stream delivery tracking for order
  Stream<DeliveryTracking?> streamOrderDeliveryTracking(String orderId) {
    try {
      return _firestore
          .collection('delivery_tracking')
          .where('order_id', isEqualTo: orderId)
          .limit(1)
          .snapshots()
          .map((snapshot) {
            if (snapshot.docs.isEmpty) return null;
            final doc = snapshot.docs.first;
            return DeliveryTracking.fromFirestore(doc.data(), doc.id);
          });
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Error streaming order delivery tracking: $e');
      }
      return Stream.value(null);
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
  Future<void> updateOrderStatus(
    String orderId,
    app_order.OrderStatus newStatus,
  ) async {
    try {
      // Get order details first for notification
      final orderDoc = await _firestore.collection('orders').doc(orderId).get();
      if (!orderDoc.exists) {
        throw Exception('Order not found');
      }
      final orderData = orderDoc.data()!;

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
        debugPrint(
          '✅ app_order.Order $orderId status updated to ${newStatus.displayName}',
        );
      }

      // Send notification to buyer about status update
      try {
        await _notificationService.sendOrderStatusNotification(
          buyerId: orderData['buyer_id'] ?? '',
          orderId: orderId,
          status: newStatus.toString().split('.').last,
          sellerName: orderData['farmer_name'] ?? 'Seller',
        );
      } catch (e) {
        if (kDebugMode) {
          debugPrint('⚠️ Failed to send order status notification: $e');
        }
        // Don't fail the status update if notification fails
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
  Future<Map<app_order.OrderStatus, int>> getFarmerOrderStats(
    String farmerId,
  ) async {
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

      return completedOrders.fold<double>(
        0.0,
        (acc, order) => acc + order.totalAmount,
      );
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Error calculating farmer revenue: $e');
      }
      return 0;
    }
  }

  /// Get farmer's today earnings (last 24 hours)
  Future<double> getFarmerTodayEarnings(String farmerId) async {
    try {
      final orders = await getFarmerOrders(farmerId);
      final now = DateTime.now();
      final last24Hours = now.subtract(const Duration(hours: 24));

      final recentOrders = orders.where((order) {
        final orderDate = order.createdAt;
        return orderDate.isAfter(last24Hours) &&
            (order.status == app_order.OrderStatus.completed ||
                order.status == app_order.OrderStatus.delivered);
      });

      return recentOrders.fold<double>(
        0.0,
        (acc, order) => acc + order.totalAmount,
      );
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Error calculating farmer today earnings: $e');
      }
      return 0;
    }
  }

  /// Get farmer's weekly earnings (last 7 days)
  Future<double> getFarmerWeeklyEarnings(String farmerId) async {
    try {
      final orders = await getFarmerOrders(farmerId);
      final now = DateTime.now();
      final lastWeek = now.subtract(const Duration(days: 7));

      final weeklyOrders = orders.where((order) {
        final orderDate = order.createdAt;
        return orderDate.isAfter(lastWeek) &&
            (order.status == app_order.OrderStatus.completed ||
                order.status == app_order.OrderStatus.delivered);
      });

      return weeklyOrders.fold<double>(
        0.0,
        (acc, order) => acc + order.totalAmount,
      );
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Error calculating farmer weekly earnings: $e');
      }
      return 0;
    }
  }

  /// Get farmer's active orders count
  Future<int> getFarmerActiveOrdersCount(String farmerId) async {
    try {
      final stats = await getFarmerOrderStats(farmerId);
      int activeCount = 0;

      // Active orders include: confirmed, preparing, ready, in_transit
      activeCount += stats[app_order.OrderStatus.confirmed] ?? 0;
      activeCount += stats[app_order.OrderStatus.preparing] ?? 0;
      activeCount += stats[app_order.OrderStatus.ready] ?? 0;
      activeCount += stats[app_order.OrderStatus.inTransit] ?? 0;

      return activeCount;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Error getting farmer active orders count: $e');
      }
      return 0;
    }
  }

  /// Get farmer's pending orders count
  Future<int> getFarmerPendingOrdersCount(String farmerId) async {
    try {
      final stats = await getFarmerOrderStats(farmerId);
      return stats[app_order.OrderStatus.pending] ?? 0;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Error getting farmer pending orders count: $e');
      }
      return 0;
    }
  }

  /// Get farmer's recent orders (last 24 hours)
  Future<List<app_order.Order>> getFarmerRecentOrders(String farmerId) async {
    try {
      final orders = await getFarmerOrders(farmerId);
      final now = DateTime.now();
      final last24Hours = now.subtract(const Duration(hours: 24));

      final recentOrders = orders.where((order) {
        return order.createdAt.isAfter(last24Hours);
      }).toList();

      // Sort by created date (most recent first)
      recentOrders.sort((a, b) => b.createdAt.compareTo(a.createdAt));

      return recentOrders;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Error getting farmer recent orders: $e');
      }
      return [];
    }
  }

  // ============================================================================
  // DELIVERY CONFIRMATION (Buyer)
  // ============================================================================

  /// Buyer confirms receipt of order
  /// This marks the order as truly completed and triggers stock reduction
  /// Also generates a receipt for the transaction
  Future<void> confirmReceipt(
    String orderId, {
    String? notes,
    String? deliveryPhoto,
    int? rating,
    String? feedback,
  }) async {
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
          final productDoc = await _firestore
              .collection('products')
              .doc(item.productId)
              .get();

          if (productDoc.exists) {
            final currentStock = productDoc.data()?['stock_quantity'] ?? 0;
            final newStock = (currentStock - item.quantity)
                .clamp(0, double.infinity)
                .toInt();

            await _firestore.collection('products').doc(item.productId).update({
              'stock_quantity': newStock,
              'is_available': newStock > 0,
              'updated_at': FieldValue.serverTimestamp(),
            });

            if (kDebugMode) {
              debugPrint(
                '📉 Stock reduced for ${item.productName}: $currentStock → $newStock',
              );
            }
          }
        } catch (e) {
          if (kDebugMode) {
            debugPrint(
              '⚠️ Error reducing stock for product ${item.productId}: $e',
            );
          }
          // Continue with other products even if one fails
        }
      }

      // 🧾 Generate receipt for this confirmed delivery
      try {
        final receipt = await _receiptService.generateReceipt(
          order: order,
          notes: notes,
          deliveryPhoto: deliveryPhoto,
          rating: rating,
          feedback: feedback,
        );

        if (kDebugMode) {
          debugPrint('🧾 Receipt generated: ${receipt.id}');
        }
      } catch (e) {
        if (kDebugMode) {
          debugPrint('⚠️ Error generating receipt: $e');
        }
        // Don't fail the confirmation if receipt generation fails
      }

      // ⭐ Update seller's system rating after order completion
      if (order.farmerId != null) {
        try {
          await _ratingService.calculateAndUpdateUserRating(order.farmerId!);
          if (kDebugMode) {
            debugPrint('⭐ Seller rating updated for ${order.farmerId}');
          }
        } catch (e) {
          if (kDebugMode) {
            debugPrint('⚠️ Error updating seller rating: $e');
          }
          // Don't fail the confirmation if rating update fails
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
                (order.isReceivedByBuyer ?? false));
      });

      return monthlyOrders.fold<double>(
        0.0,
        (acc, order) => acc + order.totalAmount,
      );
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
      // Only count orders that are BOTH delivered AND received by buyer
      return orders
          .where(
            (order) =>
                order.status == app_order.OrderStatus.delivered &&
                (order.isReceivedByBuyer ?? false),
          )
          .length;
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
      // Only count truly active orders - not delivered, completed, cancelled, or rejected
      return orders
          .where(
            (order) =>
                order.status == app_order.OrderStatus.pending ||
                order.status == app_order.OrderStatus.confirmed ||
                order.status == app_order.OrderStatus.preparing ||
                order.status == app_order.OrderStatus.ready ||
                order.status == app_order.OrderStatus.inTransit,
          )
          .length;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Error getting active orders count: $e');
      }
      return 0;
    }
  }

  /// Get recent orders (created within 24 hours)
  Future<List<app_order.Order>> getBuyerRecentOrders(String buyerId) async {
    try {
      final orders = await getBuyerOrders(buyerId);
      final yesterday = DateTime.now().subtract(const Duration(hours: 24));

      // Show all orders created in last 24 hours, regardless of status
      return orders
          .where((order) => order.createdAt.isAfter(yesterday))
          .toList();
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Error getting recent orders: $e');
      }
      return [];
    }
  }

  // ============================================================================
  // ORDER REVIEW & RATING
  // ============================================================================

  /// Submit order review and rating from buyer
  Future<void> submitOrderReview({
    required String orderId,
    required int rating,
    required String review,
    String? reviewPhotoPath,
    bool isFavoriteSeller = false,
  }) async {
    try {
      if (kDebugMode) {
        debugPrint(
          '📝 Submitting review for order: $orderId (Rating: $rating stars)',
        );
      }

      // Validate rating
      if (rating < 1 || rating > 5) {
        throw Exception('Rating must be between 1 and 5');
      }

      final now = DateTime.now();

      // TODO: Upload review photo to Firebase Storage if provided
      String? reviewPhotoUrl;
      if (reviewPhotoPath != null) {
        // reviewPhotoUrl = await _uploadReviewPhoto(reviewPhotoPath);
        reviewPhotoUrl =
            reviewPhotoPath; // Placeholder until storage is implemented
      }

      // Update order with review
      await _firestore.collection('orders').doc(orderId).update({
        'rating': rating,
        'review': review,
        'review_photo': reviewPhotoUrl,
        'reviewed_at': now.toIso8601String(),
        'is_favorite_seller': isFavoriteSeller,
        'updated_at': now.toIso8601String(),
      });

      // Get order to update farmer ratings
      final orderDoc = await _firestore.collection('orders').doc(orderId).get();
      if (orderDoc.exists) {
        final orderData = orderDoc.data()!;
        final farmerId = orderData['farmer_id'];
        final farmerName = orderData['farmer_name'];

        // Update farmer's rating statistics
        await _updateFarmerRating(farmerId, farmerName, rating);

        // ⭐ Update seller's system rating after review submission
        try {
          await _ratingService.calculateAndUpdateUserRating(farmerId);
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

  /// Get farmer's rating information
  Future<Map<String, dynamic>?> getFarmerRating(String farmerId) async {
    try {
      final ratingDoc = await _firestore
          .collection('farmer_ratings')
          .doc(farmerId)
          .get();
      if (ratingDoc.exists) {
        return ratingDoc.data();
      }
      return null;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Error getting farmer rating: $e');
      }
      return null;
    }
  }
}
